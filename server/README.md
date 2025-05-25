# AttenSense 서버

Wi-Fi CSI 기반 출결 관리 시스템의 백엔드 서버입니다.

## 주요 기능

- API 엔드포인트 제공
- 라즈베리파이 CSI 데이터 처리
- Firebase Firestore 연동
- 세션 관리 및 출석 처리

## 설치 방법

```bash
# 필요 패키지 설치
npm install

# 개발 모드 실행
npm run dev

# 프로덕션 모드 실행
npm start
```

## 환경 변수 설정 (.env 파일)

```
# Firebase 설정
FIREBASE_TYPE=service_account
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour Private Key\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=your-client-email@example.com
FIREBASE_CLIENT_ID=your-client-id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_X509_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/your-service-account-email

# 서버 설정
PORT=3000
NODE_ENV=development
```

## 서버 배포 가이드

### 1. 서버 프로세스 관리

PM2를 사용하여 서버를 관리하는 것이 좋습니다:

```bash
# PM2 전역 설치
npm install -g pm2

# 서버 시작
pm2 start app.js --name "attensense-server"

# 서버 상태 확인
pm2 status

# 서버 로그 확인
pm2 logs attensense-server

# 서버 재시작
pm2 restart attensense-server

# 시스템 부팅 시 자동 시작 설정
pm2 startup
pm2 save
```

### 2. 방화벽 설정

포트 3000이 외부에서 접근 가능하도록 방화벽 설정이 필요합니다:

```bash
# Ubuntu/Debian
sudo ufw allow 3000/tcp

# CentOS/RHEL
sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
```

### 3. 보안 설정

프로덕션 환경에서는 다음 보안 설정을 고려하세요:

- HTTPS 설정 (Nginx/Apache 프록시 권장)
- 적절한 CORS 설정 (현재 app.js에 구현됨)
- API 키 인증 추가
- 요청 속도 제한 설정

### 4. 로그 관리

로그 관리를 위해 winston 같은 로깅 라이브러리 사용:

```bash
npm install winston
```

### 5. 백업 전략

Firebase Firestore 데이터 정기 백업 설정:

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# 로그인
firebase login

# Firestore 백업 스크립트 예시
firebase firestore:export backups/$(date +%Y-%m-%d)
```

## API 엔드포인트

### 서버 상태 확인

```
GET /api/health
```

### 수업 관리

```
POST /api/class/start
POST /api/class/end
```

### 출석 관리

```
POST /api/attendance/check
GET /api/attendance/status
```

### CSI 데이터 관리

```
POST /api/csi/capture
GET /api/csi/data
```

## 문제 해결

### 일반적인 오류

1. **서버 연결 문제**

   - 포트 3000이 열려있는지 확인
   - 서버 프로세스가 실행 중인지 확인

2. **Firebase 오류**

   - serviceAccountKey.json 파일이 유효한지 확인
   - Firebase 프로젝트 설정 확인

3. **CSI 데이터 캡처 오류**
   - 라즈베리파이와의 연결 확인
   - Wi-Fi 인터페이스가 모니터 모드인지 확인

## 서버 모니터링

프로덕션 환경에서는 정기적인 모니터링을 설정하세요:

1. **서버 상태 모니터링**

   - `/api/health` 엔드포인트 정기 점검

2. **성능 모니터링**

   - 메모리 사용량 및 CPU 사용률 확인

3. **오류 알림**
   - 중요 오류 발생 시 이메일/SMS 알림 설정

## 성능 최적화

필요한 경우 다음과 같은 최적화를 고려하세요:

1. **캐싱 전략 구현**

   - 자주 요청되는 데이터 캐싱

2. **데이터베이스 쿼리 최적화**

   - Firestore 인덱스 최적화
   - 쿼리 패턴 개선

3. **부하 테스트**
   - 많은 동시 사용자 처리 능력 테스트
