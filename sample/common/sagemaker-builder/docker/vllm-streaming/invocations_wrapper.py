
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
    try:
        body = await request.json()

        if "messages" not in body:
            inputs = body.get("inputs") or body.get("prompt", "")
            parameters = body.get("parameters", {})
            payload = {
                "messages": [{"role": "user", "content": inputs}],
                **parameters
            }
        else:
            payload = body

        stream = payload.pop("stream", False)

        if stream:
            payload["stream"] = True

            async def stream_generator():
                async with httpx.AsyncClient(timeout=600.0) as client:
                    async with client.stream(
                        "POST",
                        f"http://127.0.0.1:{VLLM_PORT}/v1/chat/completions",
                        json=payload
                    ) as response:
                        async for line in response.aiter_lines():
                            if line.startswith("data: "):
                                data_str = line[6:]
                                if data_str != "[DONE]":
                                    try:
                                        data = json.loads(data_str)
                                        yield (json.dumps(data) + "\n").encode()
                                    except:
                                        pass

            return StreamingResponse(
                stream_generator(),
                media_type="application/jsonlines"
            )
        else:
            payload["stream"] = False
            async with httpx.AsyncClient(timeout=600.0) as client:
                response = await client.post(
                    f"http://127.0.0.1:{VLLM_PORT}/v1/chat/completions",
                    json=payload
                )
                return JSONResponse(content=response.json())

    except Exception as e:
        logger.error(f"Error: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})

@app.get("/ping")
async def ping():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080, log_level="info")
