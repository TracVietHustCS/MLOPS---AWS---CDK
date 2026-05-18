import json
import re

from langchain_openai import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from langchain_core.exceptions import OutputParserException
from pydantic import BaseModel, Field


class TestResponse(BaseModel):
    reason: str = Field(..., description="A one-sentence explanation why LiteLLM is amazing.")
    sentiment: str = Field(..., description="The tone of the sentence (e.g. positive, neutral, or excited).")


BASE_URL = "http://acb-dev-bedrock-alb-1695327695.ap-northeast-2.elb.amazonaws.com/api/v1"
API_KEY = "sk-swohna987ds6f0876asdf6asd7f6"
MODEL_NAME = "sagemaker:acb-dev-qwen3-30b-a3b-instruct-2507-fp8"


chat = ChatOpenAI(
    base_url=BASE_URL,
    api_key=API_KEY,
    model=MODEL_NAME,
    temperature=0.3,
)


def _infer_sentiment(text: str) -> str:
    lowered = text.lower()
    if any(word in lowered for word in ("amazing", "great", "excellent", "love", "fantastic", "positive")):
        return "positive"
    if any(word in lowered for word in ("bad", "terrible", "awful", "hate", "negative")):
        return "negative"
    return "neutral"


structured_chat = chat.with_structured_output(TestResponse, method="json_mode")

messages = [
    SystemMessage(
        content=(
            "You are a helpful assistant that must respond in valid JSON matching the schema "
            "{'reason': string, 'sentiment': string}. Avoid reasoning tags or extra fields."
        )
    ),
    HumanMessage(content="test from litellm. tell me why it's amazing in 1 sentence"),
]

structured_response = structured_chat.invoke(messages)
parsed = structured_response

print(parsed)
print(f"Reason: {parsed.reason}")
print(f"Sentiment: {parsed.sentiment}")
