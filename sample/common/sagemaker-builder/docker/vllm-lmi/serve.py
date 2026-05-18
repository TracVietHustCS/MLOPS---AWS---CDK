"""
SageMaker serving script for vLLM - AWS LMI aligned approach.
Uses 'vllm serve' command with native streaming support.
"""

import os
import sys
import logging
import subprocess
from pathlib import Path
from threading import Thread

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def get_env(key, default=None, required=False):
    """Get environment variable with validation."""
    value = os.environ.get(key, default)
    if required and not value:
        raise ValueError(f"Required environment variable {key} is not set")
    return value

def build_vllm_command():
    """
    Build vLLM serve command from environment variables.
    Supports both AWS LMI format and native vLLM format.

    AWS LMI Format:
      - HF_MODEL_ID (model path)
      - TENSOR_PARALLEL_DEGREE
      - OPTION_ENGINE=Python
      - OPTION_ROLLING_BATCH=vllm

    Native vLLM Format:
      - OPTION_MODEL_ID
      - OPTION_TENSOR_PARALLEL_DEGREE
    """
    model_dir = Path(get_env('SAGEMAKER_MODEL_DIR', '/opt/ml/model'))

    model_id = get_env('HF_MODEL_ID') or get_env('OPTION_MODEL_ID')

    if not model_id:
        raise ValueError("Either HF_MODEL_ID or OPTION_MODEL_ID must be set")

    if model_id == '/opt/ml/model' or model_id == str(model_dir):
        model_path = str(model_dir)
        logger.info(f"Using local model from: {model_path}")
    elif model_dir.exists() and any(model_dir.glob('*.safetensors')):
        model_path = str(model_dir)
        logger.info(f"Using local model from: {model_path}")
    else:
        model_path = model_id
        logger.info(f"Will download model from HuggingFace: {model_path}")

    cmd = [
        'vllm', 'serve', model_path,
        '--host', '127.0.0.1',  # Only accessible locally
        '--port', '8001',  # Internal port
    ]

    tensor_parallel_size = get_env('TENSOR_PARALLEL_DEGREE') or get_env('OPTION_TENSOR_PARALLEL_DEGREE', '1')
    cmd.extend(['--tensor-parallel-size', tensor_parallel_size])

    if int(tensor_parallel_size) > 1:
        if get_env('OPTION_ENABLE_EXPERT_PARALLEL', 'false').lower() == 'true':
            cmd.append('--enable-expert-parallel')

    gpu_memory_utilization = get_env('OPTION_GPU_MEMORY_UTILIZATION', '0.85')
    cmd.extend(['--gpu-memory-utilization', gpu_memory_utilization])

    max_model_len = get_env('OPTION_MAX_MODEL_LEN')
    if max_model_len:
        cmd.extend(['--max-model-len', max_model_len])

    max_batched_len = get_env('OPTION_MAX_BATCHED_LEN')
    if max_batched_len:
        cmd.extend(['--max-num-batched-tokens', max_batched_len])

    quantization = get_env('OPTION_QUANTIZATION')
    if quantization and quantization.lower() != 'none':
        if 'fp8' not in model_id.lower():
            cmd.extend(['--quantization', quantization])
        else:
            logger.info(f"Model {model_id} is pre-quantized FP8, skipping --quantization flag")

    trust_remote_code = get_env('OPTION_TRUST_REMOTE_CODE', 'true')
    if trust_remote_code.lower() == 'true':
        cmd.append('--trust-remote-code')

    dtype = get_env('OPTION_DTYPE', 'auto')
    cmd.extend(['--dtype', dtype])

    max_num_seqs = get_env('OPTION_MAX_NUM_SEQS', '64')
    cmd.extend(['--max-num-seqs', max_num_seqs])

    enable_prefix_caching = get_env('OPTION_ENABLE_PREFIX_CACHING', 'false')
    if enable_prefix_caching.lower() == 'true':
        cmd.append('--enable-prefix-caching')

    kv_cache_memory = get_env('OPTION_KV_CACHE_MEMORY')
    if kv_cache_memory:
        cmd.extend(['--kv-cache-memory', kv_cache_memory])

    use_cuda_graph = get_env('OPTION_USE_CUDA_GRAPH', 'false')
    if use_cuda_graph.lower() == 'false':
        cmd.append('--disable-cuda-graph')

    disable_log_requests = get_env('OPTION_DISABLE_LOG_REQUESTS', 'true')
    if disable_log_requests.lower() == 'true':
        cmd.append('--disable-log-requests')

    if model_id.startswith('/'):
        served_model_name = get_env('SAGEMAKER_ENDPOINT_NAME', 'model')
    else:
        served_model_name = model_id.split('/')[-1]
    cmd.extend(['--served-model-name', served_model_name])

    enable_chunked_prefill = get_env('OPTION_ENABLE_CHUNKED_PREFILL', 'false')
    if enable_chunked_prefill.lower() == 'true':
        cmd.append('--enable-chunked-prefill')

    swap_space = get_env('OPTION_SWAP_SPACE')
    if swap_space:
        cmd.extend(['--swap-space', swap_space])

    return cmd

