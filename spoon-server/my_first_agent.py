"""
SpoonOS 첫 번째 에이전트 예제
간단한 인사 도구를 가진 에이전트를 만들어봅니다.
"""

import asyncio
from dotenv import load_dotenv

# 환경변수 로드
load_dotenv()

from spoon_ai import ChatBot
from spoon_ai.agents import ToolCallAgent
from spoon_ai.tools import BaseTool, ToolManager


# 1. 커스텀 도구 정의
class GreetingTool(BaseTool):
    """사용자에게 인사하는 도구"""

    name: str = "greeting"
    description: str = "사용자에게 친근한 인사를 합니다. 이름을 입력받아 맞춤 인사를 제공합니다."
    parameters: dict = {
        "type": "object",
        "properties": {
            "name": {
                "type": "string",
                "description": "인사할 사용자의 이름"
            }
        },
        "required": ["name"]
    }

    async def execute(self, name: str = "친구") -> str:
        """인사 실행"""
        return f"안녕하세요, {name}님! SpoonOS에 오신 것을 환영합니다! 🎉"


class CalculatorTool(BaseTool):
    """간단한 계산을 수행하는 도구"""

    name: str = "calculator"
    description: str = "간단한 수학 계산을 수행합니다. 수식을 입력받아 결과를 반환합니다."
    parameters: dict = {
        "type": "object",
        "properties": {
            "expression": {
                "type": "string",
                "description": "계산할 수학 수식 (예: 100 + 200, 15 * 8)"
            }
        },
        "required": ["expression"]
    }

    async def execute(self, expression: str) -> str:
        """계산 실행"""
        try:
            # 안전한 계산을 위해 허용된 문자만 사용
            allowed = set("0123456789+-*/(). ")
            if not all(c in allowed for c in expression):
                return f"오류: 허용되지 않는 문자가 포함되어 있습니다."
            result = eval(expression)
            return f"계산 결과: {expression} = {result}"
        except Exception as e:
            return f"계산 오류: {str(e)}"


# 2. 에이전트 클래스 정의
class MyFirstAgent(ToolCallAgent):
    """나의 첫 번째 SpoonOS 에이전트"""

    name: str = "MyFirstAgent"
    description: str = "인사와 간단한 계산을 수행할 수 있는 친근한 AI 에이전트입니다."

    system_prompt: str = """당신은 친근하고 도움이 되는 AI 어시스턴트입니다.
    사용자의 요청에 따라 적절한 도구를 사용하여 응답하세요.
    항상 한국어로 응답하세요."""

    def __init__(self, **kwargs):
        # 도구 매니저 초기화
        available_tools = ToolManager(tools=[
            GreetingTool(),
            CalculatorTool()
        ])

        # LLM 설정 (OpenRouter 사용)
        llm = ChatBot(
            llm_provider="openai",
            model_name="google/gemini-2.5-flash",
            base_url="https://openrouter.ai/api/v1"
        )

        super().__init__(
            available_tools=available_tools,
            llm=llm,
            **kwargs
        )


async def main():
    """에이전트 실행"""
    print("=" * 50)
    print("SpoonOS 첫 번째 에이전트 테스트")
    print("=" * 50)

    # 에이전트 생성
    agent = MyFirstAgent()

    # 테스트 메시지들
    test_messages = [
        "안녕하세요! 저는 김진혁입니다.",
        "100 + 200은 얼마인가요?",
        "15 * 8 - 30을 계산해주세요."
    ]

    for message in test_messages:
        print(f"\n👤 사용자: {message}")
        print("-" * 40)

        try:
            response = await agent.run(message)
            print(f"🤖 에이전트: {response}")
        except Exception as e:
            print(f"❌ 오류 발생: {str(e)}")

        print()


if __name__ == "__main__":
    asyncio.run(main())
