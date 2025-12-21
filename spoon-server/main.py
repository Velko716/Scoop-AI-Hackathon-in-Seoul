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
from schedule_modifier_agent import ScheduleModifierAgent

# 전역 에이전트 인스턴스
agents: dict = {}
fallback_agent: Optional[FallbackAgent] = None
event_planner: Optional[EventPlannerAgent] = None
schedule_modifier: Optional[ScheduleModifierAgent] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """서버 시작/종료 시 에이전트 초기화/정리"""
    global agents, fallback_agent, event_planner, schedule_modifier

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

    # 일정 변경 에이전트
    try:
        schedule_modifier = ScheduleModifierAgent()
        print("  ✅ 일정 변경 에이전트 준비 완료")
    except Exception as e:
        print(f"  ⚠️ 일정 변경 에이전트 초기화 실패: {e}")

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


class TodoItem(BaseModel):
    """체크리스트 항목"""
    title: str
    scheduleId: str  # 연관된 스케줄 ID (title-startDate)
    priority: int    # 우선순위 (1: 높음, 2: 중간, 3: 낮음)
    category: str    # 카테고리 (기획, 예산, 장소, 홍보, 운영 등)


class EventPlanResponse(BaseModel):
    """행사 기획 응답 모델"""
    success: bool
    event_name: Optional[str] = None
    schedules: Optional[list[ScheduleItem]] = None
    todos: Optional[list[TodoItem]] = None  # 체크리스트 추가
    raw_response: Optional[str] = None
    error: Optional[str] = None


class CurrentScheduleItem(BaseModel):
    """현재 일정 항목 (일정 변경 요청 시)"""
    id: Optional[str] = None
    title: str
    date: str
    start_time: Optional[str] = None
    end_time: Optional[str] = None


class ScheduleModifyRequest(BaseModel):
    """일정 변경 요청 모델"""
    message: str
    current_schedules: Optional[list[CurrentScheduleItem]] = None

    model_config = {
        "json_schema_extra": {
            "example": {
                "message": "내일 오후 3시에 팀 미팅 잡아줘",
                "current_schedules": [
                    {"id": "1", "title": "기존 회의", "date": "2024-12-22"}
                ]
            }
        }
    }


class ScheduleChangeItem(BaseModel):
    """일정 변경 항목"""
    type: str  # add, modify, delete
    schedule_id: Optional[str] = None
    title: Optional[str] = None
    original_date: Optional[str] = None
    new_date: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    color: Optional[str] = None


