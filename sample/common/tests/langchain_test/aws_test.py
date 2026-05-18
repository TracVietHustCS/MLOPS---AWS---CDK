import json
from typing import Dict

from langchain_aws.llms import SagemakerEndpoint
from langchain_aws.llms.sagemaker_endpoint import LLMContentHandler

class VisionContentHandler(LLMContentHandler):
        content_type = "application/json"
        accepts = "application/json"

        def transform_input(self, prompt: str, model_kwargs: Dict) -> bytes:
            """
            Send vision content with image.
            Pass image_url in model_kwargs: llm.invoke(prompt, image_url="https://...")
            """
            image_url = model_kwargs.pop('image_url', None)

            content = [{"type": "text", "text": prompt}]

            if image_url:
                content.append({
                    "type": "image_url",
                    "image_url": {"url": image_url}
                })

            payload = {
                "messages": [
                    {
                        "role": "user",
                        "content": content
                    }
                ],
                "stream": True,
                "stream_options": {"include_usage": True},  # Request usage info
                **model_kwargs
            }
            return json.dumps(payload).encode('utf-8')

        def transform_output(self, output) -> str:
            """Extract text from response"""
            if hasattr(output, 'read'):
                content = output.read()
                if isinstance(content, bytes):
                    content = content.decode("utf-8")
            elif isinstance(output, bytes):
                content = output
            else:
                content = str(output)


            return content

def test_basic_completion():
    """Test sending an image to SagemakerEndpoint."""
    print("=" * 80)
    print("Test 1: Vision - Send Image to Endpoint")
    print("=" * 80)

    IMAGE_URL = "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen-VL/assets/demo.jpeg"

    content_handler = VisionContentHandler()

    llm = SagemakerEndpoint(
        endpoint_name="acb-dev-qwen2-5-vl-7b",
        region_name="ap-southeast-1",
        model_kwargs={
            "temperature": 0.2,
            "max_tokens": 500,
            "image_url": IMAGE_URL
        },
        content_handler=content_handler
    )

    prompt = "mô tả hình ảnh sau"
    response = llm.stream(prompt)

    for out in response:
        content = json.loads(out)

        try:
            text = content["choices"][0]["delta"].get("content", "")
            print(text)
        except:
            print(content['usage'])

    print(f"Image URL: {IMAGE_URL}")
    print(f"Prompt: {prompt}\n")

if __name__ == "__main__":
    try:
        test_basic_completion()

    except Exception as e:
        print(f"\nL Test failed with error: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
