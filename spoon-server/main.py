"""
SpoonOS API Server
iOS 앱에서 에이전트를 호출할 수 있는 REST API 서버

다중 LLM 프로바이더 지원:
- Gemini (기본)
- OpenAI
- Anthropic (Claude)
"""

import asyncio
import os
from contextlib import asynccontextmanager
from enum import Enum
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# 환경변수 로드
load_dotenv()

# 에이전트 임포트
from my_first_agent import MyFirstAgent
from multi_model_agent import MultiModelAgent, LLMProvider, FallbackAgent

# 전역 에이전트 인스턴스
agents: dict = {}
fallback_agent: Optional[FallbackAgent] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """서버 시작/종료 시 에이전트 초기화/정리"""
    global agents, fallback_agent

    print("🚀 SpoonOS 에이전트 초기화 중...")

    # 기본 에이전트 (Gemini)
    agents["default"] = MyFirstAgent()
    print("  ✅ 기본 에이전트 (Gemini) 준비 완료")

    # Fallback 에이전트
    try:
        fallback_agent = FallbackAgent()
        print("  ✅ Fallback 에이전트 준비 완료")
    except Exception as e:
        print(f"  ⚠️ Fallback 에이전트 초기화 실패: {e}")

    # 사용 가능한 프로바이더 확인
    print("\n📋 사용 가능한 LLM 프로바이더:")
    for provider in LLMProvider:
        key_names = {
            LLMProvider.GEMINI: "GEMINI_API_KEY",
            LLMProvider.OPENAI: "OPENAI_API_KEY",
            LLMProvider.ANTHROPIC: "ANTHROPIC_API_KEY",
        }
        api_key = os.getenv(key_names[provider])
        status = "✅ 활성화" if api_key and not api_key.startswith("your_") else "❌ API 키 없음"
        print(f"  - {provider.value}: {status}")

    print("\n✅ 서버 준비 완료!")
    yield
    print("👋 서버 종료")


# FastAPI 앱 생성
app = FastAPI(
    title="SpoonOS Agent API",
    description="""
iOS 앱에서 SpoonOS 에이전트를 호출하기 위한 API

## 지원 LLM 프로바이더
- **Gemini** (기본): 빠른 응답, 무료
- **OpenAI**: 창의적 글쓰기, 범용성
- **Anthropic (Claude)**: 코딩, 긴 문서 분석
    """,
    version="2.0.0",
    lifespan=lifespan
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================
# 요청/응답 모델
# ============================================

class ChatRequest(BaseModel):
    """채팅 요청 모델"""
    message: str
    provider: Optional[str] = None  # gemini, openai, anthropic

    model_config = {
        "json_schema_extra": {
            "example": {
                "message": "안녕하세요!",
                "provider": "gemini"
            }
        }
    }


class ChatResponse(BaseModel):
    """채팅 응답 모델"""
    success: bool
    response: str
    provider: Optional[str] = None
    error: Optional[str] = None


class ProviderInfo(BaseModel):
    """프로바이더 정보"""
    name: str
    available: bool
    specialty: str


# ============================================
# API 엔드포인트
# ============================================

@app.get("/")
async def root():
    """서버 상태 확인"""
    return {
        "status": "running",
        "message": "SpoonOS Agent API Server",
        "version": "2.0.0",
        "features": ["multi-llm", "fallback", "tools"]
    }


@app.get("/health")
async def health_check():
    """헬스 체크"""
    is_ready = "default" in agents
    return {
        "status": "healthy",
        "agent_ready": is_ready,  # iOS 앱 호환
        "default_agent_ready": is_ready,
        "fallback_ready": fallback_agent is not None
    }


@app.get("/providers")
async def list_providers():
    """사용 가능한 LLM 프로바이더 목록"""
    providers = []

    specialties = {
        LLMProvider.GEMINI: "빠른 응답, 멀티모달, 무료",
        LLMProvider.OPENAI: "창의적 글쓰기, 범용성",
        LLMProvider.ANTHROPIC: "코딩, 긴 문서 분석, 정확성",
    }

    key_names = {
        LLMProvider.GEMINI: "GEMINI_API_KEY",
        LLMProvider.OPENAI: "OPENAI_API_KEY",
        LLMProvider.ANTHROPIC: "ANTHROPIC_API_KEY",
    }

    for provider in LLMProvider:
        api_key = os.getenv(key_names[provider])
        available = bool(api_key and not api_key.startswith("your_"))

        providers.append(ProviderInfo(
            name=provider.value,
            available=available,
            specialty=specialties[provider]
        ))

    return {"providers": providers}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    에이전트와 대화

    - provider를 지정하지 않으면 기본 에이전트 (Gemini) 사용
    - provider를 지정하면 해당 프로바이더로 새 에이전트 생성
    """
    try:
        # 프로바이더 지정된 경우
        if request.provider:
            try:
                provider = LLMProvider(request.provider.lower())
                agent = MultiModelAgent(provider=provider)
                response = await agent.run(request.message)

                return ChatResponse(
                    success=True,
                    response=str(response),
                    provider=provider.value
                )
            except ValueError:
                return ChatResponse(
                    success=False,
                    response="",
                    error=f"지원하지 않는 프로바이더: {request.provider}"
                )

        # 기본 에이전트 사용
        if "default" not in agents:
            raise HTTPException(status_code=503, detail="Agent not initialized")

        response = await agents["default"].run(request.message)

        return ChatResponse(
            success=True,
            response=str(response),
            provider="gemini"
        )

    except Exception as e:
        return ChatResponse(
            success=False,
            response="",
            error=str(e)
        )


@app.post("/chat/fallback", response_model=ChatResponse)
async def chat_with_fallback(request: ChatRequest):
    """
    Fallback 에이전트와 대화

    여러 프로바이더를 순차적으로 시도하여 응답을 반환합니다.
    하나가 실패하면 자동으로 다음 프로바이더로 전환됩니다.
    """
    if fallback_agent is None:
        raise HTTPException(status_code=503, detail="Fallback agent not initialized")

    try:
        response = await fallback_agent.run(request.message)

        return ChatResponse(
            success=True,
            response=str(response),
            provider="fallback"
        )
    except Exception as e:
        return ChatResponse(
            success=False,
            response="",
            error=str(e)
        )


@app.post("/calculate")
async def calculate(expression: str = Query(..., description="계산할 수식")):
    """간단한 계산"""
    try:
        allowed = set("0123456789+-*/(). ")
        if not all(c in allowed for c in expression):
            raise ValueError("허용되지 않는 문자가 포함되어 있습니다.")
        result = eval(expression)
        return {"success": True, "expression": expression, "result": result}
    except Exception as e:
        return {"success": False, "error": str(e)}


# ============================================
# 서버 실행
# ============================================

if __name__ == "__main__":
    import uvicorn

    print("=" * 50)
    print("SpoonOS Agent API Server v2.0")
    print("=" * 50)
    print()
    print("📡 서버 주소: http://localhost:8000")
    print("📚 API 문서: http://localhost:8000/docs")
    print()
    print("지원 프로바이더: Gemini, OpenAI, Anthropic")
    print()
    print("종료하려면 Ctrl+C를 누르세요.")
    print("=" * 50)

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
