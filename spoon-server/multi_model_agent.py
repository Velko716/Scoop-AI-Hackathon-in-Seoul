"""
다중 LLM 프로바이더를 지원하는 SpoonOS 에이전트 예제

이 예제는 Gemini, OpenAI, Claude를 모두 활용하는 방법을 보여줍니다.
"""

import asyncio
import os
from enum import Enum
from typing import Optional

from dotenv import load_dotenv

load_dotenv()

from spoon_ai import ChatBot
from spoon_ai.agents import ToolCallAgent
from spoon_ai.tools import BaseTool, ToolManager


# ============================================
# 1. LLM 프로바이더 설정
# ============================================

class LLMProvider(str, Enum):
    """지원하는 LLM 프로바이더"""
    GEMINI = "gemini"
    OPENAI = "openai"
    ANTHROPIC = "anthropic"


# 프로바이더별 추천 모델
RECOMMENDED_MODELS = {
    LLMProvider.GEMINI: "gemini-2.5-flash",
    LLMProvider.OPENAI: "gpt-4o-mini",  # 비용 효율적
    LLMProvider.ANTHROPIC: "claude-3-5-sonnet-20241022",
}

# 프로바이더별 특화 용도
PROVIDER_SPECIALTIES = {
    LLMProvider.GEMINI: "빠른 응답, 멀티모달, 무료",
    LLMProvider.OPENAI: "창의적 글쓰기, 범용성",
    LLMProvider.ANTHROPIC: "코딩, 긴 문서 분석, 정확성",
}


def create_chatbot(
    provider: LLMProvider,
    model: Optional[str] = None
) -> ChatBot:
    """
    지정된 프로바이더로 ChatBot 생성

    Args:
        provider: LLM 프로바이더 (gemini, openai, anthropic)
        model: 사용할 모델 (None이면 기본 모델 사용)

    Returns:
        ChatBot 인스턴스
    """
    model_name = model or RECOMMENDED_MODELS.get(provider)

    return ChatBot(
        llm_provider=provider.value,
        model_name=model_name
    )


# ============================================
# 2. 도구 정의
# ============================================

class WebSearchTool(BaseTool):
    """웹 검색 시뮬레이션 도구"""

    name: str = "web_search"
    description: str = "웹에서 정보를 검색합니다."
    parameters: dict = {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "검색할 쿼리"
            }
        },
        "required": ["query"]
    }

    async def execute(self, query: str) -> str:
        # 실제로는 웹 검색 API를 호출
        return f"'{query}'에 대한 검색 결과: [시뮬레이션된 결과입니다]"


class CodeGeneratorTool(BaseTool):
    """코드 생성 도구 (Claude에 특화)"""

    name: str = "generate_code"
    description: str = "요청에 따라 코드를 생성합니다. Python, Swift 등 지원."
    parameters: dict = {
        "type": "object",
        "properties": {
            "language": {
                "type": "string",
                "description": "프로그래밍 언어 (python, swift, javascript 등)"
            },
            "description": {
                "type": "string",
                "description": "생성할 코드에 대한 설명"
            }
        },
        "required": ["language", "description"]
    }

    async def execute(self, language: str, description: str) -> str:
        return f"[{language}] {description}에 대한 코드 생성 요청을 받았습니다."


class CreativeWritingTool(BaseTool):
    """창의적 글쓰기 도구 (GPT에 특화)"""

    name: str = "creative_writing"
    description: str = "창의적인 글, 스토리, 마케팅 문구 등을 작성합니다."
    parameters: dict = {
        "type": "object",
        "properties": {
            "style": {
                "type": "string",
                "description": "글쓰기 스타일 (formal, casual, creative 등)"
            },
            "topic": {
                "type": "string",
                "description": "글의 주제"
            }
        },
        "required": ["topic"]
    }

    async def execute(self, topic: str, style: str = "casual") -> str:
        return f"'{topic}' 주제로 {style} 스타일의 글을 작성합니다."


# ============================================
# 3. 다중 모델 에이전트
# ============================================

class MultiModelAgent(ToolCallAgent):
    """
    여러 LLM 프로바이더를 지원하는 에이전트

    용도에 따라 다른 모델을 사용할 수 있습니다:
    - 코딩 작업 → Claude
    - 창의적 작업 → GPT-4
    - 빠른 응답 → Gemini
    """

    name: str = "MultiModelAgent"
    description: str = "다양한 LLM을 활용하는 만능 에이전트"

    system_prompt: str = """당신은 다재다능한 AI 어시스턴트입니다.
    사용자의 요청에 따라 적절한 도구를 사용하여 응답하세요.
    코딩, 글쓰기, 검색 등 다양한 작업을 수행할 수 있습니다.
    항상 한국어로 응답하세요."""

    def __init__(
        self,
        provider: LLMProvider = LLMProvider.GEMINI,
        model: Optional[str] = None,
        **kwargs
    ):
        # 도구 설정
        available_tools = ToolManager(tools=[
            WebSearchTool(),
            CodeGeneratorTool(),
            CreativeWritingTool(),
        ])

        # LLM 설정
        llm = create_chatbot(provider, model)

        super().__init__(
            available_tools=available_tools,
            llm=llm,
            **kwargs
        )

        self._provider = provider
        print(f"✅ {provider.value} 모델로 에이전트 초기화 완료")
        print(f"   특화 분야: {PROVIDER_SPECIALTIES.get(provider)}")


