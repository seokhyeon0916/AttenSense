console.log(`수업 종료 요청: 클래스 ID ${classId}, 세션 ID ${sessionId}`);

// 1. Firebase에 세션 종료 상태 업데이트 (선택적)
try {
  if (admin.apps.length) {
    // 'sessions' 컬렉션 대신 'session_logs' 컬렉션 사용 (수업 시작에서 사용된 것과 동일하게)
    const sessionRef = admin
      .firestore()
      .collection("session_logs")
      .doc(sessionId);

    // 세션 문서가 존재하는지 먼저 확인
    const sessionDoc = await sessionRef.get();
    if (sessionDoc.exists) {
      await sessionRef.update({
        isActive: false,
        endTime: admin.firestore.Timestamp.fromDate(
          new Date(timestamp || Date.now())
        ),
        server_timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Firebase에 세션 종료 상태 업데이트 완료: ${sessionId}`);
    } else {
      console.log(
        `세션 ID ${sessionId}에 해당하는 문서가 존재하지 않습니다. 업데이트를 건너뜁니다.`
      );
    }
  }
} catch (fbError) {
  console.error("Firebase 세션 종료 상태 업데이트 오류:", fbError);
  // Firebase 오류는 무시하고 계속 진행
}
