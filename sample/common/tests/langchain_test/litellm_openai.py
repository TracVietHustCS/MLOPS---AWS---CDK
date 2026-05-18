from langchain_openai import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from pydantic import BaseModel, Field

BASE_URL = "http://acb-dev-alb-1257863866.ap-northeast-2.elb.amazonaws.com"
API_KEY = "sk-Xj45JZP5rag45wHjLbnveg"
MODEL_NAME = "acb-dev-qwen3-30b-a3b-instruct-2507-fp8"


class TestResponse(BaseModel):
   reason: str = Field(..., description="A one-sentence explanation why LiteLLM is amazing.")
   sentiment: str = Field(..., description="The tone of the sentence (e.g. positive, neutral, or excited).")


def test_simple_chat():
    """Test 1: Simple chat without structured output"""
    print("=" * 80)
    print("TEST 1: Simple Chat (No Structured Output)")
    print("=" * 80)

    chat = ChatOpenAI(
        openai_api_base=BASE_URL,
        model=MODEL_NAME,
        api_key=API_KEY,
        temperature=0.7,
        max_tokens=2048
    )


    messages = [
        SystemMessage(content="You are a helpful assistant."),
        HumanMessage(content="test from litellm. tell me why it's amazing in 1 sentence")
    ]

    response = chat.invoke(messages)
    print(response)

def main():
    test_simple_chat()

if __name__ == "__main__":
    main()
