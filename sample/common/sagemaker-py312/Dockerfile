FROM python:3.12-slim

# =======================
# System dependencies
# =======================
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    libgomp1 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# =======================
# Python dependencies
# =======================
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
        fastapi \
        uvicorn \
        gunicorn \
        numpy \
        pandas \
        scikit-learn==1.7.2 \
        xgboost==2.1.4 \
        joblib==1.5.2

# =======================
# SageMaker standard paths
# =======================
RUN mkdir -p /opt/ml/code /opt/ml/models
WORKDIR /opt/ml/code

# =======================
# Copy inference code
# =======================
COPY inference.py /opt/ml/code/inference.py

# =======================
# SageMaker serve entrypoint
# =======================
RUN printf '#!/usr/bin/env bash\n\
set -e\n\
exec gunicorn inference:app \\\n\
  --workers 1 \\\n\
  --worker-class uvicorn.workers.UvicornWorker \\\n\
  --bind 0.0.0.0:8080 \\\n\
  --timeout 60 \\\n\
  --graceful-timeout 30 \\\n\
  --keep-alive 5 \\\n\
  --access-logfile - \\\n\
  --error-logfile - \\\n\
  --log-level warning\n' \
> /usr/local/bin/serve \
&& chmod +x /usr/local/bin/serve

# =======================
# SageMaker required env
# =======================
ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE
ENV SAGEMAKER_PROGRAM=inference.py

# =======================
# Enable Multi-Model Endpoint
# =======================
LABEL com.amazonaws.sagemaker.capabilities.multi-models=true

# =======================
# Expose port
# =======================
EXPOSE 8080

# =======================
# ENTRYPOINT (BẮT BUỘC)
# =======================
ENTRYPOINT ["/usr/local/bin/serve"]
