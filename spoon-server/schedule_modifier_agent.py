"""
SpoonOS 일정 변경 에이전트
채팅 기반으로 기존 일정을 분석하고 변경사항을 제안하는 AI 에이전트
"""

import asyncio
import json
import re
from datetime import datetime
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

from spoon_ai import ChatBot


class ScheduleModifierAgent:
    """일정 변경 전문가 에이전트"""

    name: str = "ScheduleModifierAgent"
    description: str = "사용자의 요청에 따라 기존 일정을 분석하고 변경사항을 제안하는 AI 에이전트입니다."

    def __init__(self, **kwargs):
        # Gemini 직접 사용 (OpenRouter 대신)
        self.llm = ChatBot(
            llm_provider="gemini",
            model_name="gemini-2.0-flash"
        )
        self.system_prompt = self._build_system_prompt()

    def _build_system_prompt(self) -> str:
        today = datetime.now().strftime("%Y-%m-%d")

        return f"""당신은 일정 관리 전문가입니다.

## 역할
- 사용자의 요청을 분석하여 기존 일정을 어떻게 변경해야 하는지 판단합니다.
- 일정 추가, 수정, 삭제, 이동 등의 변경사항을 JSON 형식으로 응답합니다.
- 오늘 날짜는 {today}입니다.

## 변경 유형
1. **add**: 새로운 일정 추가
2. **modify**: 기존 일정 수정 (날짜, 시간, 제목 변경)
3. **delete**: 일정 삭제
4. **reschedule**: 일정 날짜/시간 변경

## 응답 형식
반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 포함하지 마세요.

```json
{{
  "success": true,
  "action": "add | modify | delete | reschedule",
  "message": "사용자에게 보여줄 친근한 응답 메시지",
  "changes": [
    {{
      "type": "add | modify | delete",
      "schedule_id": "기존 일정 ID (modify/delete 시)",
      "title": "일정 제목",
      "original_date": "변경 전 날짜 (YYYY-MM-DD, modify/reschedule 시)",
      "new_date": "변경 후 날짜 (YYYY-MM-DD)",
      "start_time": "시작 시간 (HH:MM, 선택)",
      "end_time": "종료 시간 (HH:MM, 선택)",
      "color": "색상 (red, orange, yellow, green, blue, purple, pink)"
    }}
  ]
}}
```

## 색상 규칙
- 업무/회의: blue
- 개인 일정: green
- 중요/긴급: red
- 휴식/여가: yellow
- 학습/공부: purple
- 운동/건강: orange
- 기타: pink

## 예시

사용자: "내일 3시에 팀 미팅 잡아줘"
```json
{{
  "success": true,
  "action": "add",
  "message": "내일 오후 3시에 팀 미팅 일정을 추가했어요!",
  "changes": [
    {{
      "type": "add",
      "title": "팀 미팅",
      "new_date": "2024-12-22",
      "start_time": "15:00",
      "end_time": "16:00",
      "color": "blue"
    }}
  ]
}}
```

사용자: "금요일 회의를 다음주 월요일로 옮겨줘"
```json
{{
  "success": true,
  "action": "reschedule",
  "message": "금요일 회의를 다음주 월요일로 옮겼어요!",
  "changes": [
    {{
      "type": "modify",
      "title": "회의",
      "original_date": "2024-12-27",
      "new_date": "2024-12-30",
      "color": "blue"
    }}
  ]
}}
```

## 주의사항
1. 날짜는 항상 YYYY-MM-DD 형식으로 응답하세요.
2. 시간은 24시간 형식(HH:MM)으로 응답하세요.
3. 사용자가 "오늘", "내일", "다음주" 등 상대적 표현을 사용하면 {today} 기준으로 계산하세요.
4. 변경 내용을 친근하고 명확하게 message에 설명하세요.
5. 요청이 불명확하면 success: false와 함께 clarification_needed 메시지를 포함하세요."""

    async def run(self, message: str, current_schedules: list = None) -> str:
        """에이전트 실행"""
        try:
            # 기존 일정 정보가 있으면 컨텍스트에 추가
            context = message
            if current_schedules:
                schedules_str = json.dumps(current_schedules, ensure_ascii=False, indent=2)
                context = f"""현재 일정 목록:
{schedules_str}

사용자 요청: {message}"""

            # 메시지 리스트 형태로 전달
            messages = [{"role": "user", "content": context}]

            response = await self.llm.ask(messages, system_msg=self.system_prompt)

            response_text = str(response)
            json_result = self._extract_json(response_text)

            if json_result:
                return json_result
            else:
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
                parsed = json.loads(json_str)
                return json.dumps(parsed, ensure_ascii=False)
            except json.JSONDecodeError:
                pass

        # { ... } 블록 직접 추출 시도
        brace_pattern = r'\{[\s\S]*"success"[\s\S]*\}'
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
    print("일정 변경 에이전트 테스트")
    print("=" * 50)

    agent = ScheduleModifierAgent()

    # 테스트 요청들
    test_requests = [
        "내일 오후 3시에 팀 미팅 잡아줘",
        "다음주 월요일에 치과 예약 추가해줘",
        "금요일 회의 취소해줘",
    ]

    for request in test_requests:
        print(f"\n📋 요청: {request}")
        print("-" * 30)

        try:
            response = await agent.run(request)
            print(f"🤖 응답:\n{response}")

            try:
                parsed = json.loads(response)
                print(f"\n✅ JSON 파싱 성공! action: {parsed.get('action')}")
            except json.JSONDecodeError as e:
                print(f"\n⚠️ JSON 파싱 실패: {e}")

        except Exception as e:
            print(f"❌ 오류: {e}")

        print()


if __name__ == "__main__":
    asyncio.run(main())
