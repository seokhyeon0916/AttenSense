# CSI 기반 온라인 출결 시스템 API 문서

이 문서는 와이파이 CSI 기반 온라인 출결 시스템의 서버 API에 대한 설명입니다. 이 API는 Flutter 앱과 서버 간의 통신을 담당합니다.

## 기본 정보

- **기본 URL**: `https://csi-server-696186584116.asia-northeast3.run.app`
- **개발 URL**: `http://localhost:8080`
- **Content-Type**: `application/json`
- **인증 방식**: 요청 본문에 교수/학생 ID 포함 (보안 강화를 위해 JWT 인증 추가 권장)

## 응답 형식

모든 API 응답은 다음과 같은 기본 형식을 따릅니다:

### 성공 응답

```json
{
  "success": true,
  "message": "작업 성공 메시지",
  "timestamp": "2023-05-19T12:34:56.789Z"
  // 추가 데이터...
}
```

### 오류 응답

```json
{
  "success": false,
  "error": "오류 메시지",
  "timestamp": "2023-05-19T12:34:56.789Z"
}
```

## API 엔드포인트

### 1. 기본 API

#### 1.1 서버 상태 확인

**요청**

- **메서드**: `GET`
- **엔드포인트**: `/api/health`

**응답 예시**

```json
{
  "status": "online",
  "message": "CSI 예측 서버가 정상 작동 중입니다",
  "serverTime": "2023-05-19T12:34:56.789Z",
  "version": "1.0.0"
}
```

### 2. CSI 및 출석 API

#### 2.1 CSI 예측 요청

**요청**

- **메서드**: `POST`
- **엔드포인트**: `/main.py`

**요청 본문**

```json
{
  "session_id": "세션_ID",
  "student_id": "학생_ID",
  "csi_data": [1.0, 2.0, 3.0, ...], // 선택사항: CSI 데이터 배열
  "timestamp": "2023-05-19T12:34:56.789Z" // 선택사항
}
```

**응답 예시**

```json
{
  "success": true,
  "prediction": "sitdown", // 또는 "empty"
  "is_active": true, // 또는 false
  "timestamp": "2023-05-19T12:34:56.789Z"
}
```

#### 2.2 출석 확인 요청

**요청**

- **메서드**: `POST`
- **엔드포인트**: `/check`

**요청 본문**

```json
{
  "session_id": "세션_ID",
  "student_id": "학생_ID",
  "class_id": "수업_ID", // 선택사항
  "timestamp": "2023-05-19T12:34:56.789Z" // 선택사항
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "✅ 출석 요청이 성공적으로 처리되었습니다",
  "attendance": {
    "session_id": "세션_ID",
    "student_id": "학생_ID",
    "class_id": "수업_ID",
    "status": "present",
    "timestamp": "2023-05-19T12:34:56.789Z"
  },
  "receivedAt": "2023-05-19T12:34:56.789Z"
}
```

### 3. 수업 세션 관리 API

#### 3.1 수업 세션 시작

**요청**

- **메서드**: `POST`
- **엔드포인트**: `/api/sessions/start`

**요청 본문**

```json
{
  "class_id": "수업_ID",
  "professor_id": "교수_ID",
  "session_name": "5월 19일 수업", // 선택사항
  "duration_minutes": 90 // 선택사항, 기본값 90분
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "수업 세션이 성공적으로 시작되었습니다",
  "session": {
    "session_id": "CLS_12345_1621417496789",
    "class_id": "수업_ID",
    "professor_id": "교수_ID",
    "session_name": "5월 19일 수업",
    "start_time": "2023-05-19T12:34:56.789Z",
    "end_time": null,
    "status": "active",
    "duration_minutes": 90,
    "students": []
  }
}
```

#### 3.2 수업 세션 종료

**요청**

- **메서드**: `POST`
- **엔드포인트**: `/api/sessions/{session_id}/end`

**요청 본문**

```json
{
  "professor_id": "교수_ID"
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "수업 세션이 성공적으로 종료되었습니다",
  "session": {
    "session_id": "CLS_12345_1621417496789",
    "class_id": "수업_ID",
    "professor_id": "교수_ID",
    "session_name": "5월 19일 수업",
    "start_time": "2023-05-19T12:34:56.789Z",
    "end_time": "2023-05-19T14:04:56.789Z",
    "status": "completed",
    "duration_minutes": 90,
    "students": []
  }
}
```

#### 3.3 세션 상태 조회

**요청**

- **메서드**: `GET`
- **엔드포인트**: `/api/sessions/{session_id}`

**응답 예시**

```json
{
  "success": true,
  "session": {
    "session_id": "CLS_12345_1621417496789",
    "class_id": "수업_ID",
    "professor_id": "교수_ID",
    "session_name": "5월 19일 수업",
    "start_time": "2023-05-19T12:34:56.789Z",
    "end_time": null,
    "status": "active",
    "duration_minutes": 90,
    "students": []
  },
  "attendances": [
    {
      "session_id": "CLS_12345_1621417496789",
      "student_id": "학생_ID_1",
      "class_id": "수업_ID",
      "status": "present",
      "timestamp": "2023-05-19T12:40:12.345Z"
    }
    // 추가 출석 기록...
  ],
  "timestamp": "2023-05-19T12:45:00.000Z"
}
```

