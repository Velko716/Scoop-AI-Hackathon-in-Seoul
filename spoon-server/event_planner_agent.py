"""
SpoonOS 행사 기획 전문가 에이전트
행사 정보를 받아 상세 일정을 기획하는 AI 에이전트

Tool 없이 직접 JSON 형식으로 응답하도록 구현
(Gemini function_call + text 혼합 응답 이슈 해결)
"""

import asyncio
import json
import re
from datetime import datetime, timedelta
from typing import Optional
from dotenv import load_dotenv

# 환경변수 로드
load_dotenv()

from spoon_ai import ChatBot


class EventPlannerAgent:
    """행사 기획 전문가 에이전트 (Tool-free 버전)"""

    name: str = "EventPlannerAgent"
    description: str = "행사 정보를 분석하고 체계적인 일정을 기획하는 전문가 AI 에이전트입니다."

    def __init__(self, **kwargs):
        # LLM 설정 (OpenRouter 사용)
        self.llm = ChatBot(
            llm_provider="openai",
            model_name="google/gemini-2.5-flash",
            base_url="https://openrouter.ai/api/v1"
        )

        # 시스템 프롬프트
        self.system_prompt = self._build_system_prompt()

    def _build_system_prompt(self) -> str:
        # 오늘 날짜
        today = datetime.now().strftime("%Y-%m-%d")

        return f"""당신은 10년 이상의 경험을 가진 전문 행사 기획자입니다.

## 역할
- 행사 정보를 분석하여 성공적인 행사를 위한 체계적인 준비 일정을 수립합니다.
- 오늘({today})부터 행사 시작일까지의 준비 일정을 계획합니다.
- 행사 기간(시작일~마감일) 동안의 행사 진행 일정도 포함합니다.

## 일정 기획 원칙
1. 오늘({today})부터 행사 시작일까지 남은 기간에 맞춰 준비 일정을 수립합니다.
2. 행사는 시작일부터 마감일까지의 기간 동안 진행됩니다 (마감일만 D-Day가 아님).
3. 남은 기간이 짧으면 준비 일정을 압축하고, 길면 여유있게 배치합니다.
4. 관련 업무는 병렬로 진행할 수 있도록 그룹화합니다.

## 주요 준비 단계 (남은 기간에 맞춰 조정)
- 기획서 확정, 예산 확보
- 장소 섭외 및 계약, 협력업체 선정
- 홍보물 제작, 참가자 모집
- 비품 준비, 리허설 계획
- 최종 점검, 참가자 안내
- 현장 세팅, 리허설
- 행사 진행 (시작일~마감일)

## 중요: 응답 형식
반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 포함하지 마세요.
@@ -82,23 +81,19 @@ def _build_system_prompt(self) -> str:
```

색상은 다음 중 선택: red, orange, yellow, green, blue, purple, pink
- 행사 본행사: red
- 기획/총괄: purple
- 재무/예산: blue
- 장소/설비: orange
- 홍보: green
- 운영/리허설: yellow

## 주의사항
1. 오늘 날짜는 {today}입니다. 모든 준비 일정은 오늘 이후여야 합니다.
2. 행사 기간이 여러 날이면 "[행사] 행사명"으로 시작일~마감일 전체를 하나의 일정으로 표시하세요.
3. 행사 기간이 하루면 "[D-Day] 행사명"으로 표시하세요.
4. 준비 일정은 오늘부터 행사 시작일 전날까지 배치하세요.
5. 5-10개의 준비 일정을 생성하세요."""

    async def run(self, message: str) -> str:
        """에이전트 실행"""
        try:
            # LLM 호출
            response = await self.llm.chat(
                message=message,
                system_prompt=self.system_prompt
            )

            response_text = str(response)

            # JSON 블록 추출 시도
            json_result = self._extract_json(response_text)

            if json_result:
                # 오늘 이전 날짜 필터링
                filtered_result = self._filter_past_schedules(json_result)
                return filtered_result
            else:
                # JSON을 찾지 못한 경우, 응답 전체 반환
                return response_text

        except Exception as e:
            return json.dumps({
                "success": False,
                "error": str(e)
            }, ensure_ascii=False)

    def _filter_past_schedules(self, json_str: str) -> str:
        """오늘 이전 날짜의 스케줄을 필터링"""
        try:
            data = json.loads(json_str)
            today = datetime.now().strftime("%Y-%m-%d")

            if "schedules" in data:
                # 오늘 이후 스케줄만 유지
                filtered_schedules = []
                for schedule in data["schedules"]:
                    start_date = schedule.get("startDate", "")
                    # startDate가 오늘 이후인 경우만 포함
                    if start_date >= today:
                        filtered_schedules.append(schedule)

                data["schedules"] = filtered_schedules

            return json.dumps(data, ensure_ascii=False)
        except json.JSONDecodeError:
            return json_str

    def _extract_json(self, text: str) -> Optional[str]:
        """텍스트에서 JSON 블록 추출"""
        # ```json ... ``` 블록 추출
        json_block_pattern = r'```json\s*([\s\S]*?)\s*```'
        match = re.search(json_block_pattern, text)

        if match:
            json_str = match.group(1).strip()
            try:
                # JSON 유효성 검사
                parsed = json.loads(json_str)
                return json.dumps(parsed, ensure_ascii=False)
            except json.JSONDecodeError:
                pass

        # { ... } 블록 직접 추출 시도
        brace_pattern = r'\{[\s\S]*"schedules"[\s\S]*\}'
        match = re.search(brace_pattern, text)

        if match:
            try:
                parsed = json.loads(match.group())
                return json.dumps(parsed, ensure_ascii=False)
            except json.JSONDecodeError:
                pass

        return None


async def main():
    """테스트 실행"""
    print("=" * 50)
    print("행사 기획 전문가 에이전트 테스트 (Tool-free)")
    print("=" * 50)

    agent = EventPlannerAgent()

    # 테스트 행사 정보
    test_event = """
    다음 행사 정보를 기반으로 준비 일정을 기획해주세요:

    - 행사명: Apple Developer Academy 송년 네트워킹 파티
    - 행사 일정: 2024년 12월 28일 (토) 18:00 - 22:00
    - 행사 장소: 서울특별시 강남구 테헤란로 521 파르나스타워 42층
    - 행사 예산: 5,000,000원
    - 행사 대상: Apple Developer Academy @POSTECH 러너 및 졸업생
    - 행사 인원: 약 150명 (러너 100명, 졸업생 50명)
    - 행사 비품: 음향장비, 빔프로젝터, 명찰, 현수막, 포토존 소품
    - 행사 종류: 네트워킹 파티 / 송년회
    - 행사 취지: 한 해를 마무리하며 러너들 간의 친목 도모 및 졸업생과의 네트워킹 기회 제공
    - 행사 내용: 개회식, 올해의 프로젝트 시상, 네트워킹 타임, 경품 추첨, 포토타임
    """

    print(f"\n📋 요청:\n{test_event}")
    print("-" * 50)

    try:
        response = await agent.run(test_event)
        print(f"\n🤖 에이전트 응답:\n{response}")

        # JSON 파싱 테스트
        try:
            parsed = json.loads(response)
            print(f"\n✅ JSON 파싱 성공!")
            print(f"   행사명: {parsed.get('event_name')}")
            print(f"   일정 수: {len(parsed.get('schedules', []))}")
        except json.JSONDecodeError as e:
            print(f"\n⚠️ JSON 파싱 실패: {e}")

    except Exception as e:
        print(f"❌ 오류 발생: {str(e)}")


if __name__ == "__main__":
    asyncio.run(main())
