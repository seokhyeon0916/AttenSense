const fetch = require("node-fetch");

// 서버 URL (필요시 변경)
const SERVER_URL = "http://localhost:8080";

// 테스트할 학생 ID
const TEST_STUDENT_IDS = ["1234", "5678", "9012", "3456"];

/**
 * CSI 예측 요청 테스트
 */
async function testCSIPrediction() {
  console.log("\n🔵 CSI 예측 요청 테스트 (/main.py) 시작...");

  for (const studentId of TEST_STUDENT_IDS) {
    try {
      console.log(`\n학생 ID ${studentId}에 대한 예측 요청 전송 중...`);

      const response = await fetch(`${SERVER_URL}/main.py`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          session_id: "test_session",
          student_id: studentId,
          timestamp: new Date().toISOString(),
        }),
      });

      const data = await response.json();

      console.log(`🟢 응답 상태: ${response.status}`);
      console.log(`🟢 응답 데이터:`, data);

      // 예측 결과 표시
      if (data.success) {
        console.log(
          `✅ 예측 결과: ${data.prediction} (활성 상태: ${data.is_active})`
        );
      } else {
        console.log(`❌ 오류 발생: ${data.error}`);
      }
    } catch (error) {
      console.error(`💥 요청 실패: ${error.message}`);
    }
  }
}

/**
 * 출석 확인 요청 테스트
 */
async function testAttendanceCheck() {
  console.log("\n🔵 출석 확인 요청 테스트 (/check) 시작...");

  try {
    console.log("\n출석 확인 요청 전송 중...");

    const response = await fetch(`${SERVER_URL}/check`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        session_id: "test_session",
        student_id: "1234",
        class_id: "test_class",
        timestamp: new Date().toISOString(),
      }),
    });

    const data = await response.json();

    console.log(`🟢 응답 상태: ${response.status}`);
    console.log(`🟢 응답 데이터:`, data);
  } catch (error) {
    console.error(`💥 요청 실패: ${error.message}`);
  }
}

/**
 * 서버 상태 확인 테스트
 */
async function testServerHealth() {
  console.log("\n🔵 서버 상태 확인 테스트 (/api/health) 시작...");

  try {
    console.log("\n서버 상태 확인 요청 전송 중...");

    const response = await fetch(`${SERVER_URL}/api/health`);
    const data = await response.json();

    console.log(`🟢 응답 상태: ${response.status}`);
    console.log(`🟢 응답 데이터:`, data);
  } catch (error) {
    console.error(`💥 요청 실패: ${error.message}`);
  }
}

/**
 * 모든 테스트 실행
 */
async function runAllTests() {
  console.log("🚀 CSI 서버 API 테스트 시작...");
  console.log(`🔗 서버 URL: ${SERVER_URL}`);

  try {
    // 서버 상태 확인
    await testServerHealth();

    // CSI 예측 요청 테스트
    await testCSIPrediction();

    // 출석 확인 요청 테스트
    await testAttendanceCheck();

    console.log("\n✅ 모든 테스트 완료!");
  } catch (error) {
    console.error(`\n💥 테스트 실행 중 오류 발생: ${error.message}`);
  }
}

// 테스트 실행
runAllTests();