### 4. 수업 관리 API

#### 4.1 수업 목록 조회

**요청**

- **메서드**: `GET`
- **엔드포인트**: `/api/classes`
- **쿼리 파라미터**: `professor_id` (선택사항, 교수 ID로 필터링)

**응답 예시**

```json
{
  "success": true,
  "classes": [
    {
      "class_id": "CLS_12345",
      "class_name": "컴퓨터 네트워크",
      "professor_id": "교수_ID",
      "schedule": "월,수 10:30-12:00",
      "room": "공학관 401호",
      "description": "컴퓨터 네트워크 기초 과목",
      "start_date": "2023-03-01T00:00:00.000Z",
      "end_date": "2023-06-30T00:00:00.000Z",
      "created_at": "2023-02-15T09:00:00.000Z",
      "students": ["학생_ID_1", "학생_ID_2", "학생_ID_3"]
    }
    // 추가 수업...
  ],
  "count": 1,
  "timestamp": "2023-05-19T12:34:56.789Z"
}
```

#### 4.2 수업 생성

**요청**

- **메서드**: `POST`
- **엔드포인트**: `/api/classes`

**요청 본문**

```json
{
  "class_name": "컴퓨터 네트워크",
  "professor_id": "교수_ID",
  "schedule": "월,수 10:30-12:00",
  "room": "공학관 401호", // 선택사항
  "description": "컴퓨터 네트워크 기초 과목", // 선택사항
  "start_date": "2023-03-01T00:00:00.000Z", // 선택사항
  "end_date": "2023-06-30T00:00:00.000Z" // 선택사항
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "수업이 성공적으로 생성되었습니다",
  "class": {
    "class_id": "CLS_12345",
    "class_name": "컴퓨터 네트워크",
    "professor_id": "교수_ID",
    "schedule": "월,수 10:30-12:00",
    "room": "공학관 401호",
    "description": "컴퓨터 네트워크 기초 과목",
    "start_date": "2023-03-01T00:00:00.000Z",
    "end_date": "2023-06-30T00:00:00.000Z",
    "created_at": "2023-05-19T12:34:56.789Z",
    "students": []
  }
}
```

#### 4.3 수업 상세 조회

**요청**

- **메서드**: `GET`
- **엔드포인트**: `/api/classes/{class_id}`

**응답 예시**

```json
{
  "success": true,
  "class": {
    "class_id": "CLS_12345",
    "class_name": "컴퓨터 네트워크",
    "professor_id": "교수_ID",
    "schedule": "월,수 10:30-12:00",
    "room": "공학관 401호",
    "description": "컴퓨터 네트워크 기초 과목",
    "start_date": "2023-03-01T00:00:00.000Z",
    "end_date": "2023-06-30T00:00:00.000Z",
    "created_at": "2023-02-15T09:00:00.000Z",
    "students": ["학생_ID_1", "학생_ID_2", "학생_ID_3"]
  },
  "timestamp": "2023-05-19T12:34:56.789Z"
}
```

#### 4.4 수업 수정

**요청**

- **메서드**: `PUT`
- **엔드포인트**: `/api/classes/{class_id}`

**요청 본문**

```json
{
  "professor_id": "교수_ID", // 권한 확인용
  "class_name": "컴퓨터 네트워크 고급",
  "schedule": "월,수 13:30-15:00",
  "room": "공학관 402호",
  "description": "컴퓨터 네트워크 고급 과정"
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "수업 정보가 성공적으로 수정되었습니다",
  "class": {
    "class_id": "CLS_12345",
    "class_name": "컴퓨터 네트워크 고급",
    "professor_id": "교수_ID",
    "schedule": "월,수 13:30-15:00",
    "room": "공학관 402호",
    "description": "컴퓨터 네트워크 고급 과정",
    "start_date": "2023-03-01T00:00:00.000Z",
    "end_date": "2023-06-30T00:00:00.000Z",
    "created_at": "2023-02-15T09:00:00.000Z",
    "updated_at": "2023-05-19T12:34:56.789Z",
    "students": ["학생_ID_1", "학생_ID_2", "학생_ID_3"]
  }
}
```

### 5. 학생 관리 API

#### 5.1 수업에 학생 추가

**요청**

- **메서드**: `POST`
- **엔드포인트**: `/api/classes/{class_id}/students`

**요청 본문**

```json
{
  "professor_id": "교수_ID", // 권한 확인용
  "student_ids": ["학생_ID_4", "학생_ID_5"]
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "2명의 학생이 성공적으로 추가되었습니다",
  "added_students": ["학생_ID_4", "학생_ID_5"],
  "total_students": 5
}
```

#### 5.2 수업에서 학생 제거

**요청**

- **메서드**: `DELETE`
- **엔드포인트**: `/api/classes/{class_id}/students/{student_id}`

**요청 본문**

