# CSI 기반 온라인 출결 시스템 서버 구현 노트

이 문서는 와이파이 CSI 기반 온라인 출결 시스템의 서버 구현에 대한 설명입니다. 서버 관리자는 이 문서를 참고하여 서버 코드를 이해하고 관리할 수 있습니다.

## 구현 개요

- **서버 환경**: Node.js + Express
- **데이터 저장**: 현재는 메모리 내 임시 저장 (실제 구현 시 Firebase 또는 다른 데이터베이스로 교체 필요)
- **주요 기능**: CSI 예측, 출석 확인, 수업 관리, 학생 관리, 출석 통계, 비활동 감지

## 주요 API 엔드포인트

서버는 다음과 같은 주요 API 엔드포인트를 제공합니다:

1. **CSI 예측**: `/main.py` (POST)
2. **출석 확인**: `/check` (POST)
3. **수업 세션 관리**: `/api/sessions/*`
4. **수업 관리**: `/api/classes/*`
5. **학생 관리**: `/api/classes/{class_id}/students/*`
6. **출석 통계**: `/api/classes/{class_id}/attendance/stats`
7. **학생 활동 분석**: `/api/students/{student_id}/activity`
8. **비활동 알림 설정**: `/api/classes/{class_id}/inactivity-settings`

전체 API 명세는 `API_DOCUMENTATION.md` 파일을 참조하세요.

## 코드 구조

- **app.js**: 메인 서버 코드
- **logs/**: 로그 파일 디렉토리
- **main.py**: 파이썬 예측 리스너 (현재는 더미 구현)

## 임시 데이터 저장소

현재 구현에서는 메모리 내 임시 저장소를 사용합니다:

```javascript
const db = {
  sessions: [], // 진행 중인 수업 세션
  users: [], // 사용자 정보
  attendances: [], // 출석 정보
  classes: [], // 수업 정보
  predictions: [], // 예측 결과 이력
};
```

실제 구현 시에는 Firebase Firestore 또는 다른 데이터베이스로 변경해야 합니다.

## 로깅 시스템

서버는 다음과 같은 로그 파일을 생성합니다:

- **access.log**: HTTP 요청 로그
- **predictions.log**: CSI 예측 결과 로그
- **attendance.log**: 출석 상태 변경 로그
- **sessions.log**: 수업 세션 시작/종료 로그
- **class_management.log**: 수업 및 학생 관리 로그

로그 파일은 `./logs` 디렉토리에 저장됩니다.

## CSI 예측 로직

현재 구현에서는 학생 ID의 마지막 숫자가 짝수인지 홀수인지에 따라 더미 예측 결과를 생성합니다:

```javascript
// 학생 ID 기반 더미 예측 결과 생성 (짝수면 sitdown, 홀수면 empty)
const studentSuffix = student_id.slice(-1);
const isActive = parseInt(studentSuffix) % 2 === 0;
const prediction = isActive ? "sitdown" : "empty";
```

실제 구현 시에는 머신러닝 모델을 통합하여 CSI 데이터를 분석해야 합니다.

## 권한 관리

API 엔드포인트는 교수 ID 또는 학생 ID를 통해 간단한 권한 검사를 수행합니다. 예를 들어:

```javascript
// 권한 확인
if (db.classes[classIndex].professor_id !== professor_id) {
  return res.status(403).json({
    success: false,
    error: "해당 수업의 설정을 변경할 권한이 없습니다",
    timestamp: req.requestTime,
  });
}
```

실제 구현 시에는 JWT 또는 Firebase Authentication을 통한 보다 안전한 인증 방식을 도입해야 합니다.

## 구현 시 고려사항

1. **데이터베이스 연동**: Firebase Firestore 또는 다른 데이터베이스 연동
2. **인증 보안 강화**: JWT 토큰 기반 인증 시스템 도입
3. **실시간 기능 구현**: Firebase Realtime Database 또는 WebSocket을 활용한 실시간 업데이트
4. **CSI 데이터 처리 최적화**: 실제 CSI 데이터 처리 및 분석 알고리즘 통합
5. **알림 시스템 구현**: Firebase Cloud Messaging을 활용한 학생/교수 알림 기능

## 서버 실행 방법

1. 필요한 패키지 설치: `npm install`
2. 서버 실행: `npm start` 또는 `node app.js`
3. 개발 모드 실행: `npm run dev`

## 테스트 방법

1. API 테스트: `npm test`
2. 개별 엔드포인트 테스트: `node test-api.js`

## 배포 방법

서버는 Google Cloud Run에 배포됩니다:

```bash
gcloud run deploy csi-server --source . --platform managed --region asia-northeast3 --allow-unauthenticated --project [프로젝트ID]
```

## 문제 해결

- **로그 확인**: 문제 발생 시 `./logs` 디렉토리의 로그 파일을 확인하세요.
- **메모리 제한**: 대용량 CSI 데이터 처리 시 메모리 사용량에 주의하세요.
- **비동기 처리**: 대부분의 API 호출은 비동기로 처리됩니다. 콜백 또는 프로미스 체인에 주의하세요.

## 추가 문의

추가 문의사항이 있으면 다음 연락처로 문의하세요:

- 이메일: [이메일 주소]
- 전화번호: [전화번호]