class ScheduleModifyResponse(BaseModel):
    """일정 변경 응답 모델"""
    success: bool
    action: Optional[str] = None
    message: Optional[str] = None
    changes: Optional[list[ScheduleChangeItem]] = None
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

        # 준비 기간은 항상 45일로 고정 (행사 시작일 기준 역산)
        # 과거/미래 행사 모두 동일하게 처리
        preparation_days = 45

        # 준비 일정 템플릿 (행사 시작일 기준 역산)
        # days_before: 행사 시작일 기준 몇 일 전에 시작
        # duration: 작업 기간 (일)
        preparation_templates = [
            {"title": "행사 기획서 확정", "days_before": 45, "duration": 5, "color": "purple"},
            {"title": "예산 확보 및 승인", "days_before": 42, "duration": 7, "color": "blue"},
            {"title": "장소 섭외 및 계약", "days_before": 35, "duration": 5, "color": "blue"},
            {"title": "협력업체 선정", "days_before": 30, "duration": 5, "color": "green"},
            {"title": "홍보물 제작", "days_before": 25, "duration": 7, "color": "orange"},
            {"title": "참가자 모집", "days_before": 25, "duration": 15, "color": "green"},
            {"title": "비품 준비", "days_before": 14, "duration": 5, "color": "yellow"},
            {"title": "리허설 계획 수립", "days_before": 10, "duration": 3, "color": "orange"},
            {"title": "최종 점검", "days_before": 7, "duration": 3, "color": "red"},
            {"title": "참가자 안내 발송", "days_before": 5, "duration": 2, "color": "blue"},
            {"title": "현장 세팅", "days_before": 2, "duration": 1, "color": "orange"},
            {"title": "리허설", "days_before": 1, "duration": 1, "color": "purple"},
        ]

        schedules = []

        for template in preparation_templates:
            # 행사 시작일 기준으로 역산하여 날짜 계산
            start = event_start - timedelta(days=template["days_before"])
            end = start + timedelta(days=template["duration"] - 1)

            # 행사 시작일 이후로 넘어가면 행사 전날까지로 조정
            if end >= event_start:
                end = event_start - timedelta(days=1)
            if start >= event_start:
                continue

            # 오늘 이전 날짜는 스킵
            if end < today:
                continue
            # 시작일이 오늘 이전이면 오늘로 조정
            if start < today:
                start = today

            schedules.append(ScheduleItem(
                title=template["title"],
                startDate=start.strftime("%Y-%m-%d"),
                endDate=end.strftime("%Y-%m-%d"),
                color=template["color"]
            ))

        # 행사 일정 추가 (시작일 ~ 마감일 전체를 하나의 행사로 표시)
        schedules.append(ScheduleItem(
            title=f"[행사] {event_name}",
            startDate=event_start.strftime("%Y-%m-%d"),
            endDate=event_end.strftime("%Y-%m-%d"),
            color="red"
        ))

        # 시작일 기준 정렬
        schedules.sort(key=lambda x: x.startDate)

        # ============================================
        # 체크리스트(Todo) 생성 - 우선순위 기반
        # ============================================
        # 각 스케줄에 대한 체크리스트 템플릿
        todo_templates = {
            "행사 기획서 확정": [
                {"title": "행사 목표 및 KPI 정의", "priority": 1, "category": "기획"},
                {"title": "세부 프로그램 구성", "priority": 1, "category": "기획"},
                {"title": "예산 초안 작성", "priority": 2, "category": "예산"},
                {"title": "이해관계자 승인 받기", "priority": 1, "category": "기획"},
            ],
            "예산 확보 및 승인": [
                {"title": "상세 예산안 작성", "priority": 1, "category": "예산"},
                {"title": "결재 서류 준비", "priority": 1, "category": "예산"},
                {"title": "예산 승인 완료", "priority": 1, "category": "예산"},
            ],
            "장소 섭외 및 계약": [
                {"title": "후보 장소 리스트업", "priority": 1, "category": "장소"},
                {"title": "장소 답사 및 확인", "priority": 1, "category": "장소"},
                {"title": "계약서 검토 및 서명", "priority": 1, "category": "장소"},
                {"title": "장소 사용료 입금", "priority": 2, "category": "예산"},
            ],
            "협력업체 선정": [
                {"title": "케이터링 업체 선정", "priority": 2, "category": "운영"},
                {"title": "음향/조명 업체 섭외", "priority": 2, "category": "운영"},
                {"title": "계약 조건 협의", "priority": 2, "category": "운영"},
            ],
            "홍보물 제작": [
                {"title": "홍보 컨셉 확정", "priority": 1, "category": "홍보"},
                {"title": "포스터/배너 디자인", "priority": 1, "category": "홍보"},
                {"title": "SNS 홍보 콘텐츠 제작", "priority": 2, "category": "홍보"},
                {"title": "인쇄물 발주", "priority": 2, "category": "홍보"},
            ],
            "참가자 모집": [
                {"title": "참가 신청 폼 생성", "priority": 1, "category": "홍보"},
                {"title": "홍보 채널 배포", "priority": 1, "category": "홍보"},
                {"title": "참가자 명단 관리", "priority": 2, "category": "운영"},
                {"title": "참가 확정 안내 발송", "priority": 2, "category": "운영"},
            ],
            "비품 준비": [
                {"title": "필요 비품 목록 작성", "priority": 1, "category": "운영"},
                {"title": "비품 구매/대여", "priority": 1, "category": "운영"},
                {"title": "비품 수량 확인", "priority": 2, "category": "운영"},
            ],
            "리허설 계획 수립": [
                {"title": "리허설 일정 확정", "priority": 1, "category": "운영"},
                {"title": "스태프 역할 분담", "priority": 1, "category": "운영"},
                {"title": "진행 시나리오 작성", "priority": 1, "category": "기획"},
            ],
            "최종 점검": [
                {"title": "체크리스트 최종 확인", "priority": 1, "category": "운영"},
                {"title": "비상 연락망 정리", "priority": 1, "category": "운영"},
                {"title": "날씨/교통 상황 체크", "priority": 2, "category": "운영"},
            ],
            "참가자 안내 발송": [
                {"title": "안내 메일/문자 발송", "priority": 1, "category": "운영"},
                {"title": "오시는 길 안내 첨부", "priority": 2, "category": "운영"},
                {"title": "준비물 안내", "priority": 2, "category": "운영"},
            ],
            "현장 세팅": [
                {"title": "장소 도착 및 점검", "priority": 1, "category": "운영"},
                {"title": "테이블/의자 배치", "priority": 1, "category": "운영"},
                {"title": "음향/조명 테스트", "priority": 1, "category": "운영"},
                {"title": "안내 표지판 설치", "priority": 2, "category": "운영"},
            ],
            "리허설": [
                {"title": "전체 리허설 진행", "priority": 1, "category": "운영"},
                {"title": "문제점 파악 및 수정", "priority": 1, "category": "운영"},
                {"title": "스태프 최종 브리핑", "priority": 1, "category": "운영"},
            ],
        }

        # 행사 진행 체크리스트
        event_todos = [
            {"title": "행사장 최종 점검", "priority": 1, "category": "운영"},
            {"title": "참가자 등록 데스크 운영", "priority": 1, "category": "운영"},
            {"title": "행사 진행 모니터링", "priority": 1, "category": "운영"},
            {"title": "사진/영상 촬영", "priority": 2, "category": "홍보"},
            {"title": "참가자 만족도 조사", "priority": 3, "category": "기획"},
            {"title": "행사 종료 후 정리", "priority": 1, "category": "운영"},
        ]

        todos = []

        # 각 스케줄에 대해 체크리스트 생성
        for schedule in schedules:
            schedule_id = f"{schedule.title}-{schedule.startDate}"

            # 행사 본행사
            if schedule.title.startswith("[행사]"):
                for todo_template in event_todos:
                    todos.append(TodoItem(
                        title=todo_template["title"],
                        scheduleId=schedule_id,
                        priority=todo_template["priority"],
                        category=todo_template["category"]
                    ))
            else:
                # 준비 일정
                template_todos = todo_templates.get(schedule.title, [])
                for todo_template in template_todos:
                    todos.append(TodoItem(
                        title=todo_template["title"],
                        scheduleId=schedule_id,
                        priority=todo_template["priority"],
                        category=todo_template["category"]
                    ))

        # 우선순위 기준 정렬 (priority 낮을수록 높은 우선순위)
        todos.sort(key=lambda x: (x.priority, x.scheduleId))

        return EventPlanResponse(
            success=True,
            event_name=event_name,
            schedules=schedules,
            todos=todos
        )

    except Exception as e:
        return EventPlanResponse(
            success=False,
            error=str(e)
        )


