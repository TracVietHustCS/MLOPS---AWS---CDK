set -e

echo "=" echo "================================================================================================"
echo "SageMaker vLLM Streaming Deployment"
echo "================================================================================================"
echo ""

cd "$(dirname "$0")"

echo "Step 1: Building vLLM Docker image with streaming support..."
echo "----------------------------------------------------------------------------"
./build_and_push_vllm.sh

echo ""
echo "Step 2: Image built successfully!"
echo ""
echo "Next steps:"
echo "  1. Go to your region directory:"
echo "     cd ../../environments/ap-southeast-1"
echo ""
echo "  2. Deploy with Terraform:"
echo "     terraform apply"
echo ""
echo "  3. Wait for endpoint to update (~10-15 minutes)"
echo ""
echo "  4. Test streaming:"
echo "     curl -N http://your-alb-url/invoke/text \\"
echo "       -H 'X-API-Key: your-key' \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"messages\": [{\"role\": \"user\", \"content\": \"Count to 10\"}], \"stream\": true}'"
echo ""
echo "================================================================================================"
