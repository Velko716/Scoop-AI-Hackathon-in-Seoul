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
from event_planner_agent import EventPlannerAgent

# 전역 에이전트 인스턴스
agents: dict = {}
fallback_agent: Optional[FallbackAgent] = None
event_planner: Optional[EventPlannerAgent] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """서버 시작/종료 시 에이전트 초기화/정리"""
    global agents, fallback_agent, event_planner

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

    # 행사 기획 전문가 에이전트
    try:
        event_planner = EventPlannerAgent()
        print("  ✅ 행사 기획 전문가 에이전트 준비 완료")
    except Exception as e:
        print(f"  ⚠️ 행사 기획 에이전트 초기화 실패: {e}")

    # OpenRouter 상태 확인
    openrouter_key = os.getenv("OPENAI_API_KEY")
    openrouter_status = "✅ 활성화" if openrouter_key and openrouter_key.startswith("sk-or-") else "❌ API 키 없음"
    print(f"\n📋 OpenRouter API: {openrouter_status}")
    print("   (Gemini, OpenAI, Anthropic 모든 모델 사용 가능)")

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


class EventInfoItem(BaseModel):
    """행사 정보 항목"""
    label: str
    value: str


class EventPlanRequest(BaseModel):
    """행사 기획 요청 모델"""
    event_info: list[EventInfoItem]

    model_config = {
        "json_schema_extra": {
            "example": {
                "event_info": [
                    {"label": "행사명", "value": "송년회"},
                    {"label": "행사 일정", "value": "2024-12-28"},
                    {"label": "행사 장소", "value": "서울"}
                ]
            }
        }
    }


class ScheduleItem(BaseModel):
    """일정 항목"""
    title: str
    startDate: str
    endDate: str
    color: str


class EventPlanResponse(BaseModel):
    """행사 기획 응답 모델"""
    success: bool
    event_name: Optional[str] = None
    schedules: Optional[list[ScheduleItem]] = None
    raw_response: Optional[str] = None
    error: Optional[str] = None


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
    """사용 가능한 LLM 프로바이더 목록 (OpenRouter 통합)"""
    # OpenRouter 키가 있으면 모든 프로바이더 사용 가능
    openrouter_key = os.getenv("OPENAI_API_KEY")
    openrouter_available = bool(openrouter_key and openrouter_key.startswith("sk-or-"))

    specialties = {
        LLMProvider.GEMINI: "빠른 응답, 멀티모달",
        LLMProvider.OPENAI: "창의적 글쓰기, 범용성",
        LLMProvider.ANTHROPIC: "코딩, 긴 문서 분석, 정확성",
    }

    providers = []
    for provider in LLMProvider:
        providers.append(ProviderInfo(
            name=provider.value,
            available=openrouter_available,
            specialty=specialties[provider]
        ))

    return {"providers": providers, "gateway": "OpenRouter"}


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


@app.post("/plan-event", response_model=EventPlanResponse)
async def plan_event(request: EventPlanRequest):
    """
    행사 정보를 받아 체계적인 준비 일정을 자동 생성합니다.
    오늘부터 행사 시작일까지의 준비 일정을 동적으로 생성합니다.
    """
    import re
    from datetime import datetime, timedelta

    try:
        # 행사 정보에서 필요한 데이터 추출
        event_name = ""
        start_date_str = ""
        end_date_str = ""

        for item in request.event_info:
            if item.label == "행사명":
                event_name = item.value
            elif item.label == "행사 시작일":
                start_date_str = item.value
            elif item.label == "행사 마감일":
                end_date_str = item.value

        def parse_date(date_str: str) -> datetime | None:
            """다양한 형식의 날짜 문자열을 파싱"""
            if not date_str:
                return None

            # "2024년 12월 28일" 형식
            match = re.search(r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일', date_str)
            if match:
                year, month, day = map(int, match.groups())
                return datetime(year, month, day)

            # "2024-12-28" 형식
            match = re.search(r'(\d{4})-(\d{1,2})-(\d{1,2})', date_str)
            if match:
                year, month, day = map(int, match.groups())
                return datetime(year, month, day)

            return None

        # 날짜 파싱
        today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        event_start = parse_date(start_date_str)
        event_end = parse_date(end_date_str)

        # 날짜를 찾지 못한 경우 기본값 설정
        if not event_start:
            event_start = today + timedelta(days=30)
        if not event_end:
            event_end = event_start

        # 오늘부터 행사 시작일까지 남은 일수 계산
        days_until_event = (event_start - today).days
        if days_until_event < 1:
            days_until_event = 1  # 최소 1일

        # 준비 일정 템플릿 (30일 기준, 비율로 조정됨)
        preparation_templates = [
            {"title": "행사 기획서 확정", "ratio": 1.0, "duration_ratio": 0.1, "color": "purple"},
            {"title": "예산 확보 및 승인", "ratio": 0.93, "duration_ratio": 0.17, "color": "blue"},
            {"title": "장소 섭외 및 계약", "ratio": 0.7, "duration_ratio": 0.1, "color": "blue"},
            {"title": "협력업체 선정", "ratio": 0.6, "duration_ratio": 0.13, "color": "green"},
            {"title": "홍보물 제작", "ratio": 0.47, "duration_ratio": 0.17, "color": "orange"},
            {"title": "참가자 모집", "ratio": 0.47, "duration_ratio": 0.33, "color": "green"},
            {"title": "비품 준비", "ratio": 0.23, "duration_ratio": 0.1, "color": "yellow"},
            {"title": "리허설 계획 수립", "ratio": 0.17, "duration_ratio": 0.07, "color": "orange"},
            {"title": "최종 점검", "ratio": 0.1, "duration_ratio": 0.07, "color": "red"},
            {"title": "참가자 안내 발송", "ratio": 0.1, "duration_ratio": 0.03, "color": "blue"},
            {"title": "현장 세팅", "ratio": 0.03, "duration_ratio": 0.03, "color": "orange"},
            {"title": "리허설", "ratio": 0.03, "duration_ratio": 0.03, "color": "purple"},
        ]

        schedules = []

        for template in preparation_templates:
            # 비율에 따라 일수 계산
            days_before = max(1, int(days_until_event * template["ratio"]))
            duration = max(1, int(days_until_event * template["duration_ratio"]))

            start = event_start - timedelta(days=days_before)
            end = start + timedelta(days=duration - 1)

            # 오늘 이전 날짜는 오늘로 조정
            if start < today:
                start = today
            if end < start:
                end = start

            # 행사 시작일 이후는 제외
            if start >= event_start:
                continue

            schedules.append(ScheduleItem(
                title=template["title"],
                startDate=start.strftime("%Y-%m-%d"),
                endDate=end.strftime("%Y-%m-%d"),
                color=template["color"]
            ))

        # 행사 일정 추가 (시작일 ~ 마감일)
        if event_start == event_end:
            # 단일일 행사
            schedules.append(ScheduleItem(
                title=f"[D-Day] {event_name}",
                startDate=event_start.strftime("%Y-%m-%d"),
                endDate=event_end.strftime("%Y-%m-%d"),
                color="red"
            ))
        else:
            # 다일 행사
            schedules.append(ScheduleItem(
                title=f"[행사] {event_name}",
                startDate=event_start.strftime("%Y-%m-%d"),
                endDate=event_end.strftime("%Y-%m-%d"),
                color="red"
            ))

        # 시작일 기준 정렬
        schedules.sort(key=lambda x: x.startDate)

        return EventPlanResponse(
            success=True,
            event_name=event_name,
            schedules=schedules
        )

    except Exception as e:
        return EventPlanResponse(
            success=False,
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
