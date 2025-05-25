const express = require("express");
const cors = require("cors");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");
const helmet = require("helmet");
const morgan = require("morgan");
const app = express();

// 로그 디렉토리 생성
const logDir = path.join(__dirname, "logs");
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir);
}

// 로그 스트림 생성
const accessLogStream = fs.createWriteStream(path.join(logDir, "access.log"), {
  flags: "a",
});

// 보안 설정
app.use(helmet());

// CORS 설정
app.use(
  cors({
    origin: "*", // 모든 오리진 허용 (실제 배포에서는 특정 도메인만 허용하도록 변경 필요)
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// 요청 로깅
app.use(morgan("combined", { stream: accessLogStream }));
app.use(morgan("dev")); // 개발 콘솔용 로깅

// JSON 파싱 미들웨어
app.use(express.json({ limit: "10mb" })); // CSI 데이터가 클 수 있으므로 제한 확장

// 요청 시간 기록 미들웨어
app.use((req, res, next) => {
  req.requestTime = new Date().toISOString();
  next();
});

// ✅ 서버 시작 시 파이썬 예측 리스너 실행
exec("python main.py", (error, stdout, stderr) => {
  if (error) {
    console.error(`❌ 파이썬 실행 오류: ${error.message}`);
    return;
  }
  if (stderr) {
    console.warn(`⚠️ 파이썬 stderr: ${stderr}`);
  }
  console.log(`🎉 파이썬 예측 코드 시작됨:\n${stdout}`);
});

// 임시 저장소 (실제 구현에서는 Firebase 등의 데이터베이스 사용 필요)
const db = {
  sessions: [], // 진행 중인 수업 세션
  users: [], // 사용자 정보
  attendances: [], // 출석 정보
  classes: [], // 수업 정보
  predictions: [], // 예측 결과 이력
};

// ===== API 엔드포인트 정의 =====

// ✅ 서버 상태 확인 API
app.get("/api/health", (req, res) => {
  res.status(200).json({
    status: "online",
    message: "CSI 예측 서버가 정상 작동 중입니다",
    serverTime: req.requestTime,
    version: "1.0.0",
  });
});

// ✅ 출석 확인 요청 API
app.post("/check", (req, res) => {
  try {
    const { session_id, student_id, class_id, timestamp } = req.body;

    console.log("🟢 출석 확인 요청 수신됨");
    console.log(`   - 요청 데이터:`, req.body);

    // 필수 파라미터 검증
    if (!session_id || !student_id) {
      console.warn("⚠️ 필수 파라미터 누락 (session_id 또는 student_id)");
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다 (session_id, student_id)",
        timestamp: req.requestTime,
      });
    }

    // 출석 기록 저장 (실제 구현에서는 데이터베이스에 저장)
    const attendanceRecord = {
      session_id,
      student_id,
      class_id: class_id || "unknown",
      timestamp: timestamp || req.requestTime,
      status: "present", // 기본값은 출석
    };

    db.attendances.push(attendanceRecord);

    // 로그에 기록
    fs.appendFile(
      path.join(logDir, "attendance.log"),
      `${req.requestTime} - 세션: ${session_id}, 학생: ${student_id}, 상태: present\n`,
      (err) => {
        if (err) console.error("로그 기록 실패:", err);
      }
    );

    res.status(200).json({
      success: true,
      message: "✅ 출석 요청이 성공적으로 처리되었습니다",
      attendance: attendanceRecord,
      receivedAt: req.requestTime,
    });
  } catch (error) {
    console.error(`❌ 출석 확인 처리 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// ✅ CSI 예측 API 엔드포인트 (/main.py)
app.post("/main.py", (req, res) => {
  try {
    const { session_id, student_id, csi_data, timestamp } = req.body;

    console.log(`🔵 CSI 예측 요청 수신 (/main.py):`);
    console.log(`   - 세션 ID: ${session_id}`);
    console.log(`   - 학생 ID: ${student_id}`);
    console.log(`   - 타임스탬프: ${timestamp || req.requestTime}`);

    // 필수 파라미터 확인
    if (!session_id || !student_id) {
      console.warn(`⚠️ 필수 파라미터 누락 (session_id 또는 student_id)`);
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다 (session_id, student_id)",
        timestamp: req.requestTime,
      });
    }

    // 학생 ID 기반 더미 예측 결과 생성 (짝수면 sitdown, 홀수면 empty)
    const studentSuffix = student_id.slice(-1);
    const isActive = parseInt(studentSuffix) % 2 === 0;
    const prediction = isActive ? "sitdown" : "empty";

    console.log(`🟢 CSI 예측 결과: ${prediction} (is_active: ${isActive})`);

    // 로그에 예측 결과 기록
    fs.appendFile(
      path.join(logDir, "predictions.log"),
      `${req.requestTime} - 세션: ${session_id}, 학생: ${student_id}, 예측: ${prediction}\n`,
      (err) => {
        if (err) console.error("로그 기록 실패:", err);
      }
    );

    // 예측 결과 저장 (실제 구현에서는 데이터베이스에 저장)
    const predictionRecord = {
      session_id,
      student_id,
      prediction,
      is_active: isActive,
      timestamp: req.requestTime,
      csi_data_received: !!csi_data,
    };

    db.predictions.push(predictionRecord);

    res.status(200).json({
      success: true,
      prediction: prediction,
      is_active: isActive,
      timestamp: req.requestTime,
    });
  } catch (error) {
    console.error(`❌ CSI 예측 처리 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// ✅ 수업 세션 관리 API (교수용)
// 수업 세션 시작
app.post("/api/sessions/start", (req, res) => {
  try {
    const { class_id, professor_id, session_name, duration_minutes } = req.body;

    console.log("🔵 수업 세션 시작 요청 수신:");
    console.log(`   - 수업 ID: ${class_id}`);
    console.log(`   - 교수 ID: ${professor_id}`);

    // 필수 파라미터 검증
    if (!class_id || !professor_id) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다 (class_id, professor_id)",
        timestamp: req.requestTime,
      });
    }

    // 세션 ID 생성 (실제 구현에서는 더 고유한 방식 사용)
    const session_id = `${class_id}_${Date.now()}`;

    // 세션 정보 저장
    const sessionInfo = {
      session_id,
      class_id,
      professor_id,
      session_name:
        session_name || `수업 세션 ${new Date().toLocaleDateString()}`,
      start_time: req.requestTime,
      end_time: null,
      status: "active",
      duration_minutes: duration_minutes || 90,
      students: [],
    };

    db.sessions.push(sessionInfo);

    // 로그에 기록
    fs.appendFile(
      path.join(logDir, "sessions.log"),
      `${req.requestTime} - 세션 시작: ${session_id}, 수업: ${class_id}, 교수: ${professor_id}\n`,
      (err) => {
        if (err) console.error("로그 기록 실패:", err);
      }
    );

    res.status(201).json({
      success: true,
      message: "수업 세션이 성공적으로 시작되었습니다",
      session: sessionInfo,
    });
  } catch (error) {
    console.error(`❌ 세션 시작 처리 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// 수업 세션 종료
app.post("/api/sessions/:session_id/end", (req, res) => {
  try {
    const { session_id } = req.params;
    const { professor_id } = req.body;

    console.log(`🔵 수업 세션 종료 요청: ${session_id}`);

    // 필수 파라미터 검증
    if (!professor_id) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다 (professor_id)",
        timestamp: req.requestTime,
      });
    }

    // 세션 찾기 (실제 구현에서는 데이터베이스 쿼리)
    const sessionIndex = db.sessions.findIndex(
      (s) => s.session_id === session_id
    );

    if (sessionIndex === -1) {
      return res.status(404).json({
        success: false,
        error: "요청한 세션을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 권한 확인
    if (db.sessions[sessionIndex].professor_id !== professor_id) {
      return res.status(403).json({
        success: false,
        error: "해당 세션을 종료할 권한이 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 세션 종료 처리
    db.sessions[sessionIndex].end_time = req.requestTime;
    db.sessions[sessionIndex].status = "completed";

    // 로그에 기록
    fs.appendFile(
      path.join(logDir, "sessions.log"),
      `${req.requestTime} - 세션 종료: ${session_id}, 교수: ${professor_id}\n`,
      (err) => {
        if (err) console.error("로그 기록 실패:", err);
      }
    );

    res.status(200).json({
      success: true,
      message: "수업 세션이 성공적으로 종료되었습니다",
      session: db.sessions[sessionIndex],
    });
  } catch (error) {
    console.error(`❌ 세션 종료 처리 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// 세션 상태 조회
app.get("/api/sessions/:session_id", (req, res) => {
  try {
    const { session_id } = req.params;

    // 세션 찾기
    const session = db.sessions.find((s) => s.session_id === session_id);

    if (!session) {
      return res.status(404).json({
        success: false,
        error: "요청한 세션을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 출석 정보 취합 (실제 구현에서는 데이터베이스 쿼리)
    const attendances = db.attendances.filter(
      (a) => a.session_id === session_id
    );

    res.status(200).json({
      success: true,
      session,
      attendances,
      timestamp: req.requestTime,
    });
  } catch (error) {
    console.error(`❌ 세션 조회 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// ✅ 수업 관리 API
// 수업 목록 조회
app.get("/api/classes", (req, res) => {
  try {
    const { professor_id } = req.query;

    let classes = db.classes;

    // 교수 ID로 필터링 (있는 경우)
    if (professor_id) {
      classes = classes.filter((c) => c.professor_id === professor_id);
    }

    res.status(200).json({
      success: true,
      classes,
      count: classes.length,
      timestamp: req.requestTime,
    });
  } catch (error) {
    console.error(`❌ 수업 목록 조회 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// 수업 생성
app.post("/api/classes", (req, res) => {
  try {
    const {
      class_name,
      professor_id,
      schedule,
      room,
      description,
      start_date,
      end_date,
    } = req.body;

    // 필수 파라미터 검증
    if (!class_name || !professor_id || !schedule) {
      return res.status(400).json({
        success: false,
        error:
          "필수 정보가 누락되었습니다 (class_name, professor_id, schedule)",
        timestamp: req.requestTime,
      });
    }

    // 수업 ID 생성
    const class_id = `CLS_${Date.now()}`;

    // 수업 정보 저장
    const classInfo = {
      class_id,
      class_name,
      professor_id,
      schedule,
      room: room || "미정",
      description: description || "",
      start_date: start_date || req.requestTime,
      end_date: end_date || null,
      created_at: req.requestTime,
      students: [],
    };

    db.classes.push(classInfo);

    res.status(201).json({
      success: true,
      message: "수업이 성공적으로 생성되었습니다",
      class: classInfo,
    });
  } catch (error) {
    console.error(`❌ 수업 생성 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// 수업 상세 조회
app.get("/api/classes/:class_id", (req, res) => {
  try {
    const { class_id } = req.params;

    // 수업 찾기
    const classInfo = db.classes.find((c) => c.class_id === class_id);

    if (!classInfo) {
      return res.status(404).json({
        success: false,
        error: "요청한 수업을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    res.status(200).json({
      success: true,
      class: classInfo,
      timestamp: req.requestTime,
    });
  } catch (error) {
    console.error(`❌ 수업 조회 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// 수업 수정
app.put("/api/classes/:class_id", (req, res) => {
  try {
    const { class_id } = req.params;
    const { professor_id, class_name, schedule, room, description } = req.body;

    // 수업 찾기
    const classIndex = db.classes.findIndex((c) => c.class_id === class_id);

    if (classIndex === -1) {
      return res.status(404).json({
        success: false,
        error: "요청한 수업을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 권한 확인
    if (professor_id && db.classes[classIndex].professor_id !== professor_id) {
      return res.status(403).json({
        success: false,
        error: "해당 수업을 수정할 권한이 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 수업 정보 업데이트
    if (class_name) db.classes[classIndex].class_name = class_name;
    if (schedule) db.classes[classIndex].schedule = schedule;
    if (room) db.classes[classIndex].room = room;
    if (description) db.classes[classIndex].description = description;

    // 수정 시간 기록
    db.classes[classIndex].updated_at = req.requestTime;

    res.status(200).json({
      success: true,
      message: "수업 정보가 성공적으로 수정되었습니다",
      class: db.classes[classIndex],
    });
  } catch (error) {
    console.error(`❌ 수업 수정 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// ✅ 학생 관리 API
// 수업에 학생 추가
app.post("/api/classes/:class_id/students", (req, res) => {
  try {
    const { class_id } = req.params;
    const { student_ids, professor_id } = req.body;

    // 필수 파라미터 검증
    if (!student_ids || !Array.isArray(student_ids) || !professor_id) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다 (student_ids 배열, professor_id)",
        timestamp: req.requestTime,
      });
    }

    // 수업 찾기
    const classIndex = db.classes.findIndex((c) => c.class_id === class_id);

    if (classIndex === -1) {
      return res.status(404).json({
        success: false,
        error: "요청한 수업을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 권한 확인
    if (db.classes[classIndex].professor_id !== professor_id) {
      return res.status(403).json({
        success: false,
        error: "해당 수업에 학생을 추가할 권한이 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 이미 등록된 학생 필터링
    const existingStudents = new Set(db.classes[classIndex].students);
    const newStudents = student_ids.filter((id) => !existingStudents.has(id));

    // 학생 추가
    db.classes[classIndex].students.push(...newStudents);

    // 로그 기록
    fs.appendFile(
      path.join(logDir, "class_management.log"),
      `${req.requestTime} - 수업 ${class_id}에 학생 추가: ${newStudents.join(
        ", "
      )}\n`,
      (err) => {
        if (err) console.error("로그 기록 실패:", err);
      }
    );

    res.status(200).json({
      success: true,
      message: `${newStudents.length}명의 학생이 성공적으로 추가되었습니다`,
      added_students: newStudents,
      total_students: db.classes[classIndex].students.length,
    });
  } catch (error) {
    console.error(`❌ 학생 추가 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// 수업에서 학생 제거
app.delete("/api/classes/:class_id/students/:student_id", (req, res) => {
  try {
    const { class_id, student_id } = req.params;
    const { professor_id } = req.body;

    // 필수 파라미터 검증
    if (!professor_id) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다 (professor_id)",
        timestamp: req.requestTime,
      });
    }

    // 수업 찾기
    const classIndex = db.classes.findIndex((c) => c.class_id === class_id);

    if (classIndex === -1) {
      return res.status(404).json({
        success: false,
        error: "요청한 수업을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 권한 확인
    if (db.classes[classIndex].professor_id !== professor_id) {
      return res.status(403).json({
        success: false,
        error: "해당 수업에서 학생을 제거할 권한이 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 학생이 수업에 등록되어 있는지 확인
    const studentIndex = db.classes[classIndex].students.indexOf(student_id);

    if (studentIndex === -1) {
      return res.status(404).json({
        success: false,
        error: "해당 학생은 수업에 등록되어 있지 않습니다",
        timestamp: req.requestTime,
      });
    }

    // 학생 제거
    db.classes[classIndex].students.splice(studentIndex, 1);

    // 로그 기록
    fs.appendFile(
      path.join(logDir, "class_management.log"),
      `${req.requestTime} - 수업 ${class_id}에서 학생 제거: ${student_id}\n`,
      (err) => {
        if (err) console.error("로그 기록 실패:", err);
      }
    );

    res.status(200).json({
      success: true,
      message: "학생이 성공적으로 제거되었습니다",
      removed_student: student_id,
      total_students: db.classes[classIndex].students.length,
    });
  } catch (error) {
    console.error(`❌ 학생 제거 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// ✅ 출석 관리 API
// 출석 상태 수동 변경 (교수용)
app.post("/api/sessions/:session_id/attendance", (req, res) => {
  try {
    const { session_id } = req.params;
    const { student_id, status, professor_id, reason } = req.body;

    // 필수 파라미터 검증
    if (!student_id || !status || !professor_id) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다 (student_id, status, professor_id)",
        timestamp: req.requestTime,
      });
    }

    // 세션 찾기
    const session = db.sessions.find((s) => s.session_id === session_id);

    if (!session) {
      return res.status(404).json({
        success: false,
        error: "요청한 세션을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 권한 확인
    if (session.professor_id !== professor_id) {
      return res.status(403).json({
        success: false,
        error: "해당 세션의 출석 상태를 변경할 권한이 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 유효한 상태값 확인 (출석, 지각, 결석, 공결)
    const validStatuses = ["present", "late", "absent", "excused"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: "유효하지 않은 출석 상태입니다",
        valid_statuses: validStatuses,
        timestamp: req.requestTime,
      });
    }

    // 기존 출석 기록 찾기
    const attendanceIndex = db.attendances.findIndex(
      (a) => a.session_id === session_id && a.student_id === student_id
    );

    let attendanceRecord;

    if (attendanceIndex === -1) {
      // 새 출석 기록 생성
      attendanceRecord = {
        session_id,
        student_id,
        class_id: session.class_id,
        status,
        reason: reason || null,
        updated_by: professor_id,
        timestamp: req.requestTime,
      };

      db.attendances.push(attendanceRecord);
    } else {
      // 기존 출석 기록 업데이트
      db.attendances[attendanceIndex].status = status;
      db.attendances[attendanceIndex].reason =
        reason || db.attendances[attendanceIndex].reason;
      db.attendances[attendanceIndex].updated_by = professor_id;
      db.attendances[attendanceIndex].updated_at = req.requestTime;

      attendanceRecord = db.attendances[attendanceIndex];
    }

    // 로그 기록
    fs.appendFile(
      path.join(logDir, "attendance.log"),
      `${req.requestTime} - 세션: ${session_id}, 학생: ${student_id}, 상태 변경: ${status}, 교수: ${professor_id}\n`,
      (err) => {
        if (err) console.error("로그 기록 실패:", err);
      }
    );

    res.status(200).json({
      success: true,
      message: "출석 상태가 성공적으로 변경되었습니다",
      attendance: attendanceRecord,
    });
  } catch (error) {
    console.error(`❌ 출석 상태 변경 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// 출석 통계 조회
app.get("/api/classes/:class_id/attendance/stats", (req, res) => {
  try {
    const { class_id } = req.params;
    const { start_date, end_date } = req.query;

    // 수업 찾기
    const classInfo = db.classes.find((c) => c.class_id === class_id);

    if (!classInfo) {
      return res.status(404).json({
        success: false,
        error: "요청한 수업을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 해당 수업의 세션 찾기
    const sessions = db.sessions.filter((s) => s.class_id === class_id);

    if (sessions.length === 0) {
      return res.status(200).json({
        success: true,
        message: "해당 수업의 세션이 아직 없습니다",
        stats: {
          total_sessions: 0,
          total_students: classInfo.students.length,
          attendance_rates: {},
        },
        timestamp: req.requestTime,
      });
    }

    // 세션 ID 목록
    const sessionIds = sessions.map((s) => s.session_id);

    // 날짜 필터링 준비
    let startTimestamp = start_date ? new Date(start_date).toISOString() : null;
    let endTimestamp = end_date ? new Date(end_date).toISOString() : null;

    // 출석 기록 필터링
    let attendances = db.attendances.filter((a) =>
      sessionIds.includes(a.session_id)
    );

    // 날짜 필터링 적용
    if (startTimestamp || endTimestamp) {
      attendances = attendances.filter((a) => {
        const timestamp = a.timestamp;
        let include = true;

        if (startTimestamp && timestamp < startTimestamp) {
          include = false;
        }

        if (endTimestamp && timestamp > endTimestamp) {
          include = false;
        }

        return include;
      });
    }

    // 학생별 출석 통계 계산
    const studentStats = {};
    classInfo.students.forEach((studentId) => {
      const studentAttendances = attendances.filter(
        (a) => a.student_id === studentId
      );

      // 상태별 카운트
      const statusCounts = {
        present: studentAttendances.filter((a) => a.status === "present")
          .length,
        late: studentAttendances.filter((a) => a.status === "late").length,
        absent: studentAttendances.filter((a) => a.status === "absent").length,
        excused: studentAttendances.filter((a) => a.status === "excused")
          .length,
      };

      // 출석률 계산
      const totalSessions = sessions.length;
      const attendedSessions =
        statusCounts.present + statusCounts.late + statusCounts.excused;
      const attendanceRate =
        totalSessions > 0 ? (attendedSessions / totalSessions) * 100 : 0;

      studentStats[studentId] = {
        status_counts: statusCounts,
        attendance_rate: Math.round(attendanceRate * 10) / 10, // 소수점 첫째자리까지
        total_sessions: totalSessions,
        attended_sessions: attendedSessions,
      };
    });

    // 전체 출석률 계산
    let totalAttendanceRate = 0;
    let studentCount = classInfo.students.length;

    if (studentCount > 0) {
      const sumAttendanceRates = Object.values(studentStats).reduce(
        (sum, stat) => sum + stat.attendance_rate,
        0
      );
      totalAttendanceRate =
        Math.round((sumAttendanceRates / studentCount) * 10) / 10;
    }

    res.status(200).json({
      success: true,
      stats: {
        total_sessions: sessions.length,
        total_students: studentCount,
        total_attendance_rate: totalAttendanceRate,
        student_stats: studentStats,
      },
      timestamp: req.requestTime,
    });
  } catch (error) {
    console.error(`❌ 출석 통계 조회 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// ✅ 학생별 CSI 데이터 분석 API
app.get("/api/students/:student_id/activity", (req, res) => {
  try {
    const { student_id } = req.params;
    const { session_id, limit } = req.query;

    // 세션 ID 필터링 (있는 경우)
    let predictions = db.predictions.filter((p) => p.student_id === student_id);

    if (session_id) {
      predictions = predictions.filter((p) => p.session_id === session_id);
    }

    // 최근 데이터 기준 정렬
    predictions.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // 결과 개수 제한 (있는 경우)
    if (limit && !isNaN(parseInt(limit))) {
      predictions = predictions.slice(0, parseInt(limit));
    }

    // 활동 상태 통계 계산
    const activityStats = {
      total_predictions: predictions.length,
      active_count: predictions.filter((p) => p.is_active).length,
      inactive_count: predictions.filter((p) => !p.is_active).length,
    };

    activityStats.active_percentage =
      activityStats.total_predictions > 0
        ? Math.round(
            (activityStats.active_count / activityStats.total_predictions) * 100
          )
        : 0;

    res.status(200).json({
      success: true,
      student_id,
      activity_stats: activityStats,
      recent_activity: predictions,
      timestamp: req.requestTime,
    });
  } catch (error) {
    console.error(`❌ 학생 활동 조회 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// ✅ 비활동 알림 설정 API
app.post("/api/classes/:class_id/inactivity-settings", (req, res) => {
  try {
    const { class_id } = req.params;
    const { professor_id, threshold_minutes, enabled } = req.body;

    // 필수 파라미터 검증
    if (
      professor_id === undefined ||
      threshold_minutes === undefined ||
      enabled === undefined
    ) {
      return res.status(400).json({
        success: false,
        error:
          "필수 정보가 누락되었습니다 (professor_id, threshold_minutes, enabled)",
        timestamp: req.requestTime,
      });
    }

    // 수업 찾기
    const classIndex = db.classes.findIndex((c) => c.class_id === class_id);

    if (classIndex === -1) {
      return res.status(404).json({
        success: false,
        error: "요청한 수업을 찾을 수 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 권한 확인
    if (db.classes[classIndex].professor_id !== professor_id) {
      return res.status(403).json({
        success: false,
        error: "해당 수업의 설정을 변경할 권한이 없습니다",
        timestamp: req.requestTime,
      });
    }

    // 임계값 유효성 검사
    if (threshold_minutes < 1 || threshold_minutes > 60) {
      return res.status(400).json({
        success: false,
        error: "비활동 임계값은 1분에서 60분 사이여야 합니다",
        timestamp: req.requestTime,
      });
    }

    // 비활동 설정 업데이트 또는 생성
    if (!db.classes[classIndex].inactivity_settings) {
      db.classes[classIndex].inactivity_settings = {};
    }

    db.classes[classIndex].inactivity_settings = {
      threshold_minutes: parseInt(threshold_minutes),
      enabled: Boolean(enabled),
      updated_at: req.requestTime,
      updated_by: professor_id,
    };

    res.status(200).json({
      success: true,
      message: "비활동 알림 설정이 성공적으로 업데이트되었습니다",
      settings: db.classes[classIndex].inactivity_settings,
    });
  } catch (error) {
    console.error(`❌ 비활동 설정 오류: ${error.message}`);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
      timestamp: req.requestTime,
    });
  }
});

// ✅ 기본 경로
app.get("/", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>CSI 예측 서버</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
        h1 { color: #3B82F6; }
        .container { max-width: 800px; margin: 0 auto; }
        .status { padding: 15px; background: #d1fae5; border-radius: 5px; border-left: 5px solid #10B981; }
        code { background: #f1f5f9; padding: 2px 5px; border-radius: 3px; }
        .endpoints { margin-top: 30px; }
        .endpoint { margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #e2e8f0; }
        .method { font-weight: bold; display: inline-block; width: 60px; }
        .path { font-family: monospace; }
        .description { color: #64748b; margin-top: 5px; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>CSI 온라인 출결 시스템 서버</h1>
        <div class="status">
          <h3>✅ 서버 상태: 정상 작동 중</h3>
          <p>서버 시간: ${req.requestTime}</p>
        </div>
        
        <div class="endpoints">
          <h2>API 엔드포인트</h2>
          
          <div class="endpoint-group">
            <h3>기본 API</h3>
            <div class="endpoint">
              <span class="method">GET</span>
              <span class="path">/api/health</span>
              <div class="description">서버 상태 확인</div>
            </div>
          </div>
          
          <div class="endpoint-group">
            <h3>CSI 및 출석 API</h3>
            <div class="endpoint">
              <span class="method">POST</span>
              <span class="path">/main.py</span>
              <div class="description">CSI 예측 요청</div>
            </div>
            <div class="endpoint">
              <span class="method">POST</span>
              <span class="path">/check</span>
              <div class="description">출석 확인 요청</div>
            </div>
          </div>
          
          <div class="endpoint-group">
            <h3>수업 세션 관리 API</h3>
            <div class="endpoint">
              <span class="method">POST</span>
              <span class="path">/api/sessions/start</span>
              <div class="description">수업 세션 시작</div>
            </div>
            <div class="endpoint">
              <span class="method">POST</span>
              <span class="path">/api/sessions/{session_id}/end</span>
              <div class="description">수업 세션 종료</div>
            </div>
            <div class="endpoint">
              <span class="method">GET</span>
              <span class="path">/api/sessions/{session_id}</span>
              <div class="description">세션 상태 조회</div>
            </div>
          </div>
          
          <div class="endpoint-group">
            <h3>수업 관리 API</h3>
            <div class="endpoint">
              <span class="method">GET</span>
              <span class="path">/api/classes</span>
              <div class="description">수업 목록 조회</div>
            </div>
            <div class="endpoint">
              <span class="method">POST</span>
              <span class="path">/api/classes</span>
              <div class="description">수업 생성</div>
            </div>
            <div class="endpoint">
              <span class="method">GET</span>
              <span class="path">/api/classes/{class_id}</span>
              <div class="description">수업 상세 조회</div>
            </div>
            <div class="endpoint">
              <span class="method">PUT</span>
              <span class="path">/api/classes/{class_id}</span>
              <div class="description">수업 수정</div>
            </div>
          </div>
          
          <div class="endpoint-group">
            <h3>학생 관리 및 출석 API</h3>
            <div class="endpoint">
              <span class="method">POST</span>
              <span class="path">/api/classes/{class_id}/students</span>
              <div class="description">수업에 학생 추가</div>
            </div>
            <div class="endpoint">
              <span class="method">DELETE</span>
              <span class="path">/api/classes/{class_id}/students/{student_id}</span>
              <div class="description">수업에서 학생 제거</div>
            </div>
            <div class="endpoint">
              <span class="method">POST</span>
              <span class="path">/api/sessions/{session_id}/attendance</span>
              <div class="description">출석 상태 수동 변경</div>
            </div>
            <div class="endpoint">
              <span class="method">GET</span>
              <span class="path">/api/classes/{class_id}/attendance/stats</span>
              <div class="description">출석 통계 조회</div>
            </div>
          </div>
          
          <div class="endpoint-group">
            <h3>활동 및 비활동 관리 API</h3>
            <div class="endpoint">
              <span class="method">GET</span>
              <span class="path">/api/students/{student_id}/activity</span>
              <div class="description">학생별 CSI 데이터 활동 분석</div>
            </div>
            <div class="endpoint">
              <span class="method">POST</span>
              <span class="path">/api/classes/{class_id}/inactivity-settings</span>
              <div class="description">비활동 알림 설정</div>
            </div>
          </div>
        </div>
      </div>
    </body>
    </html>
  `);
});

// ✅ 404 오류 처리
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    error: `요청한 URL ${req.originalUrl}을(를) 찾을 수 없습니다`,
    timestamp: req.requestTime,
  });
});

// ✅ 전역 오류 처리
app.use((err, req, res, next) => {
  console.error(`💥 서버 오류: ${err.stack}`);
  res.status(err.statusCode || 500).json({
    success: false,
    error: err.message || "서버 내부 오류가 발생했습니다",
    timestamp: req.requestTime,
  });
});

// ✅ 서버 실행
const PORT = process.env.PORT || 8080;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Node.js 서버 실행 중! 포트: ${PORT}`);
  console.log(`📝 로그 디렉토리: ${logDir}`);
  console.log(`🔗 API 상태 확인: http://localhost:${PORT}/api/health`);
});
