#!/bin/bash

# SpoonOS Server 시작 스크립트

echo "========================================"
echo "  SpoonOS Agent Server 시작"
echo "========================================"

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."

# 가상환경 활성화
source spoon-env/bin/activate

# 서버 디렉토리로 이동
cd spoon-server

# 서버 실행
python main.py
