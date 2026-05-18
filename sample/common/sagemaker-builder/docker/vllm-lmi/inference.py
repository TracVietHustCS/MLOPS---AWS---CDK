"""
Inference module for vLLM SageMaker container.
This file is kept for compatibility but the actual inference is handled
by vLLM's native OpenAI-compatible API server (started via serve.py).

The vLLM server provides:
- /v1/chat/completions - Chat completions (streaming & non-streaming)
- /v1/completions - Text completions (streaming & non-streaming)
- /v1/models - List available models
- /health - Health check endpoint
- /metrics - Prometheus metrics

Streaming is supported natively by adding "stream": true to the request.
"""

import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

logger.info("=" * 80)
logger.info("vLLM Inference Module")
logger.info("=" * 80)
logger.info("Using vLLM's native OpenAI-compatible API server")
logger.info("Streaming support: Native (stream=true in request)")
logger.info("API Endpoints:")
logger.info("  - POST /v1/chat/completions")
logger.info("  - POST /v1/completions")
logger.info("  - GET /v1/models")
logger.info("  - GET /health")
logger.info("  - GET /metrics")
logger.info("=" * 80)