def start_metrics_publisher():
    """Start CloudWatch metrics publisher as a background thread."""
    try:
        logger.info("Starting CloudWatch metrics publisher...")

        if get_env('publish_cloudwatch_metrics', 'Enabled').lower() != 'enabled':
            logger.info("CloudWatch metrics publishing is disabled")
            return None

        def run_metrics_publisher():
            """Run metrics publisher in a separate thread."""
            metrics_cmd = ['python3', '/opt/ml/code/metrics_publisher.py']
            try:
                subprocess.run(
                    metrics_cmd,
                    check=True,
                    stdout=sys.stdout,
                    stderr=sys.stderr,
                    env=os.environ.copy()
                )
            except subprocess.CalledProcessError as e:
                logger.error(f"Metrics publisher failed with exit code {e.returncode}")
            except Exception as e:
                logger.error(f"Metrics publisher error: {e}")

        metrics_thread = Thread(target=run_metrics_publisher, daemon=True)
        metrics_thread.start()
        logger.info("✓ Metrics publisher thread started")
        return metrics_thread

    except Exception as e:
        logger.warning(f"Failed to start metrics publisher: {e}")
        return None

def wait_for_vllm_ready():
    """Wait for vLLM server to be ready and perform warmup."""
    import time
    import requests

    max_wait = 600  # 10 minutes
    start_time = time.time()

    logger.info("=" * 80)
    logger.info("Waiting for vLLM server to be ready...")
    logger.info("=" * 80)

    while time.time() - start_time < max_wait:
        try:
            response = requests.get("http://127.0.0.1:8001/health", timeout=5)
            if response.status_code == 200:
                logger.info("✓ vLLM server is healthy!")
                break
        except Exception:
            pass
        time.sleep(5)
    else:
        logger.error("❌ vLLM server failed to become ready within timeout")
        return False

    if get_env('OPTION_ENABLE_WARMUP', 'true').lower() == 'true':
        try:
            logger.info("Performing warmup inference...")

            model_id = get_env('HF_MODEL_ID') or get_env('OPTION_MODEL_ID', 'model')
            if model_id.startswith('/'):
                model_name = get_env('SAGEMAKER_ENDPOINT_NAME', 'model')
            else:
                model_name = model_id.split('/')[-1]

            warmup_payload = {
                "model": model_name,
                "messages": [{"role": "user", "content": "Hi"}],
                "max_tokens": 1,
                "temperature": 0.0
            }

            start = time.time()
            response = requests.post(
                "http://127.0.0.1:8001/v1/chat/completions",
                json=warmup_payload,
                timeout=300
            )
            elapsed = time.time() - start

            if response.status_code == 200:
                logger.info(f"✓ Warmup successful! Took {elapsed:.2f}s")
            else:
                logger.warning(f"⚠ Warmup request returned status {response.status_code}")

        except Exception as e:
            logger.warning(f"⚠ Warmup failed: {e}")
            logger.info("Model will warm up on first real request")

    return True