```json
{
  "professor_id": "교수_ID" // 권한 확인용
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "학생이 성공적으로 제거되었습니다",
  "removed_student": "학생_ID_3",
  "total_students": 4
}
```

### 6. 출석 관리 API

#### 6.1 출석 상태 수동 변경

**요청**

- **메서드**: `POST`
- **엔드포인트**: `/api/sessions/{session_id}/attendance`

**요청 본문**

```json
{
  "professor_id": "교수_ID", // 권한 확인용
  "student_id": "학생_ID",
  "status": "present", // "present", "late", "absent", "excused" 중 하나
  "reason": "지각 사유" // 선택사항
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "출석 상태가 성공적으로 변경되었습니다",
  "attendance": {
    "session_id": "세션_ID",
    "student_id": "학생_ID",
    "class_id": "수업_ID",
    "status": "late",
    "reason": "교통 지연",
    "updated_by": "교수_ID",
    "timestamp": "2023-05-19T12:34:56.789Z"
  }
}
```

#### 6.2 출석 통계 조회

**요청**

- **메서드**: `GET`
- **엔드포인트**: `/api/classes/{class_id}/attendance/stats`
- **쿼리 파라미터**:
  - `start_date`: 시작 날짜 (YYYY-MM-DD 형식, 선택사항)
  - `end_date`: 종료 날짜 (YYYY-MM-DD 형식, 선택사항)

**응답 예시**

```json
{
  "success": true,
  "stats": {
    "total_sessions": 10,
    "total_students": 3,
    "total_attendance_rate": 85.3,
    "student_stats": {
      "학생_ID_1": {
        "status_counts": {
          "present": 8,
          "late": 1,
          "absent": 1,
          "excused": 0
        },
        "attendance_rate": 90.0,
        "total_sessions": 10,
        "attended_sessions": 9
      },
      "학생_ID_2": {
        "status_counts": {
          "present": 7,
          "late": 2,
          "absent": 0,
          "excused": 1
        },
        "attendance_rate": 100.0,
        "total_sessions": 10,
        "attended_sessions": 10
      },
      "학생_ID_3": {
        "status_counts": {
          "present": 5,
          "late": 1,
          "absent": 3,
          "excused": 1
        },
        "attendance_rate": 70.0,
        "total_sessions": 10,
        "attended_sessions": 7
      }
    }
  },
  "timestamp": "2023-05-19T12:34:56.789Z"
}
```

### 7. 학생 활동 분석 API

#### 7.1 학생별 CSI 데이터 활동 분석

**요청**

- **메서드**: `GET`
- **엔드포인트**: `/api/students/{student_id}/activity`
- **쿼리 파라미터**:
  - `session_id`: 세션 ID로 필터링 (선택사항)
  - `limit`: 결과 개수 제한 (선택사항)

**응답 예시**

```json
{
  "success": true,
  "student_id": "학생_ID",
  "activity_stats": {
    "total_predictions": 100,
    "active_count": 75,
    "inactive_count": 25,
    "active_percentage": 75
  },
  "recent_activity": [
    {
      "session_id": "세션_ID",
      "student_id": "학생_ID",
      "prediction": "sitdown",
      "is_active": true,
      "timestamp": "2023-05-19T12:30:00.000Z",
      "csi_data_received": true
    }
    // 추가 활동 기록...
  ],
  "timestamp": "2023-05-19T12:34:56.789Z"
}
```

#### 7.2 비활동 알림 설정

**요청**

- **메서드**: `POST`
- **엔드포인트**: `/api/classes/{class_id}/inactivity-settings`

**요청 본문**

```json
{
  "professor_id": "교수_ID", // 권한 확인용
  "threshold_minutes": 5, // 비활동 감지 임계값 (분)
  "enabled": true // 활성화 여부
}
```

**응답 예시**

```json
{
  "success": true,
  "message": "비활동 알림 설정이 성공적으로 업데이트되었습니다",
  "settings": {
    "threshold_minutes": 5,
    "enabled": true,
    "updated_at": "2023-05-19T12:34:56.789Z",
    "updated_by": "교수_ID"
  }
}
```

## 오류 코드

| HTTP 상태 코드 | 설명                                |
| -------------- | ----------------------------------- |
| 400            | 잘못된 요청 (필수 파라미터 누락 등) |
| 401            | 인증 실패                           |
| 403            | 권한 부족                           |
| 404            | 리소스를 찾을 수 없음               |
| 500            | 서버 내부 오류                      |

## 구현 참고사항

1. 현재 API는 메모리 내 임시 저장소를 사용하고 있으므로, 실제 구현 시 Firebase 또는 다른 데이터베이스로 변경해야 합니다.
2. 인증 보안을 강화하기 위해 JWT와 같은 토큰 기반 인증 시스템 도입을 권장합니다.
3. CSI 데이터 처리는 현재 더미 로직으로 구현되어 있으며, 실제 구현 시 머신러닝 모델을 통합해야 합니다.
4. 실시간 알림을 위해 Firebase Cloud Messaging 또는 WebSocket을 추가하는 것이 좋습니다.
