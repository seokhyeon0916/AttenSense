# CSI 기반 온라인 출결 시스템 - 서버 API 가이드

## 서버 접속 정보

- **서버 URL**: `https://csi-server-696186584116.asia-northeast3.run.app`
- **로컬 개발 서버**: `http://localhost:8080`
- **개발 테스트 서버**: `http://10.50.236.226:8080`

## API 엔드포인트

### 1. CSI 예측 요청 (`/main.py`)

학생의 자리 착석 여부를 예측합니다.

#### 요청 방법

- **HTTP 메서드**: `POST`
- **Content-Type**: `application/json`

#### 요청 파라미터

```json
{
  "session_id": "수업_세션_ID",
  "student_id": "학생_ID",
  "csi_data": [1.0, 2.0, 3.0, ...], // 선택사항: CSI 데이터 배열
  "timestamp": "2023-05-19T12:34:56.789Z" // 선택사항: ISO 형식 타임스탬프
}
```

#### 응답 형식

```json
{
  "success": true,
  "prediction": "sitdown", // 또는 "empty"
  "is_active": true, // 또는 false
  "timestamp": "2023-05-19T12:34:56.789Z"
}
```

#### 오류 응답

```json
{
  "success": false,
  "error": "오류 메시지",
  "timestamp": "2023-05-19T12:34:56.789Z"
}
```

#### Flutter에서 사용 예시

```dart
Future<Map<String, dynamic>?> requestCSIPrediction({
  required String sessionId,
  required String studentId,
}) async {
  try {
    final url = '$_serverUrl/main.py';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'student_id': studentId,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('오류 응답: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    print('요청 실패: $e');
    return null;
  }
}
```

### 2. 출석 확인 요청 (`/check`)

학생의 출석을 확인합니다.

#### 요청 방법

- **HTTP 메서드**: `POST`
- **Content-Type**: `application/json`

#### 요청 파라미터

```json
{
  "session_id": "수업_세션_ID",
  "student_id": "학생_ID",
  "class_id": "수업_ID",
  "timestamp": "2023-05-19T12:34:56.789Z" // 선택사항
}
```

#### 응답 형식

```json
{
  "success": true,
  "message": "출석 요청 수신됨",
  "receivedAt": "2023-05-19T12:34:56.789Z"
}
```

### 3. 서버 상태 확인 (`/api/health`)

서버의 작동 상태를 확인합니다.

#### 요청 방법

- **HTTP 메서드**: `GET`

#### 응답 형식

```json
{
  "status": "online",
  "message": "CSI 예측 서버가 정상 작동 중입니다",
  "serverTime": "2023-05-19T12:34:56.789Z",
  "version": "1.0.0"
}
```

## 예측 결과 해석

- `prediction`: "sitdown" - 학생이 자리에 앉아 있음
- `prediction`: "empty" - 학생이 자리에 없음
- `is_active`: true - 학생이 활동 중 (자리에 앉아 있음)
- `is_active`: false - 학생이 비활동 중 (자리에 없음)

## Flutter 앱 설정 가이드

1. Flutter 앱의 `lib/services/api_service.dart` 파일에서 서버 URL을 설정합니다:

```dart
static String _baseUrl = kDebugMode
    ? 'http://10.50.236.226:8080' // 개발 환경
    : 'https://csi-server-696186584116.asia-northeast3.run.app'; // 프로덕션 환경
```

2. 다음 권한이 `AndroidManifest.xml`에 추가되어 있는지 확인합니다:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

3. iOS의 경우 `Info.plist`에 다음 설정이 있는지 확인합니다:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 에러 처리 권장사항

1. 네트워크 연결 오류에 대비한 타임아웃 설정 (5-10초 권장)
2. 서버 응답 실패 시 로컬 더미 데이터 사용 기능 구현
3. 오류 상황에 대한 사용자 피드백 제공
4. 주기적인 서버 상태 확인 기능 구현

## 테스트 방법

1. 서버 루트 경로(`/`)에 접속하여 서버가 실행 중인지 확인
2. 제공된 `test-api.js` 스크립트를 사용하여 API 엔드포인트 테스트:
   ```
   node test-api.js
   ```

## 문제 해결

**Q: 서버 연결이 안 됩니다.**  
A: 네트워크 연결 확인, 서버 URL 확인, 방화벽 설정 확인

**Q: 예측 결과가 항상 같습니다.**  
A: 현재 서버는 학생 ID 끝자리가 짝수면 "sitdown", 홀수면 "empty"를 반환하는 더미 로직을 사용합니다.

**Q: 서버 응답이 너무 느립니다.**  
A: 서버 부하 확인, 네트워크 상태 확인, 타임아웃 설정 조정

## 연락처

문제가 발생하거나 추가 정보가 필요한 경우 아래 연락처로 문의하세요:

- 서버 관리자: [이메일 또는 연락처]
- 프로젝트 관리자: [이메일 또는 연락처]
