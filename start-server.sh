#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 헤더 출력
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}   CSI 온라인 출결 시스템 서버 시작   ${NC}"
echo -e "${BLUE}=========================================${NC}"

# 필요한 디렉토리 확인 및 생성
echo -e "${YELLOW}로그 디렉토리 확인 중...${NC}"
mkdir -p logs
echo -e "${GREEN}✓ 로그 디렉토리 준비됨${NC}"

# 필요한 패키지 확인
echo -e "${YELLOW}필요한 Node.js 패키지 확인 중...${NC}"
npm install --no-audit || {
  echo -e "${RED}패키지 설치 실패!${NC}"
  exit 1
}
echo -e "${GREEN}✓ 필요한 패키지가 설치됨${NC}"

# 파이썬 파일 존재 확인
if [ ! -f "main.py" ]; then
  echo -e "${YELLOW}main.py 파일이 없습니다. 더미 파일을 생성합니다...${NC}"
  cat > main.py << 'EOF'
import sys
import time

def main():
    print("CSI 예측 더미 서비스가 시작됩니다.")
    print("이 서비스는 실제 예측을 수행하지 않으며, Node.js 서버에서 처리됩니다.")
    print("실제 예측 로직을 구현하려면 이 파일을 수정하세요.")
    
    # 프로세스 유지
    try:
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
        print("\n프로세스가 종료됩니다.")
        sys.exit(0)

if __name__ == "__main__":
    main()
EOF
  echo -e "${GREEN}✓ 더미 main.py 파일 생성됨${NC}"
fi

# 서버 환경 설정
export PORT=8080
export NODE_ENV=development

# 서버 시작
echo -e "${YELLOW}CSI 온라인 출결 시스템 서버를 시작합니다...${NC}"
echo -e "${BLUE}-------------------------------${NC}"
echo -e "${YELLOW}서버 접속 정보:${NC}"
echo -e "  로컬 URL: ${GREEN}http://localhost:${PORT}${NC}"
echo -e "  API URL: ${GREEN}http://localhost:${PORT}/api/health${NC}"
echo -e "${BLUE}-------------------------------${NC}"
echo -e "${YELLOW}Ctrl+C로 서버를 종료할 수 있습니다${NC}"
echo -e "${BLUE}-------------------------------${NC}"

# 서버 실행
node app.js

# 종료 메시지
echo -e "${RED}서버가 종료되었습니다.${NC}" 