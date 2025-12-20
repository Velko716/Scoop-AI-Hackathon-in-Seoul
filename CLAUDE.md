# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack AI chat application for the Apple Developer Academy Scoop AI Hackathon in Seoul. SwiftUI iOS app communicates with a Python FastAPI backend powered by SpoonOS AI Agent SDK.

## Architecture

```
iOS App (SwiftUI) ──HTTP/JSON──▶ FastAPI Server (SpoonOS) ──API──▶ LLM Provider
     ChatView                        main.py                    Gemini/OpenAI/Claude
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

## Key Components

### iOS (`ScoopAIHackathon/ScoopAIHackathon/`)

- `Services/SpoonAgentService.swift` - Singleton HTTP client (`@Observable`, `@MainActor`), handles `/chat` and `/health` endpoints
- `Presentations/Chat/ChatView.swift` - Main chat UI with connection status indicator
- `Models/DTO/` - `ChatRequest` and `ChatResponse` DTOs matching server models

### Python (`spoon-server/`)

- `main.py` - FastAPI server with lifespan-managed agents, CORS enabled
- `my_first_agent.py` - Basic `ToolCallAgent` with sample tools (Greeting, Calculator)
- `multi_model_agent.py` - `MultiModelAgent` and `FallbackAgent` (Gemini→OpenAI→Claude chain)

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
- iOS requires App Transport Security exception for localhost (already configured in Info.plist)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Server status |
| GET | `/health` | Agent ready status (`agent_ready` field) |
| GET | `/providers` | Available LLM providers list |
| POST | `/chat` | Chat with optional `provider` param |
| POST | `/chat/fallback` | Auto-fallback through provider chain |

API docs available at `http://localhost:8000/docs` when server is running.

## Development Workflow

1. Start server first: `./spoon-server/start_server.sh`
2. Run iOS app in simulator (Cmd+R)
3. iOS app connects to `localhost:8000` by default
