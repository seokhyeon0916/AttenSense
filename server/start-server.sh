#!/bin/bash
mkdir -p logs
export PORT=8080
export NODE_ENV=development
echo "CSI 온라인 출결 시스템 서버를 시작합니다..."
echo "서버 접속 정보: http://localhost:$PORT"
node app.js
