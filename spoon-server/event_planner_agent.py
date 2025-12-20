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
        # LLM 설정 (Gemini 사용)
        self.llm = ChatBot(
            llm_provider="gemini",
            model_name="gemini-2.5-flash"
        )

        # 시스템 프롬프트
        self.system_prompt = self._build_system_prompt()

    def _build_system_prompt(self) -> str:
        # 오늘 날짜 기준으로 예시 생성
        today = datetime.now()
        example_event_date = (today + timedelta(days=30)).strftime("%Y-%m-%d")
        example_d_minus_21 = (today + timedelta(days=9)).strftime("%Y-%m-%d")
        example_d_minus_14 = (today + timedelta(days=16)).strftime("%Y-%m-%d")

        return f"""당신은 10년 이상의 경험을 가진 전문 행사 기획자입니다.

## 역할
- 행사 정보를 분석하여 성공적인 행사를 위한 체계적인 준비 일정을 수립합니다.
- 각 준비 단계의 우선순위와 소요 기간을 고려하여 현실적인 타임라인을 제시합니다.

## 일정 기획 원칙
1. 행사 D-Day를 기준으로 역산하여 준비 일정을 수립합니다.
2. 충분한 여유 시간을 확보하여 예상치 못한 상황에 대비합니다.
3. 관련 업무는 병렬로 진행할 수 있도록 그룹화합니다.

## 주요 준비 단계 (일반적인 행사 기준)
- D-30: 행사 기획서 확정, 예산 확보
- D-21: 장소 섭외 및 계약, 협력업체 선정
- D-14: 홍보물 제작, 참가자 모집 시작
- D-7: 비품 준비, 리허설 계획
- D-3: 최종 점검, 참가자 안내
- D-1: 현장 세팅, 리허설
- D-Day: 행사 진행

## 중요: 응답 형식
반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 포함하지 마세요.

```json
{{
  "success": true,
  "event_name": "행사명",
  "schedules": [
    {{
      "title": "준비 작업 제목",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD",
      "color": "색상"
    }}
  ]
}}
```

색상은 다음 중 선택: red, orange, yellow, green, blue, purple, pink

## 예시 응답
행사 날짜가 {example_event_date}인 경우:

```json
{{
  "success": true,
  "event_name": "개발자 컨퍼런스",
  "schedules": [
    {{"title": "장소 섭외 및 계약", "startDate": "{example_d_minus_21}", "endDate": "{example_d_minus_21}", "color": "blue"}},
    {{"title": "홍보물 제작", "startDate": "{example_d_minus_14}", "endDate": "{example_d_minus_14}", "color": "green"}},
    {{"title": "[D-Day] 개발자 컨퍼런스", "startDate": "{example_event_date}", "endDate": "{example_event_date}", "color": "red"}}
  ]
}}
```

행사 정보를 분석하여 5-10개의 준비 일정을 생성하세요."""

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
                return json_result
            else:
                # JSON을 찾지 못한 경우, 응답 전체 반환
                return response_text

        except Exception as e:
            return json.dumps({
                "success": False,
                "error": str(e)
            }, ensure_ascii=False)

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
