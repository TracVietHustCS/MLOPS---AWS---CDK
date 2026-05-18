
set -e

IMAGE="${1:-vllm-sagemaker:latest}"

echo "========================================"
echo "Scanning Docker Image for Vulnerabilities"
echo "Image: $IMAGE"
echo "========================================"
echo ""

if ! docker image inspect "$IMAGE" &> /dev/null; then
    echo "Error: Image '$IMAGE' not found locally"
    echo "Please build or pull the image first"
    exit 1
fi

echo "Running Trivy security scan..."
echo ""

trivy image \
    --severity CRITICAL,HIGH \
    --exit-code 0 \
    --no-progress \
    --scanners vuln \
    --timeout 30m \
    --format table \
    "$IMAGE"

echo ""
echo "========================================"
echo "Scan Complete!"
echo "========================================"
echo ""
echo "To see all severities (including MEDIUM, LOW):"
echo "  trivy image --severity CRITICAL,HIGH,MEDIUM,LOW $IMAGE"
echo ""
echo "To generate JSON report:"
echo "  trivy image --format json --output scan-results.json $IMAGE"
echo ""
echo "To fail on CRITICAL/HIGH vulnerabilities:"
echo "  trivy image --severity CRITICAL,HIGH --exit-code 1 $IMAGE"
