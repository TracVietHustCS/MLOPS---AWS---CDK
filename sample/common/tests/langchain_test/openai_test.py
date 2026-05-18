"""
Test OpenAI-compatible API through LiteLLM proxy with structured output support.

NOTE:
- Returning an empty string was caused by treating <|im_start|> as a stop token.
- Qwen emits <|im_start|> as the first assistant token, so including it in the
  stop list halts generation before any text is produced.
- Update LiteLLM/SageMaker configs to stop on <|im_end|> and <|endoftext|> only.
"""

from langchain_openai import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.output_parsers import JsonOutputParser
from pydantic import BaseModel, Field


BASE_URL = "http://acb-dev-bedrock-alb-1695327695.ap-northeast-2.elb.amazonaws.com/api/v1"
API_KEY = "sk-swohna987ds6f0876asdf6asd7f6"
MODEL_NAME = "sagemaker:acb-dev-qwen3-30b-a3b-instruct-2507-fp8"


chat = ChatOpenAI(
    base_url=BASE_URL,
    api_key=API_KEY,
    model=MODEL_NAME,
    temperature=0.3,
    max_tokens=2**14,
    model_kwargs={
        "stream_options": {"include_usage": True},
    },
)

messages = [
   SystemMessage(content="You are a helpful assistant."),
   HumanMessage(content="Generate a story which will exceed 20k characters"),
]

class TestResponse(BaseModel):
   reason: str = Field(..., description="A one-sentence explanation why LiteLLM is amazing.")
   sentiment: str = Field(..., description="The tone of the sentence (e.g. positive, neutral, or excited).")

def non_stream():
   print("=" * 80)
   print("TEST 1: Non-streaming invoke")
   print("=" * 80)

   try:
      response = chat.invoke(messages)
      print(response)
   except Exception as e:
      print(f"FAILED: {e}")

def stream():
    print("\n" + "=" * 80)
    print("TEST 2: Streaming")
    print("=" * 80)

    chunks = []
    for chunk in chat.stream(messages):
        print("chunk", chunk)
        chunks.append(chunk.content)
    print(f"Chunks received: {len(chunks)}")

def structure_output_manual_parsing():
   print("\n" + "=" * 80)
   print("TEST 3: Structured output (with PydanticOutputParser)")
   print("=" * 80)

   try:
      import re
      import json

      parser = PydanticOutputParser(pydantic_object=TestResponse)
      format_instructions = parser.get_format_instructions()

      messages3 = [
         SystemMessage(content=f"You are a helpful assistant that responds in JSON format.\n{format_instructions}"),
         HumanMessage(content="Tell me why LiteLLM is amazing in 1 sentence"),
      ]
      response3 = chat.invoke(messages3)

      content = response3.content

      content = re.sub(r'<think>.*?</think>', '', content, flags=re.DOTALL)  # Remove reasoning tags
      content = re.sub(r'<\|endoftext\|>|<\|im_end\|>|<\|im_start\|>', '', content)  # Remove special tokens

      json_match = re.search(r'\{[^{}]*"reason"[^{}]*"sentiment"[^{}]*\}', content, re.DOTALL)

      if json_match:
         json_str = json_match.group(0)
         parsed_dict = json.loads(json_str)
         parsed = TestResponse(**parsed_dict)
      else:
         parsed = parser.parse(content)

      print(f"SUCCESS:")
      print(f"  Reason: {parsed.reason}")
      print(f"  Sentiment: {parsed.sentiment}")
   except Exception as e:
      print(f"FAILED: {str(e)[:200]}")
      print(f"Raw content: {response3.content[:300]}")

def structure_output_response_format():
   print("\n" + "=" * 80)
   print("TEST 4: Structured output (with with_structured_output)")
   print("=" * 80)

   try:
      structured_chat = chat.with_structured_output(TestResponse)
      messages4 = [
         SystemMessage(content="You are a helpful assistant."),
         HumanMessage(content="Tell me why LiteLLM is amazing in 1 sentence"),
      ]
      response4 = structured_chat.invoke(messages4)
      print(f"SUCCESS:")
      print(f"  Reason: {response4.reason}")
      print(f"  Sentiment: {response4.sentiment}")
   except Exception as e:
      print(f"FAILED: {str(e)}")

if __name__ == "__main__":
   stream()
