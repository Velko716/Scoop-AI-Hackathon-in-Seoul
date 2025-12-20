# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack AI chat application for the Apple Developer Academy Scoop AI Hackathon in Seoul. SwiftUI iOS app communicates with a Python FastAPI backend powered by SpoonOS AI Agent SDK.

## Architecture

```
iOS App (SwiftUI) ──HTTP/JSON──▶ FastAPI Server (SpoonOS) ──API──▶ LLM Provider
   InputEventView                     main.py                   Gemini/OpenAI/Claude
```

- **iOS**: Swift 6.0, SwiftUI, async/await, iOS 26.0+
- **Backend**: Python 3.12, FastAPI, uvicorn, SpoonOS SDK
- **LLM Providers**: Gemini (default), OpenAI, Anthropic

## Build & Run Commands

### iOS App

```bash
# Build
xcodebuild -project ScoopAIHackathon/ScoopAIHackathon.xcodeproj -scheme ScoopAIHackathon -configuration Debug build

# Test
xcodebuild -project ScoopAIHackathon/ScoopAIHackathon.xcodeproj -scheme ScoopAIHackathon test

# Clean
xcodebuild -project ScoopAIHackathon/ScoopAIHackathon.xcodeproj clean
```

Or open in Xcode: Cmd+B to build, Cmd+R to run.

### Python Server

```bash
# Activate virtual environment
source spoon-env/bin/activate

# Start server (port 8000)
./spoon-server/start_server.sh
# or directly:
cd spoon-server && python main.py

# Install dependencies (if needed)
pip install spoon-ai-sdk spoon-toolkits fastapi uvicorn python-dotenv

# Test agent standalone
python spoon-server/my_first_agent.py
```

## iOS App Structure (MVVM)

```
ScoopAIHackathon/ScoopAIHackathon/
├── App/
│   └── ScoopAIHackathonApp.swift     # Entry point → InputEventView
├── Presentations/
│   ├── InputEvent/                    # 이벤트 입력 화면 (현재 메인 화면)
│   │   ├── Views/InputEventView.swift
│   │   ├── ViewModels/InputEventViewModel.swift
│   │   └── Component/InputEventCom.swift
│   ├── Home/                          # 홈 화면
│   │   ├── Views/HomeView.swift
│   │   ├── ViewModels/HomeViewModel.swift
│   │   └── Component/HomeCom.swift
│   └── Chat/                          # 채팅 화면
│       ├── Views/ChatView.swift
│       ├── ViewModels/ChatViewModel.swift
│       └── Component/MessageBubble.swift
├── Services/
│   └── SpoonAgentService.swift        # HTTP client (@Observable, @MainActor)
├── Models/
│   ├── ChatMessage.swift
│   ├── HealthCheck.swift
│   ├── ServerStatus.swift
│   └── DTO/
│       ├── ChatRequest.swift
│       └── ChatResponse.swift
├── Common/
│   ├── Error/SpoonAgentError.swift
│   └── Helper/SpoonAgentService+.swift
└── Resource/Font/Font.swift
```

### Key iOS Components

- **Entry Point**: `InputEventView` (앱 시작 화면)
- **SpoonAgentService**: 싱글톤 HTTP 클라이언트, `/chat` 및 `/health` 엔드포인트 처리
- **ChatView**: 에이전트와 실시간 채팅 UI (연결 상태 표시, 자동 스크롤)

## Python Server (`spoon-server/`)

- `main.py` - FastAPI 서버, lifespan으로 에이전트 관리, CORS 활성화
- `my_first_agent.py` - 기본 `ToolCallAgent` (Greeting, Calculator 도구)
- `multi_model_agent.py` - `MultiModelAgent` 및 `FallbackAgent` (Gemini→OpenAI→Claude)

## SpoonOS Agent Pattern

```python
from spoon_ai import ChatBot
from spoon_ai.agents import ToolCallAgent
from spoon_ai.tools import BaseTool, ToolManager

class MyTool(BaseTool):
    name: str = "tool_name"
    description: str = "What this tool does"
    parameters: dict = {"type": "object", "properties": {...}}

    async def execute(self, **kwargs) -> str:
        return "result"

class MyAgent(ToolCallAgent):
    def __init__(self):
        tools = ToolManager(tools=[MyTool()])
        llm = ChatBot(llm_provider="gemini", model_name="gemini-2.5-flash")
        super().__init__(available_tools=tools, llm=llm)

# Usage
response = await agent.run("user message")
```

## Configuration

- `spoon-server/.env` - API keys (gitignored): `GEMINI_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`
- `GoogleService-Info.plist`, `Config.xcconfig` - gitignored iOS config files
- iOS requires App Transport Security exception for localhost (already configured)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Server status |
| GET | `/health` | Agent ready status (`agent_ready` field) |
| GET | `/providers` | Available LLM providers list |
| POST | `/chat` | Chat with optional `provider` param |
| POST | `/chat/fallback` | Auto-fallback through provider chain |

API docs: `http://localhost:8000/docs`

## Development Workflow

1. Start server first: `./spoon-server/start_server.sh`
2. Run iOS app in simulator (Cmd+R)
3. iOS app connects to `localhost:8000` by default
