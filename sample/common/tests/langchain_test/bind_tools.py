"""Simple tool calling test with langchain_openai."""

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage
from langchain_core.tools import tool
import json



@tool
def get_weather(location: str) -> str:
    """Get the current weather for a location."""
    return f"Weather in {location}: Sunny, 22°C"

@tool
def multiply(a: int, b: int) -> int:
    """Multiply two numbers together."""
    return a * b


BASE_URL = "http://acb-dev-bedrock-alb-1695327695.ap-northeast-2.elb.amazonaws.com/api/v1"
API_KEY = "sk-swohna987ds6f0876asdf6asd7f6"
MODEL_NAME = "sagemaker:acb-dev-qwen3-30b-a3b-instruct-2507-fp8"



def main() -> None:
    """Test tool calling."""
    print("=" * 80)
    print("Testing Tool Calling")
    print("=" * 80)
    llm = ChatOpenAI(
        base_url=BASE_URL,
        api_key=API_KEY,
        model=MODEL_NAME,
        temperature=0,
        )


    tools = [get_weather, multiply]

    llm_with_tools = llm.bind_tools(tools)


    print("\n[Test 1] Query: What's the weather in Hanoi?")

    try:

        response = llm_with_tools.invoke([HumanMessage(content="What's the weather in Hanoi?")])

       

        if hasattr(response, 'tool_calls') and response.tool_calls:

            print(f"\n✅ Tool calls detected: {len(response.tool_calls)}")

            for tc in response.tool_calls:

                print(f"   - Tool: {tc['name']}")

                print(f"   - Args: {json.dumps(tc['args'], indent=6)}")


                if tc['name'] == 'get_weather':

                    result = get_weather.invoke(tc['args'])

                    print(f"   - Result: {result}")

        else:

            print("\n❌ No tool calls detected")

    except Exception as e:

        print(f"\n❌ Error: {e}")


    print("\n" + "-" * 80)

    print("[Test 2] Query: Multiply 15 and 7")

    try:

        response = llm_with_tools.invoke([HumanMessage(content="Multiply 15 and 7")])

       

        if hasattr(response, 'tool_calls') and response.tool_calls:

            print(f"\n✅ Tool calls detected: {len(response.tool_calls)}")

            for tc in response.tool_calls:

                print(f"   - Tool: {tc['name']}")

                print(f"   - Args: {json.dumps(tc['args'], indent=6)}")


                if tc['name'] == 'multiply':

                    result = multiply.invoke(tc['args'])

                    print(f"   - Result: {result}")

        else:

            print("\n❌ No tool calls detected")

    except Exception as e:

        print(f"\n❌ Error: {e}")

    print("\n" + "=" * 80)

    print("Done")

    print("=" * 80)



if __name__ == "__main__":

    main()  
