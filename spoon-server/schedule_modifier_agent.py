"""
SpoonOS 일정 변경 에이전트
채팅 기반으로 기존 일정을 분석하고 변경사항을 제안하는 에이전트
(규칙 기반 파싱 - API 키 불필요)
"""

import json
import re
from datetime import datetime, timedelta
from typing import Optional


class ScheduleModifierAgent:
    """일정 변경 에이전트 (규칙 기반)"""

    name: str = "ScheduleModifierAgent"
    description: str = "사용자의 요청에 따라 일정을 변경합니다."

    def __init__(self, **kwargs):
        self.today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

    async def run(self, message: str, current_schedules: list = None) -> str:
        """에이전트 실행 - 규칙 기반 파싱"""
        try:
            result = self._parse_request(message)
            return json.dumps(result, ensure_ascii=False)
        except Exception as e:
            return json.dumps({
                "success": False,
                "response_type": "error",
                "error": str(e)
            }, ensure_ascii=False)

    def _parse_request(self, message: str) -> dict:
        """자연어 요청 파싱 - 항상 일정 변경으로 처리"""
        message = message.strip()

        # 삭제 요청 감지
        if any(word in message for word in ["취소", "삭제", "지워", "없애"]):
            return self._handle_delete(message)

        # 수정/이동 요청 감지
        if any(word in message for word in ["옮겨", "변경", "바꿔", "이동"]):
            return self._handle_modify(message)

        # 기본: 추가 요청
        return self._handle_add(message)

    def _handle_add(self, message: str) -> dict:
        """일정 추가 처리"""
        # 날짜 파싱
        date = self._parse_date(message)
        if not date:
            date = self.today + timedelta(days=1)  # 기본값: 내일

        # 시간 파싱
        start_time, end_time = self._parse_time(message)

        # 제목 추출
        title = self._extract_title(message)

        # 색상 결정
        color = self._determine_color(title)

        return {
            "success": True,
            "response_type": "schedule",
            "action": "add",
            "message": f"{date.strftime('%m월 %d일')} {start_time or ''}에 '{title}' 일정을 추가했어요!",
            "changes": [{
                "type": "add",
                "title": title,
                "new_date": date.strftime("%Y-%m-%d"),
                "start_time": start_time,
                "end_time": end_time,
                "color": color
            }]
        }

    def _handle_modify(self, message: str) -> dict:
        """일정 수정 처리"""
        # 원래 날짜와 새 날짜 파싱 시도
        dates = self._parse_multiple_dates(message)

        original_date = dates[0] if len(dates) > 0 else self.today
        new_date = dates[1] if len(dates) > 1 else original_date + timedelta(days=1)

        title = self._extract_title(message)
        color = self._determine_color(title)

        return {
            "success": True,
            "response_type": "schedule",
            "action": "reschedule",
            "message": f"'{title}' 일정을 {new_date.strftime('%m월 %d일')}로 옮겼어요!",
            "changes": [{
                "type": "modify",
                "title": title,
                "original_date": original_date.strftime("%Y-%m-%d"),
                "new_date": new_date.strftime("%Y-%m-%d"),
                "color": color
            }]
        }

    def _handle_delete(self, message: str) -> dict:
        """일정 삭제 처리"""
        date = self._parse_date(message)
        title = self._extract_title(message)

        return {
            "success": True,
            "response_type": "schedule",
            "action": "delete",
            "message": f"'{title}' 일정을 삭제했어요!",
            "changes": [{
                "type": "delete",
                "title": title,
                "original_date": date.strftime("%Y-%m-%d") if date else None
            }]
        }

    def _parse_date(self, text: str) -> Optional[datetime]:
        """텍스트에서 날짜 파싱"""
        today = self.today

        # 상대적 날짜 표현
        if "오늘" in text:
            return today
        if "내일" in text:
            return today + timedelta(days=1)
        if "모레" in text:
            return today + timedelta(days=2)
        if "글피" in text:
            return today + timedelta(days=3)

        # 요일 파싱
        weekdays = {"월요일": 0, "화요일": 1, "수요일": 2, "목요일": 3, "금요일": 4, "토요일": 5, "일요일": 6}
        for day_name, day_num in weekdays.items():
            if day_name in text:
                days_ahead = day_num - today.weekday()
                if days_ahead <= 0:
                    days_ahead += 7
                if "다음주" in text or "다음 주" in text:
                    days_ahead += 7
                return today + timedelta(days=days_ahead)

        # "다음주" 단독
        if "다음주" in text or "다음 주" in text:
            return today + timedelta(days=7)

        # MM월 DD일 형식
        match = re.search(r'(\d{1,2})월\s*(\d{1,2})일', text)
        if match:
            month, day = int(match.group(1)), int(match.group(2))
            year = today.year
            result = datetime(year, month, day)
            if result < today:
                result = datetime(year + 1, month, day)
            return result

        # DD일 형식 (월 없이 일만 있는 경우 - 현재 월 또는 다음 달로 추정)
        match = re.search(r'(\d{1,2})일', text)
        if match:
            day = int(match.group(1))
            year = today.year
            month = today.month
            try:
                result = datetime(year, month, day)
                # 이미 지난 날짜면 다음 달로
                if result < today:
                    month += 1
                    if month > 12:
                        month = 1
                        year += 1
                    result = datetime(year, month, day)
                return result
            except ValueError:
                # 유효하지 않은 날짜 (예: 2월 30일)
                pass

        # YYYY-MM-DD 형식
        match = re.search(r'(\d{4})-(\d{1,2})-(\d{1,2})', text)
        if match:
            return datetime(int(match.group(1)), int(match.group(2)), int(match.group(3)))

        return None

    def _parse_multiple_dates(self, text: str) -> list:
        """여러 날짜 파싱 (일정 이동용)"""
        dates = []

        # 첫 번째 날짜 (from)
        first_date = self._parse_date(text.split("을")[0] if "을" in text else text.split("를")[0] if "를" in text else text)
        if first_date:
            dates.append(first_date)

        # 두 번째 날짜 (to) - "~로" 뒤의 날짜
        for marker in ["로 ", "으로 "]:
            if marker in text:
                second_part = text.split(marker)[0].split()[-1] if marker in text else ""
                # 다시 파싱
                second_date = self._parse_date(text.split(marker)[0])
                if second_date and (not dates or second_date != dates[0]):
                    dates.append(second_date)
                    break

        # "다음주", "내일" 등이 뒤에 있으면 추가
        if len(dates) < 2:
            for keyword in ["다음주", "내일", "모레"]:
                if keyword in text:
                    if keyword == "다음주":
                        dates.append(self.today + timedelta(days=7))
                    elif keyword == "내일":
                        dates.append(self.today + timedelta(days=1))
                    elif keyword == "모레":
                        dates.append(self.today + timedelta(days=2))
                    break

        return dates

    def _parse_time(self, text: str) -> tuple:
        """시간 파싱"""
        start_time = None
        end_time = None

        # "오후 3시", "오전 10시" 형식
        match = re.search(r'(오전|오후)?\s*(\d{1,2})시', text)
        if match:
            period = match.group(1)
            hour = int(match.group(2))

            if period == "오후" and hour < 12:
                hour += 12
            elif period == "오전" and hour == 12:
                hour = 0
            elif not period and hour < 9:  # 시간대 없으면 오후로 추정 (9시 미만)
                hour += 12

            start_time = f"{hour:02d}:00"
            end_time = f"{hour + 1:02d}:00"

        # "15:00" 형식
        match = re.search(r'(\d{1,2}):(\d{2})', text)
        if match:
            hour, minute = int(match.group(1)), int(match.group(2))
            start_time = f"{hour:02d}:{minute:02d}"
            end_time = f"{hour + 1:02d}:{minute:02d}"

        return start_time, end_time

    def _extract_title(self, text: str) -> str:
        """일정 제목 추출"""
        # 불필요한 단어 제거
        remove_words = [
            "잡아줘", "추가해줘", "만들어줘", "넣어줘", "등록해줘",
            "취소해줘", "삭제해줘", "지워줘", "없애줘",
            "옮겨줘", "변경해줘", "바꿔줘",
            "오늘", "내일", "모레", "글피", "다음주", "다음 주",
            "월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일",
            "오전", "오후", "에", "으로", "로", "를", "을", "좀", "해줘"
        ]

        title = text
        for word in remove_words:
            title = title.replace(word, " ")

        # 시간 표현 제거
        title = re.sub(r'\d{1,2}시', '', title)
        title = re.sub(r'\d{1,2}:\d{2}', '', title)
        title = re.sub(r'\d{1,2}월\s*\d{1,2}일', '', title)
        title = re.sub(r'\d{1,2}일날?', '', title)  # "25일" 또는 "25일날" 제거

        # 정리
        title = " ".join(title.split()).strip()

        if not title:
            title = "새 일정"

        return title

    def _determine_color(self, title: str) -> str:
        """제목에 따른 색상 결정"""
        title_lower = title.lower()

        # 업무/회의
        if any(word in title_lower for word in ["회의", "미팅", "meeting", "업무", "보고"]):
            return "blue"

        # 운동/건강
        if any(word in title_lower for word in ["운동", "헬스", "gym", "조깅", "요가", "병원", "치과"]):
            return "orange"

        # 학습
        if any(word in title_lower for word in ["공부", "스터디", "study", "강의", "수업", "학습"]):
            return "purple"

        # 휴식/여가
        if any(word in title_lower for word in ["휴식", "영화", "데이트", "여행", "쇼핑"]):
            return "yellow"

        # 중요/긴급
        if any(word in title_lower for word in ["중요", "긴급", "마감", "deadline"]):
            return "red"

        # 기본: 개인 일정
        return "green"


async def main():
    """테스트 실행"""
    print("=" * 50)
    print("일정 변경 에이전트 테스트 (규칙 기반)")
    print("=" * 50)

    agent = ScheduleModifierAgent()

    test_requests = [
        "내일 오후 3시에 팀 미팅 잡아줘",
        "다음주 월요일에 치과 예약 추가해줘",
        "금요일 회의 취소해줘",
        "수요일 미팅을 목요일로 옮겨줘",
    ]

    for request in test_requests:
        print(f"\n📋 요청: {request}")
        print("-" * 30)

        try:
            response = await agent.run(request)
            parsed = json.loads(response)
            print(f"✅ 결과: {parsed.get('message')}")
            print(f"   액션: {parsed.get('action')}")
            if parsed.get('changes'):
                for change in parsed['changes']:
                    print(f"   - {change.get('type')}: {change.get('title')} @ {change.get('new_date')}")
        except Exception as e:
            print(f"❌ 오류: {e}")


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