def main():
    """
    Main entry point for SageMaker serving.
    Starts vLLM with native OpenAI-compatible API including streaming support.
    """
    vllm_process = None
    metrics_thread = None

    try:
        logger.info("=" * 80)
        logger.info("🚀 Starting vLLM SageMaker Container (AWS LMI Pattern)")
        logger.info("=" * 80)

        logger.info("Configuration:")
        for key in sorted(os.environ.keys()):
            if key.startswith('OPTION_') or key.startswith('SAGEMAKER_'):
                logger.info(f"  {key}={os.environ[key]}")

        model_dir = Path(get_env('SAGEMAKER_MODEL_DIR', '/opt/ml/model'))
        logger.info(f"\nModel directory: {model_dir}")
        if model_dir.exists():
            contents = list(model_dir.iterdir())[:5]
            logger.info(f"Contents (first 5): {[p.name for p in contents]}")
        else:
            logger.warning("Model directory does not exist - will download from HuggingFace")

        metrics_thread = start_metrics_publisher()

        cmd = build_vllm_command()
        logger.info("\n" + "=" * 80)
        logger.info("vLLM Server Command:")
        logger.info(f"  {' '.join(cmd)}")
        logger.info("=" * 80)

        env = os.environ.copy()

        if 'CUDA_LAUNCH_BLOCKING' not in env:
            env['CUDA_LAUNCH_BLOCKING'] = get_env('CUDA_LAUNCH_BLOCKING', '1')

        if 'VLLM_DISABLE_CUSTOM_ALL_REDUCE' not in env:
            env['VLLM_DISABLE_CUSTOM_ALL_REDUCE'] = get_env('VLLM_DISABLE_CUSTOM_ALL_REDUCE', '1')

        if 'VLLM_USE_MODELSCOPE' not in env:
            env['VLLM_USE_MODELSCOPE'] = 'false'

        logger.info("\nStability Environment Variables:")
        logger.info(f"  CUDA_LAUNCH_BLOCKING={env.get('CUDA_LAUNCH_BLOCKING')}")
        logger.info(f"  VLLM_DISABLE_CUSTOM_ALL_REDUCE={env.get('VLLM_DISABLE_CUSTOM_ALL_REDUCE')}")
        logger.info(f"  VLLM_USE_MODELSCOPE={env.get('VLLM_USE_MODELSCOPE')}")

        logger.info("\nStarting vLLM server...")
        logger.info("  - Host: 127.0.0.1:8001 (internal)")
        logger.info("  - OpenAI API: /v1/chat/completions")
        logger.info("  - Streaming: Native support enabled")
        logger.info("  - Health: /health")
        logger.info("")

        vllm_process = subprocess.Popen(
            cmd,
            stdout=sys.stdout,
            stderr=sys.stderr,
            env=env
        )

        if not wait_for_vllm_ready():
            logger.error("Failed to start vLLM server properly")
            if vllm_process:
                vllm_process.kill()
            sys.exit(1)

        logger.info("\nStarting SageMaker invocations wrapper...")
        logger.info("  - Host: 0.0.0.0:8080 (public)")
        logger.info("  - Endpoints: /invocations, /v1/chat/completions, /ping")
        logger.info("")

        wrapper_process = subprocess.Popen(
            ['python3', '/opt/ml/code/invocations_wrapper.py'],
            stdout=sys.stdout,
            stderr=sys.stderr
        )

        logger.info("=" * 80)
        logger.info("✅ All services started successfully!")
        logger.info("=" * 80)
        logger.info("  📊 Metrics Publisher: Running in background")
        logger.info("  🤖 vLLM Server: http://127.0.0.1:8001 (internal)")
        logger.info("  🔌 SageMaker Wrapper: http://0.0.0.0:8080 (public)")
        logger.info("  🌊 Streaming: Enabled via both endpoints")
        logger.info("=" * 80)
        logger.info("\nReady to accept requests...")

        try:
            returncode = wrapper_process.wait()
        finally:
            logger.info("Shutting down services...")
            if vllm_process:
                vllm_process.terminate()
            if wrapper_process:
                wrapper_process.terminate()

        if returncode != 0:
            logger.error(f"vLLM server exited with code {returncode}")
            sys.exit(returncode)

    except KeyboardInterrupt:
        logger.info("\n⚠ Received interrupt signal, shutting down...")
    except Exception as e:
        logger.exception(f"❌ Failed to start vLLM server: {e}")
        sys.exit(1)
    finally:
        if vllm_process:
            try:
                logger.info("Terminating vLLM process...")
                vllm_process.terminate()
                vllm_process.wait(timeout=10)
            except Exception:
                logger.warning("Force killing vLLM process...")
                vllm_process.kill()

        logger.info("Shutdown complete")

if __name__ == '__main__':
    main()
