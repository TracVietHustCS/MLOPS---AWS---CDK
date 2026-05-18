"""
SageMaker serving script for vLLM with streaming support.
Runs vLLM's OpenAI-compatible API server.
"""

import os
import sys
import json
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
    """Build vLLM server command from environment variables."""
    model_id = get_env('OPTION_MODEL_ID', required=True)
    model_dir = Path(get_env('SAGEMAKER_MODEL_DIR', '/opt/ml/model'))

    if model_dir.exists() and any(model_dir.glob('*.safetensors')):
        model_path = str(model_dir)
    else:
        model_path = model_id

    cmd = [
        'python3', '-m', 'vllm.entrypoints.openai.api_server',
        '--model', model_path,
        '--host', '127.0.0.1',
        '--port', '8001',
    ]

    tensor_parallel_size = get_env('OPTION_TENSOR_PARALLEL_DEGREE', '1')
    cmd.extend(['--tensor-parallel-size', tensor_parallel_size])

    if int(get_env('OPTION_TENSOR_PARALLEL_DEGREE', '1')) > 1:
        cmd.append('--enable-expert-parallel')

    gpu_memory_utilization = get_env('OPTION_GPU_MEMORY_UTILIZATION', '0.85')
    cmd.extend(['--gpu-memory-utilization', gpu_memory_utilization])

    max_model_len = get_env('OPTION_MAX_MODEL_LEN')
    if max_model_len:
        cmd.extend(['--max-model-len', max_model_len])

    max_batched_len = get_env('OPTION_MAX_BATCHED_LEN')
    if max_batched_len:
        cmd.extend(['--max-num-batched-tokens', max_batched_len])

    trust_remote_code = get_env('OPTION_TRUST_REMOTE_CODE', 'true')
    if trust_remote_code.lower() == 'true':
        cmd.append('--trust-remote-code')

    dtype = get_env('OPTION_DTYPE', 'auto')
    cmd.extend(['--dtype', dtype])

    max_num_seqs = get_env('OPTION_MAX_NUM_SEQS', '64')
    cmd.extend(['--max-num-seqs', max_num_seqs])

    if get_env('OPTION_ENABLE_PREFIX_CACHING', 'true').lower() == 'true':
        cmd.append('--enable-prefix-caching')

    cmd.append('--enable-log-requests')

    swap_space = get_env('OPTION_SWAP_SPACE', '4')
    cmd.extend(['--swap-space', swap_space])

    cmd.extend(['--served-model-name', model_id.split('/')[-1]])

    logger.info("vLLM command configuration:")
    logger.info(f"Command: {' '.join(cmd)}")
    return cmd

def wait_for_vllm():
    """Wait for vLLM server to be ready."""
    import requests
    import time
    logger.info("Waiting for vLLM to be ready...")
    for i in range(120):
        try:
            resp = requests.get("http://127.0.0.1:8001/health", timeout=5)
            if resp.status_code == 200:
                logger.info("✓ vLLM is ready!")
                return True
        except:
            pass
        time.sleep(5)
    logger.error("vLLM failed to start within timeout")
    return False

def start_metrics_publisher():
    """Start the CloudWatch metrics publisher as a background process."""
    try:
        logger.info("Starting CloudWatch metrics publisher...")

        if get_env('publish_cloudwatch_metrics', 'Enabled').lower() != 'enabled':
            logger.info("CloudWatch metrics publishing is disabled")
            return None

        def run_metrics_publisher():
            metrics_cmd = ['python3', '/opt/ml/code/metrics_publisher.py']
            try:
                subprocess.run(
                    metrics_cmd,
                    check=True,
                    env=os.environ.copy()
                )
            except subprocess.CalledProcessError as e:
                logger.error(f"Metrics publisher failed with exit code {e.returncode}")
            except Exception as e:
                logger.error(f"Metrics publisher failed: {e}")

        metrics_thread = Thread(target=run_metrics_publisher, daemon=True)
        metrics_thread.start()
        logger.info("Metrics publisher thread started")
        return metrics_thread

    except Exception as e:
        logger.warning(f"Failed to start metrics publisher: {e}")
        return None

def main():
    """Main entry point for SageMaker serving."""
    metrics_process = None
    vllm_process = None
    wrapper_process = None

    try:
        logger.info("=" * 80)
        logger.info("Starting vLLM SageMaker Container with Streaming Support")
        logger.info("=" * 80)

        logger.info("Environment variables:")
        for key in sorted(os.environ.keys()):
            if key.startswith('OPTION_') or key.startswith('SAGEMAKER_') or key.startswith('publish_'):
                logger.info(f"  {key}={os.environ[key]}")

        model_dir = Path(get_env('SAGEMAKER_MODEL_DIR', '/opt/ml/model'))
        logger.info(f"Model directory: {model_dir}")

        if model_dir.exists():
            logger.info(f"Model directory contents: {list(model_dir.iterdir())[:5]}")
        else:
            logger.warning(f"Model directory does not exist, will download from HuggingFace")

        metrics_process = start_metrics_publisher()

        cmd = build_vllm_command()
        logger.info("Starting vLLM on port 8001...")

        env = os.environ.copy()
        env['CUDA_LAUNCH_BLOCKING'] = get_env('CUDA_LAUNCH_BLOCKING', '1')
        env['VLLM_USE_CUDA_GRAPH'] = get_env('VLLM_USE_CUDA_GRAPH', '0')
        env['VLLM_DISABLE_CUSTOM_ALL_REDUCE'] = get_env('VLLM_DISABLE_CUSTOM_ALL_REDUCE', '1')

        logger.info("Stability settings:")
        logger.info(f"  CUDA_LAUNCH_BLOCKING={env['CUDA_LAUNCH_BLOCKING']}")
        logger.info(f"  VLLM_USE_CUDA_GRAPH={env['VLLM_USE_CUDA_GRAPH']}")
        logger.info(f"  VLLM_DISABLE_CUSTOM_ALL_REDUCE={env['VLLM_DISABLE_CUSTOM_ALL_REDUCE']}")

        vllm_process = subprocess.Popen(
            cmd,
            stdout=sys.stdout,
            stderr=sys.stderr,
            env=env
        )

        if not wait_for_vllm():
            logger.error("vLLM failed to start, shutting down...")
            if vllm_process:
                vllm_process.kill()
            sys.exit(1)

        logger.info("Starting SageMaker wrapper on port 8080...")
        wrapper_process = subprocess.Popen(
            ['python3', '/opt/ml/code/invocations_wrapper.py'],
            stdout=sys.stdout,
            stderr=sys.stderr
        )

        logger.info("=" * 80)
        logger.info("All services started successfully!")
        logger.info("  Metrics Publisher: Running in background")
        logger.info("  vLLM Server: http://127.0.0.1:8001")
        logger.info("  SageMaker Endpoint: http://0.0.0.0:8080")
        logger.info("=" * 80)

        try:
            wrapper_process.wait()
        finally:
            logger.info("Shutting down services...")
            if vllm_process:
                vllm_process.terminate()
            if wrapper_process:
                wrapper_process.terminate()
            if metrics_process:
                metrics_process.terminate()

    except Exception as e:
        logger.exception(f"Failed to start vLLM server: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