@app.post("/modify-schedule", response_model=ScheduleModifyResponse)
async def modify_schedule(request: ScheduleModifyRequest):
    """
    채팅 기반 일정 변경

    사용자의 자연어 요청을 분석하여 일정 추가/수정/삭제를 처리합니다.
    - message: 사용자 요청 (예: "내일 3시에 회의 잡아줘")
    - current_schedules: 현재 일정 목록 (선택, 일정 수정/삭제 시 참조)
    """
    import json

    if schedule_modifier is None:
        raise HTTPException(status_code=503, detail="Schedule modifier agent not initialized")

    try:
        # 현재 일정을 dict 리스트로 변환
        current_schedules_dict = None
        if request.current_schedules:
            current_schedules_dict = [
                {
                    "id": s.id,
                    "title": s.title,
                    "date": s.date,
                    "start_time": s.start_time,
                    "end_time": s.end_time
                }
                for s in request.current_schedules
            ]

        # 에이전트 호출
        response = await schedule_modifier.run(
            message=request.message,
            current_schedules=current_schedules_dict
        )

        # JSON 파싱 시도
        try:
            parsed = json.loads(response)

            # 변경사항 파싱
            changes = None
            if parsed.get("changes"):
                changes = [
                    ScheduleChangeItem(
                        type=c.get("type", "add"),
                        schedule_id=c.get("schedule_id"),
                        title=c.get("title"),
                        original_date=c.get("original_date"),
                        new_date=c.get("new_date"),
                        start_time=c.get("start_time"),
                        end_time=c.get("end_time"),
                        color=c.get("color", "blue")
                    )
                    for c in parsed["changes"]
                ]

            return ScheduleModifyResponse(
                success=parsed.get("success", True),
                action=parsed.get("action"),
                message=parsed.get("message", "일정이 변경되었습니다."),
                changes=changes
            )

        except json.JSONDecodeError:
            # JSON 파싱 실패 시 원본 응답 반환
            return ScheduleModifyResponse(
                success=True,
                message=response
            )

    except Exception as e:
        return ScheduleModifyResponse(
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
