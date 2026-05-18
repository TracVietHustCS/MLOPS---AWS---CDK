# Use official vLLM OpenAI image as base (AWS DLC pattern)
FROM docker.io/vllm/vllm-openai:v0.11.0

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install additional AWS and monitoring dependencies
RUN pip3 install --no-cache-dir \
    boto3>=1.40.51 \
    sagemaker>=2.252.0 \
    psutil>=6.1.0 \
    nvidia-ml-py>=12.560.30 \
    prometheus-client==0.23.1

# Security updates for any vulnerabilities
RUN pip3 install --no-cache-dir --upgrade \
    starlette \
    protobuf

# Set working directory
WORKDIR /opt/ml/model

# Create SageMaker directories
RUN mkdir -p \
    /opt/ml/code \
    /opt/ml/input \
    /opt/ml/output \
    /opt/ml/output/metrics \
    /opt/ml/output/metrics/cloudwatch \
    && chmod -R 777 /opt/ml/output

# Copy application files
COPY serve.py /opt/ml/code/serve.py
COPY inference.py /opt/ml/code/inference.py
COPY metrics_publisher.py /opt/ml/code/metrics_publisher.py
COPY invocations_wrapper.py /opt/ml/code/invocations_wrapper.py

# Make scripts executable
RUN chmod +x /opt/ml/code/serve.py /opt/ml/code/invocations_wrapper.py

# Expose port 8080 (SageMaker requirement)
EXPOSE 8080

# Set SageMaker environment variables
ENV SAGEMAKER_PROGRAM=serve \
    SAGEMAKER_SUBMIT_DIRECTORY=/opt/ml/code \
    SAGEMAKER_MODEL_DIR=/opt/ml/model \
    publish_cloudwatch_metrics=Enabled \
    METRICS_PUBLISH_INTERVAL=60

# Health check using vLLM's native health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start the server
ENTRYPOINT ["python3", "/opt/ml/code/serve.py"]
