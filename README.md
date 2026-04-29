# RunSheet

> 행사 준비, 변수 하나에 일정 전체가 흔들리죠.
> RunSheet가 확실하게 잡아드립니다.

**Apple Developer Academy @ Seoul AI Hackathon**
**Track 1 - AI Agentic Infra & Productivity AI**

---

## Problem

소규모 행사 대행 업체(10인 미만, 약 2,900개사)는 **엑셀에 의존**하며 일정을 관리합니다.

| 기존 도구 | 문제점 |
|----------|--------|
| **엑셀** | 수동 수정에 시간 소요, 변경 시 연쇄 영향 파악 어려움 |
| **Asana, Monday** | IT Sprint 방식에 최적화, 시간 축 기반 행사 기획과 맞지 않음 |

> "Asana를 쓰다가 다시 엑셀로 돌아갔다. 전체 스케줄을 한눈에 봐야 하는데 Asana는 그게 안 된다."
> — 현업자 인터뷰

---

## Solution

**범용 PM 툴은 행사 기획에 맞지 않습니다.**
**RunSheet는 전체 일정을 한눈에 보면서, 변수가 생기면 AI가 자동으로 재조정합니다.**

### 핵심 기능

| 기능 | 설명 |
|------|------|
| **AI 일정 자동 생성** | 행사 정보 입력 → 대시보드 자동 구성 |
| **줌아웃 타임라인 뷰** | 전체 일정을 한눈에 조망 (엑셀 대체) |
| **변수 → AI 재조정** | 지연/변경 발생 시 수정안 + 근거 제시 |
| **리스크 알림** | 지연 항목 및 연쇄 영향 자동 표시 |

---

## Demo Flow

```
1. 행사 정보 입력 (일정, 장소, 인원, 예산, 개요)
          ↓
2. AI가 대시보드 자동 생성
          ↓
3. 캘린더 & 체크리스트로 전체 일정 조망
          ↓
4. 챗봇에 변수 입력: "A 납품 3일 지연"
          ↓
5. AI가 조정안 제시 + 리스크 설명
          ↓
6. 선택한 조정안으로 대시보드 업데이트
```

---

## Tech Stack

| 구분 | 기술 |
|------|------|
| **iOS** | SwiftUI, Swift 6.0, MVVM, @Observable |
| **Backend** | Python, FastAPI, uvicorn |
| **AI Agent** | SpoonOS SDK (spoon-ai) |
| **LLM** | Gemini 2.5 Flash, GPT-4o-mini, Claude 3.5 Sonnet |
| **API Gateway** | OpenRouter (단일 API 키로 다중 LLM) |

### Architecture

```
┌─────────────┐       HTTP        ┌─────────────┐      OpenRouter     ┌─────────────┐
│   iOS App   │ ────────────────▶ │   FastAPI   │ ─────────────────▶  │     LLM     │
│  (SwiftUI)  │                   │  (SpoonOS)  │                     │  Provider   │
│             │ ◀──────────────── │             │ ◀───────────────────│             │
└─────────────┘      JSON         └─────────────┘      Response       └─────────────┘
```

---

## Competitive Edge

| 항목 | Excel | Asana, Monday | RunSheet |
|------|-------|---------------|----------|
| 전체 일정 조망 | ○ | × | ○ |
| AI 자동 재조정 | × | × | ○ |
| 변수 대응 속도 | 느림 | 느림 | 즉시 |
| 학습 곡선 | 낮음 | 높음 | 낮음 |

---

## Project Structure

```
RunSheet/
├── ScoopAIHackathon/           # iOS App
│   ├── Presentations/
│   │   ├── Onboarding/         # 온보딩
│   │   ├── InputEvent/         # 행사 정보 입력 (4단계)
│   │   ├── Dashboard/          # 캘린더 + 체크리스트
│   │   └── Chat/               # AI 챗봇
│   ├── Services/               # API 통신
│   └── Models/                 # 데이터 모델
│
└── spoon-server/               # Python Backend
    ├── main.py                 # FastAPI 서버
    └── .env                    # API 키 설정
```

---

## How to Run

```bash
# 1. 서버 실행
source spoon-env/bin/activate
./spoon-server/start_server.sh

# 2. iOS 앱 실행 (Xcode)
open ScoopAIHackathon/ScoopAIHackathon.xcodeproj
# Cmd + R
```

---

## Team

| 역할 | 이름 | 담당 |
|------|------|------|
| **PM** | 양희준 | 기획, 사업 모델, 프로젝트 관리 |
| **Design** | 이주은 | UI/UX, 타임라인 뷰 |
| **Tech** | 김동민 | 캘린더/투두리스트, 데이터 구조 |
| **Tech** | 진아현 | 플로우 구현, 프롬프트 작성 |
| **Tech** | 김진혁 | 챗봇, 백엔드 |

---

**Apple Developer Academy @ Seoul**
