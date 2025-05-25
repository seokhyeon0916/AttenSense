# Node.js 베이스 이미지 사용
FROM node:18-slim

# 작업 디렉토리 설정
WORKDIR /app

# 패키지 파일 복사 및 종속성 설치
COPY package*.json ./
RUN npm ci --only=production

# 애플리케이션 코드 복사
COPY . ./

# 8080 포트 노출
EXPOSE 8080

# 컨테이너 시작 명령어
CMD [ "node", "app.js" ] 