// CSI 예측 API 엔드포인트 (/main.py)
// app.js 파일에 이 코드를 추가해 주세요
app.post("/main.py", (req, res) => {
  try {
    // 요청 데이터 추출
    const { session_id, student_id, csi_data, timestamp } = req.body;

    // 요청 로깅
    console.log(`CSI 예측 요청 수신 (/main.py):`);
    console.log(`   - 세션 ID: ${session_id}`);
    console.log(`   - 학생 ID: ${student_id}`);
    console.log(`   - 타임스탬프: ${timestamp || new Date().toISOString()}`);

    // 필수 파라미터 검증
    if (!session_id || !student_id) {
      console.warn("필수 파라미터 누락 (session_id 또는 student_id)");
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다 (session_id, student_id)",
        timestamp: new Date().toISOString(),
      });
    }

    // 학생 ID 기반 더미 예측 결과 생성 (짝수면 sitdown, 홀수면 empty)
    const studentSuffix = student_id.slice(-1);
    const isActive = parseInt(studentSuffix) % 2 === 0;
    const prediction = isActive ? "sitdown" : "empty";

    // 결과 로깅
    console.log(`CSI 예측 결과: ${prediction} (is_active: ${isActive})`);

    // 성공 응답 - 중요: 이 형식을 정확히 따라야 앱에서 올바르게 처리됩니다
    res.status(200).json({
      success: true,
      prediction: prediction,
      is_active: isActive,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    // 오류 로깅 및 응답
    console.error(`CSI 예측 처리 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: new Date().toISOString(),
    });
  }
});
