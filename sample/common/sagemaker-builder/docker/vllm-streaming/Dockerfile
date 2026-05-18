FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    git \
    wget \
    curl \
    vim \
    build-essential \
    ninja-build \
    cmake \
    ccache \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12

RUN python3 -m pip install --upgrade pip setuptools wheel

# Install PyTorch with CUDA 12.1 support
RUN pip3 install --no-cache-dir \
    torch==2.5.1 \
    torchvision==0.20.1 \
    torchaudio==2.5.1 \
    --index-url https://download.pytorch.org/whl/cu121

# Install vLLM
RUN pip3 install --no-cache-dir vllm==0.10.2

# Install ML dependencies
RUN pip3 install --no-cache-dir \
    transformers==4.56.2 \
    accelerate==1.2.1 \
    sentencepiece==0.2.0 \
    protobuf==5.29.2 \
    tiktoken==0.8.0 \
    pillow==11.0.0 \
    numpy==1.26.4 \
    fastapi==0.115.6 \
    uvicorn[standard]==0.34.0 \
    pydantic==2.11.9 \
    httpx==0.28.1 \
    bitsandbytes>=0.46.1 \
    scipy==1.14.1 \
    prometheus-client==0.23.1

# Install AWS dependencies
RUN pip3 install --no-cache-dir \
    boto3>=1.35.0 \
    sagemaker>=2.232.0

# Install monitoring tools
RUN pip3 install --no-cache-dir \
    psutil>=6.1.0 \
    nvidia-ml-py>=12.560.30

# Install OpenAI and settings
RUN pip3 install --no-cache-dir \
    openai>=1.54.0 \
    pydantic-settings>=2.6.0

# Vulnerability fixes
RUN pip3 install --no-cache-dir \
    starlette==0.47.2 \
    xgrammar==0.1.24 \
    protobuf==5.29.5

WORKDIR /opt/ml/model

# Create SageMaker directories with proper permissions for metrics
RUN mkdir -p \
    /opt/ml/code \
    /opt/ml/input \
    /opt/ml/output \
    /opt/ml/output/metrics \
    /opt/ml/output/metrics/cloudwatch \
    /opt/ml/processing \
    && chmod -R 777 /opt/ml/output \
    && chmod -R 777 /opt/ml/processing

COPY serve.py /opt/ml/code/serve.py
COPY invocations_wrapper.py /opt/ml/code/invocations_wrapper.py
COPY metrics_publisher.py /opt/ml/code/metrics_publisher.py

RUN chmod +x /opt/ml/code/serve.py && \
    chmod +x /opt/ml/code/invocations_wrapper.py

EXPOSE 8080

ENV SAGEMAKER_PROGRAM=serve \
    SAGEMAKER_SUBMIT_DIRECTORY=/opt/ml/code \
    SAGEMAKER_MODEL_DIR=/opt/ml/model \
    publish_cloudwatch_metrics=Enabled \
    METRICS_PUBLISH_INTERVAL=60

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD curl -f http://localhost:8080/ping || exit 1

ENTRYPOINT ["python3", "/opt/ml/code/serve.py"]
