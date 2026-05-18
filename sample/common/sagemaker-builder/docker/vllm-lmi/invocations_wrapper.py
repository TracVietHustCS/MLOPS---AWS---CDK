"""
SageMaker /invocations endpoint wrapper for vLLM OpenAI API.
Translates SageMaker format to OpenAI format and handles streaming.
"""

import json
import httpx
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse, JSONResponse
import uvicorn
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

VLLM_PORT = 8001

@app.post("/invocations")
async def invocations(request: Request):
    """
    SageMaker invocations endpoint.
    Accepts both SageMaker format and OpenAI format.
    """
    try:
        body = await request.json()
        logger.info(f"Received request: {json.dumps(body, indent=2)[:500]}")

        if "messages" not in body:
            inputs = body.get("inputs") or body.get("prompt", "")
            parameters = body.get("parameters", {})

            if "max_new_tokens" in parameters:
                parameters["max_tokens"] = parameters.pop("max_new_tokens")
                logger.info(f"Converted max_new_tokens → max_tokens: {parameters['max_tokens']}")

            payload = {
                "messages": [{"role": "user", "content": inputs}],
                **parameters
            }
            logger.info("Transformed SageMaker format to OpenAI format")
        else:
            payload = body.copy()
            logger.info("Request already in OpenAI format")

            if "max_new_tokens" in payload:
                payload["max_tokens"] = payload.pop("max_new_tokens")
                logger.info(f"Converted max_new_tokens → max_tokens: {payload['max_tokens']}")

        stream = payload.get("stream", False)

        if "model" not in payload:
            async with httpx.AsyncClient(timeout=10.0) as client:
                models_response = await client.get(f"http://127.0.0.1:{VLLM_PORT}/v1/models")
                models_data = models_response.json()
                if models_data.get("data"):
                    payload["model"] = models_data["data"][0]["id"]
                    logger.info(f"Auto-selected model: {payload['model']}")

        logger.info(f"Final payload to vLLM: {json.dumps(payload, indent=2)[:800]}")

        if stream:
            logger.info("Handling streaming request")
            payload["stream"] = True

            async def stream_generator():
                """Generator for streaming responses."""
                async with httpx.AsyncClient(timeout=600.0) as client:
                    async with client.stream(
                        "POST",
                        f"http://127.0.0.1:{VLLM_PORT}/v1/chat/completions",
                        json=payload,
                        headers={"Content-Type": "application/json"}
                    ) as response:
                        response.raise_for_status()

                        async for line in response.aiter_lines():
                            if line.startswith("data: "):
                                data_str = line[6:]  # Remove "data: " prefix

                                if data_str == "[DONE]":
                                    continue

                                try:
                                    data = json.loads(data_str)
                                    yield (json.dumps(data) + "\n").encode()
                                except json.JSONDecodeError as e:
                                    logger.warning(f"Failed to parse streaming chunk: {e}")
                                    continue

            return StreamingResponse(
                stream_generator(),
                media_type="application/jsonlines",
                headers={
                    "X-Accel-Buffering": "no",  # Disable nginx buffering
                    "Cache-Control": "no-cache",
                }
            )
        else:
            logger.info("Handling non-streaming request")
            payload["stream"] = False

            async with httpx.AsyncClient(timeout=600.0) as client:
                response = await client.post(
                    f"http://127.0.0.1:{VLLM_PORT}/v1/chat/completions",
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )
                response.raise_for_status()
                return JSONResponse(content=response.json())

    except httpx.HTTPStatusError as e:
        logger.error(f"HTTP error from vLLM: {e}")
        logger.error(f"Response body: {e.response.text}")
        return JSONResponse(
            status_code=e.response.status_code,
            content={
                "error": {
                    "message": f"vLLM error: {e.response.text}",
                    "type": "vllm_error",
                    "code": e.response.status_code
                }
            }
        )
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "error": {
                    "message": str(e),
                    "type": "internal_error",
                    "code": 500
                }
            }
        )

@app.get("/ping")
async def ping():
    """SageMaker health check endpoint."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"http://127.0.0.1:{VLLM_PORT}/health")
            if response.status_code == 200:
                return {"status": "healthy"}
            else:
                return JSONResponse(
                    status_code=503,
                    content={"status": "unhealthy", "reason": "vLLM not ready"}
                )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return JSONResponse(
            status_code=503,
            content={"status": "unhealthy", "reason": str(e)}
        )

@app.get("/health")
async def health():
    """Alternative health check endpoint."""
    return await ping()

@app.get("/v1/models")
async def get_models():
    """Proxy to vLLM's /v1/models endpoint."""
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(f"http://127.0.0.1:{VLLM_PORT}/v1/models")
        return JSONResponse(content=response.json())

@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    """Proxy direct OpenAI API calls to vLLM."""
    body = await request.json()

    if body.get("stream", False):
        async def stream_proxy():
            async with httpx.AsyncClient(timeout=600.0) as client:
                async with client.stream(
                    "POST",
                    f"http://127.0.0.1:{VLLM_PORT}/v1/chat/completions",
                    json=body
                ) as response:
                    async for chunk in response.aiter_bytes():
                        yield chunk

        return StreamingResponse(
            stream_proxy(),
            media_type="text/event-stream"
        )
    else:
        async with httpx.AsyncClient(timeout=600.0) as client:
            response = await client.post(
                f"http://127.0.0.1:{VLLM_PORT}/v1/chat/completions",
                json=body
            )
            return JSONResponse(content=response.json())

if __name__ == "__main__":
    logger.info("=" * 80)
    logger.info("Starting SageMaker Invocations Wrapper")
    logger.info(f"Listening on: http://0.0.0.0:8080")
    logger.info(f"Forwarding to vLLM: http://127.0.0.1:{VLLM_PORT}")
    logger.info("Endpoints:")
    logger.info("  - POST /invocations (SageMaker format)")
    logger.info("  - POST /v1/chat/completions (OpenAI format)")
    logger.info("  - GET /v1/models")
    logger.info("  - GET /ping")
    logger.info("  - GET /health")
    logger.info("=" * 80)

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080,
        log_level="info",
        access_log=True
    )