# ============================================
# 4. Fallback 에이전트 (자동 전환)
# ============================================

class FallbackAgent:
    """
    프로바이더 장애 시 자동으로 다른 프로바이더로 전환하는 에이전트
    """

    def __init__(self):
        self.providers = [
            LLMProvider.GEMINI,
            LLMProvider.OPENAI,
            LLMProvider.ANTHROPIC,
        ]
        self.current_index = 0
        self._agent: Optional[MultiModelAgent] = None
        self._initialize_agent()

    def _initialize_agent(self):
        """현재 프로바이더로 에이전트 초기화"""
        provider = self.providers[self.current_index]

        # API 키 확인
        key_names = {
            LLMProvider.GEMINI: "GEMINI_API_KEY",
            LLMProvider.OPENAI: "OPENAI_API_KEY",
            LLMProvider.ANTHROPIC: "ANTHROPIC_API_KEY",
        }

        api_key = os.getenv(key_names[provider])
        if not api_key or api_key.startswith("your_"):
            print(f"⚠️ {provider.value} API 키가 설정되지 않음, 다음 프로바이더 시도...")
            self._try_next_provider()
            return

        try:
            self._agent = MultiModelAgent(provider=provider)
        except Exception as e:
            print(f"⚠️ {provider.value} 초기화 실패: {e}")
            self._try_next_provider()

    def _try_next_provider(self):
        """다음 프로바이더로 전환"""
        self.current_index += 1
        if self.current_index < len(self.providers):
            self._initialize_agent()
        else:
            raise RuntimeError("모든 LLM 프로바이더 연결 실패")

    async def run(self, message: str) -> str:
        """메시지 실행 (실패 시 자동 전환)"""
        if not self._agent:
            return "에이전트가 초기화되지 않았습니다."

        try:
            return await self._agent.run(message)
        except Exception as e:
            print(f"⚠️ 실행 실패, 다른 프로바이더로 전환 시도: {e}")
            self._try_next_provider()
            return await self.run(message)


# ============================================
# 5. 테스트
# ============================================

async def test_single_provider():
    """단일 프로바이더 테스트"""
    print("\n" + "=" * 50)
    print("단일 프로바이더 테스트 (Gemini)")
    print("=" * 50)

    agent = MultiModelAgent(provider=LLMProvider.GEMINI)

    response = await agent.run("안녕하세요! 간단한 인사를 해주세요.")
    print(f"\n🤖 응답: {response}")


async def test_fallback():
    """Fallback 에이전트 테스트"""
    print("\n" + "=" * 50)
    print("Fallback 에이전트 테스트")
    print("=" * 50)

    agent = FallbackAgent()

    response = await agent.run("오늘 날씨에 대해 이야기해주세요.")
    print(f"\n🤖 응답: {response}")


async def test_multi_provider():
    """여러 프로바이더 비교 테스트"""
    print("\n" + "=" * 50)
    print("다중 프로바이더 비교 테스트")
    print("=" * 50)

    test_message = "Python으로 피보나치 수열을 계산하는 함수를 설명해주세요."

    for provider in LLMProvider:
        # API 키 확인
        key_names = {
            LLMProvider.GEMINI: "GEMINI_API_KEY",
            LLMProvider.OPENAI: "OPENAI_API_KEY",
            LLMProvider.ANTHROPIC: "ANTHROPIC_API_KEY",
        }

        api_key = os.getenv(key_names[provider])
        if not api_key or api_key.startswith("your_"):
            print(f"\n⏭️ {provider.value}: API 키 없음, 건너뜀")
            continue

        print(f"\n--- {provider.value} ---")
        try:
            agent = MultiModelAgent(provider=provider)
            response = await agent.run(test_message)
            print(f"응답: {response[:200]}...")  # 처음 200자만 출력
        except Exception as e:
            print(f"오류: {e}")


async def main():
    """메인 실행"""
    print("=" * 50)
    print("SpoonOS 다중 LLM 프로바이더 테스트")
    print("=" * 50)

    # 1. 단일 프로바이더 테스트
    await test_single_provider()

    # 2. Fallback 테스트
    # await test_fallback()

    # 3. 다중 프로바이더 비교 (API 키가 모두 있을 때)
    # await test_multi_provider()


if __name__ == "__main__":
    asyncio.run(main())
