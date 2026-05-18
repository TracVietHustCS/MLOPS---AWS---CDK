import json
import sys
import requests

ENDPOINT_URL = "http://acb-dev-alb-1257863866.ap-northeast-2.elb.amazonaws.com/api/v1"
IMAGE_URL = "https://qianwen-res.oss-cn-beijing.aliyuncs.com/Qwen-VL/assets/demo.jpeg"

def test_vision_streaming(endpoint):
    payload = {
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": "Mô tả hình ảnh này?"},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": IMAGE_URL
                        }
                    }
                ]
            }
        ],
        "max_tokens": 1024,
        "stream": True
    }

    headers = {
        "X-API-Key": "sk-7ec2eb26f37f4ef13d2396875f1a8b9f",
        "Content-Type": "application/json"
    }


    print(f"URL: {endpoint}")
    print(f"Request: {json.dumps(payload, indent=2)}")
    print("\nStreaming response:")
    print("-" * 60)

    try:
        response = requests.post(
            endpoint,
            headers=headers,
            json=payload,
            timeout=300,
            stream=True,
            verify=False
        )

        if response.status_code != 200:
            print(f"Error: Status {response.status_code}")
            print(f"Response: {response.text}")
            return

        for chunk in response.iter_content(chunk_size=None, decode_unicode=True):
            if chunk:
                try:
                    data = json.loads(chunk)
                    if 'choices' in data:
                        for choice in data['choices']:
                            if 'delta' in choice and 'content' in choice['delta']:
                                content = choice['delta']['content']
                                print(content, end='', flush=True)
                            elif 'text' in choice:
                                print(choice['text'], end='', flush=True)
                    elif 'output' in data:
                        print(data['output'], end='', flush=True)
                    elif 'text' in data:
                        print(data['text'], end='', flush=True)
                except json.JSONDecodeError:
                    print(chunk, end='', flush=True)

        print("\n" + "-" * 60)
        print("Streaming complete!")

    except requests.exceptions.Timeout:
        print("Error: Request timed out")
    except Exception as e:
        print(f"Error: {str(e)}")


def test_chat_streaming(endpoint):

    payload = {
        "messages": [
            {"role": "user", "content": "Giới thiệu về dịch vụ EC2 của AWS"}
        ],
        "max_tokens": 1024,
        "temperature": 0.7,
        "stream": True
    }

    headers = {
        "X-API-Key": "sk-7ec2eb26f37f4ef13d2396875f1a8b9f",
        "Content-Type": "application/json"
    }


    print(f"URL: {endpoint}")
    print(f"Request: {json.dumps(payload, indent=2)}")
    print("\nStreaming response:")
    print("-" * 60)

    try:
        response = requests.post(
            endpoint,
            headers=headers,
            json=payload,
            timeout=300,
            stream=True,
            verify=False
        )

        if response.status_code != 200:
            print(f"Error: Status {response.status_code}")
            print(f"Response: {response.text}")
            return

        for chunk in response.iter_content(chunk_size=None, decode_unicode=True):
            if chunk:
                try:
                    data = json.loads(chunk)
                    if 'choices' in data:
                        for choice in data['choices']:
                            if 'delta' in choice and 'content' in choice['delta']:
                                content = choice['delta']['content']
                                print(content, end='', flush=True)
                            elif 'text' in choice:
                                print(choice['text'], end='', flush=True)
                    elif 'output' in data:
                        print(data['output'], end='', flush=True)
                    elif 'text' in data:
                        print(data['text'], end='', flush=True)
                except json.JSONDecodeError:
                    print(chunk, end='', flush=True)

        print("\n" + "-" * 60)
        print("Streaming complete!")

    except requests.exceptions.Timeout:
        print("Error: Request timed out")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "vision":
        test_vision_streaming(f"{ENDPOINT_URL}/vision")
    else:
        test_chat_streaming(f"{ENDPOINT_URL}/chat")
