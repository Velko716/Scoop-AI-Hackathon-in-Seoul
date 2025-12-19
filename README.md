# Scoop-AI-Hackathon-in-Seoul

애플 디벨로퍼 아카데미 @ 서울 AI 해커톤 프로젝트

---

## 목차

1. [프로젝트 소개](#프로젝트-소개)
2. [왜 SpoonOS인가?](#왜-spoonos인가)
3. [시스템 아키텍처](#시스템-아키텍처)
4. [설치 가이드](#설치-가이드)
5. [서버 실행](#서버-실행)
6. [iOS 앱 연동](#ios-앱-연동)
7. [다중 LLM 지원](#다중-llm-지원)
8. [프로젝트 구조](#프로젝트-구조)
9. [트러블슈팅](#트러블슈팅)

---

## 프로젝트 소개

이 프로젝트는 **SpoonOS SDK**를 활용하여 AI 에이전트를 구축하고, **iOS 앱**과 연동하는 풀스택 AI 애플리케이션입니다.

### 주요 기능

- AI 에이전트와 실시간 채팅
- 다중 LLM 프로바이더 지원 (Gemini, OpenAI, Claude)
- 커스텀 도구(Tool) 기반 에이전트 확장
- iOS 네이티브 앱 연동

---

## 왜 SpoonOS인가?

### SpoonOS란?

SpoonOS는 AI 에이전트를 쉽게 구축할 수 있는 Python SDK입니다.

### 선택 이유

| 특징 | 설명 |
|------|------|
| **다중 LLM 지원** | Gemini, OpenAI, Anthropic, DeepSeek 등 여러 프로바이더를 하나의 인터페이스로 |
| **Tool 기반 확장** | 커스텀 도구를 쉽게 추가하여 에이전트 기능 확장 |
| **ReAct 패턴** | 추론(Reasoning)과 행동(Action)을 결합한 지능형 에이전트 |
| **MCP 프로토콜** | 모듈식 도구 시스템으로 유연한 아키텍처 |
| **간편한 설정** | 환경변수 기반 설정, 자동 오류 처리 |

### 다른 프레임워크와 비교

| 항목 | SpoonOS | LangChain | 직접 구현 |
|------|---------|-----------|----------|
| 학습 곡선 | 낮음 | 높음 | 매우 높음 |
| 다중 LLM | 기본 지원 | 플러그인 필요 | 직접 구현 |
| 도구 시스템 | 내장 | 내장 | 직접 구현 |
| 설정 복잡도 | 간단 | 복잡 | 매우 복잡 |

---

## 시스템 아키텍처

```
┌─────────────────┐     HTTP      ┌─────────────────┐     API      ┌─────────────────┐
│                 │    Request    │                 │    Call      │                 │
│    iOS App      │ ───────────▶  │  FastAPI Server │ ───────────▶ │   LLM Provider  │
│   (SwiftUI)     │               │  (SpoonOS SDK)  │              │ (Gemini/OpenAI) │
│                 │ ◀───────────  │                 │ ◀─────────── │                 │
└─────────────────┘    Response   └─────────────────┘   Response   └─────────────────┘
```

### 데이터 흐름

1. **iOS 앱** → 사용자 메시지 입력
2. **FastAPI 서버** → 메시지 수신, SpoonOS 에이전트 실행
3. **LLM 프로바이더** → AI 응답 생성
4. **iOS 앱** → 응답 표시

---

## 설치 가이드

### 사전 요구사항

- macOS (Apple Silicon 또는 Intel)
- Python 3.12 이상
- Xcode 15 이상
- Homebrew

### Step 1: Python 3.12 설치

```bash
# Homebrew로 설치
brew install python@3.12

# 설치 확인
/opt/homebrew/bin/python3.12 --version
# 출력: Python 3.12.x
```

### Step 2: 가상환경 생성

```bash
# 프로젝트 루트에서 실행
/opt/homebrew/bin/python3.12 -m venv spoon-env

# 가상환경 활성화
source spoon-env/bin/activate
```

### Step 3: SpoonOS 패키지 설치

```bash
# 가상환경 활성화 상태에서
pip install spoon-ai-sdk
pip install spoon-toolkits  # 추가 도구 (선택)
```

### Step 4: API 키 설정

#### Gemini API 키 발급 (무료)

1. [Google AI Studio](https://aistudio.google.com/apikey) 접속
2. Google 계정으로 로그인
3. **"Create API Key"** 클릭
4. 프로젝트 선택 후 키 생성
5. 생성된 키 복사 (예: `AIzaSy...`)

#### OpenAI API 키 발급 (유료)

1. [OpenAI Platform](https://platform.openai.com/api-keys) 접속
2. 계정 로그인
3. **"Create new secret key"** 클릭
4. 생성된 키 복사 (예: `sk-...`)

#### 환경변수 설정

```bash
# spoon-server 디렉토리로 이동
cd spoon-server

# .env 파일 생성/편집
cat > .env << 'EOF'
# LLM 프로바이더 API 키
GEMINI_API_KEY=your_gemini_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# 기본 설정
DEFAULT_LLM_PROVIDER=gemini
DEFAULT_MODEL=gemini-2.5-flash
EOF
```

### Step 5: 설치 확인

```bash
# 가상환경 활성화
source spoon-env/bin/activate

# SpoonOS 버전 확인
python -c "import spoon_ai; print('SpoonOS:', spoon_ai.__version__)"
```

---

## 서버 실행

### 빠른 시작

```bash
# 방법 1: 스크립트 사용
./spoon-server/start_server.sh

# 방법 2: 직접 실행
source spoon-env/bin/activate
cd spoon-server
python main.py
```

### 서버 시작 시 출력

```
==================================================
SpoonOS Agent API Server v2.0
==================================================

📡 서버 주소: http://localhost:8000
📚 API 문서: http://localhost:8000/docs

🚀 SpoonOS 에이전트 초기화 중...
  ✅ 기본 에이전트 (Gemini) 준비 완료
  ✅ Fallback 에이전트 준비 완료

📋 사용 가능한 LLM 프로바이더:
  - gemini: ✅ 활성화
  - openai: ✅ 활성화
  - anthropic: ❌ API 키 없음

✅ 서버 준비 완료!
```

### API 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/` | 서버 상태 확인 |
| GET | `/health` | 에이전트 준비 상태 |
| GET | `/providers` | 사용 가능한 LLM 목록 |
| POST | `/chat` | 에이전트와 대화 |
| POST | `/chat/fallback` | Fallback 모드 대화 |

### API 사용 예시

```bash
# 기본 채팅 (Gemini 사용)
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "안녕하세요!"}'

# OpenAI 사용
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "안녕하세요!", "provider": "openai"}'

# 프로바이더 목록 확인
curl http://localhost:8000/providers
```

---

## iOS 앱 연동

### Xcode 설정

1. `ScoopAIHackathon.xcodeproj` 열기
2. Target → Info 탭에서 다음 추가:
   ```
   App Transport Security Settings (Dictionary)
   └── Allow Arbitrary Loads in Local Networking → YES
   ```

### 주요 파일

| 파일 | 설명 |
|------|------|
| `SpoonAgentService.swift` | 서버 API 통신 서비스 |
| `ChatView.swift` | 채팅 UI |
| `SpoonAgentError.swift` | 에러 타입 정의 |

### 사용법

```swift
// 에이전트 서비스 사용
let service = SpoonAgentService.shared

// 연결 테스트
let isConnected = await service.testConnection()

// 채팅
let result = await service.chat(message: "안녕하세요!")
switch result {
case .success(let response):
    print("응답: \(response)")
case .failure(let error):
    print("오류: \(error.localizedDescription)")
}
```

### 실행 순서

1. **서버 먼저 시작**: `./spoon-server/start_server.sh`
2. **iOS 시뮬레이터 실행**: Xcode에서 Cmd+R
3. 채팅 시작!

---

## 다중 LLM 지원

### 지원 프로바이더

| 프로바이더 | 특화 분야 | 비용 |
|-----------|----------|------|
| **Gemini** | 빠른 응답, 멀티모달 | 무료 티어 |
| **OpenAI** | 창의적 글쓰기, 범용성 | 유료 |
| **Claude** | 코딩, 긴 문서 분석 | 유료 |

### LLM 선택 로직

```
1. 기본 요청 (/chat)
   └── provider 파라미터 없음 → Gemini (기본)
   └── provider: "openai" → OpenAI
   └── provider: "anthropic" → Claude

2. Fallback 요청 (/chat/fallback)
   └── Gemini 시도 → 실패 시 → OpenAI → 실패 시 → Claude
```

### 프로바이더별 API 키 발급

| 프로바이더 | 발급 URL |
|-----------|----------|
| Gemini | https://aistudio.google.com/apikey |
| OpenAI | https://platform.openai.com/api-keys |
| Claude | https://console.anthropic.com/ |

---

## 프로젝트 구조

```
Scoop-AI-Hackathon-in-Seoul/
│
├── spoon-server/                    # Python 백엔드
│   ├── main.py                      # FastAPI 서버 (다중 LLM 지원)
│   ├── my_first_agent.py            # 기본 에이전트 (Gemini)
│   ├── multi_model_agent.py         # 다중 모델 에이전트 + Fallback
│   ├── start_server.sh              # 서버 시작 스크립트
│   └── .env                         # API 키 설정
│
├── ScoopAIHackathon/                # iOS 앱
│   └── ScoopAIHackathon/
│       ├── App/
│       │   └── ScoopAIHackathonApp.swift
│       ├── Presentations/
│       │   ├── ContentView.swift
│       │   └── Chat/
│       │       └── ChatView.swift
│       ├── Services/
│       │   └── SpoonAgentService.swift
│       └── Common/
│           └── Error/
│               └── SpoonAgentError.swift
│
├── spoon-env/                       # Python 가상환경 (gitignore)
├── .env.example                     # 환경변수 템플릿
├── CLAUDE.md                        # Claude Code 가이드
└── README.md                        # 이 파일
```

---

## 트러블슈팅

### Python 버전 문제

```bash
# Python 3.12 확인
/opt/homebrew/bin/python3.12 --version

# 없으면 설치
brew install python@3.12
```

### 서버 연결 안됨 (iOS)

1. 서버가 실행 중인지 확인: `curl http://localhost:8000/health`
2. App Transport Security 설정 확인
3. 시뮬레이터 사용 시 `localhost`, 실제 기기는 Mac IP 주소 사용

### API 키 오류

```bash
# .env 파일 확인
cat spoon-server/.env

# API 키 테스트
cd spoon-server
python -c "
from dotenv import load_dotenv
import os
load_dotenv()
print('Gemini:', 'OK' if os.getenv('GEMINI_API_KEY') else 'Missing')
print('OpenAI:', 'OK' if os.getenv('OPENAI_API_KEY') else 'Missing')
"
```

### Rate Limit 오류

- Gemini: 무료 티어는 분당 요청 제한 있음, 잠시 후 재시도
- OpenAI: 유료 플랜 확인 필요

---

## 참고 문서

- [SpoonOS 공식 문서](https://xspoonai.github.io/)
- [SpoonOS GitHub](https://github.com/XSpoonAi/spoon-core)
- [FastAPI 문서](https://fastapi.tiangolo.com/)
- [Google AI Studio](https://aistudio.google.com/)
- [OpenAI Platform](https://platform.openai.com/)

---
