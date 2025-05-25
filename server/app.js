/**
 * Wi-Fi CSI 기반 출결 시스템을 위한 서버
 * 학생 앱에서 출석 버튼을 누르면 라즈베리 파이에 캡처 명령을 전송하는 기능 제공
 */

// 환경변수 로드
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const { spawn } = require("child_process");
const admin = require("firebase-admin");

// 로깅 설정 - Google Cloud에서는 structured logging 사용
const enableCloudLogging = process.env.NODE_ENV === "production";

/**
 * Cloud-friendly 로깅 함수
 */
function cloudLog(severity, message, metadata = {}) {
  const entry = {
    severity: severity.toUpperCase(),
    message,
    ...metadata,
    timestamp: new Date().toISOString(),
  };

  // production 환경에서는 structured logging
  if (enableCloudLogging) {
    console.log(JSON.stringify(entry));
  } else {
    // 개발 환경에서는 가독성 있는 로깅
    console.log(`[${severity.toUpperCase()}] ${message}`, metadata);
  }
}

// Firebase 초기화
try {
  let serviceAccount;
  try {
    // 서비스 계정 키 파일 로드 시도
    serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
      "./serviceAccountKey.json");
  } catch (e) {
    cloudLog(
      "warn",
      "서비스 계정 키 파일을 찾을 수 없습니다. Firebase 인증을 건너뜁니다."
    );
    // 개발 환경에서는 파일이 없을 경우 모의 계정 사용
    if (process.env.NODE_ENV === "development") {
      serviceAccount = { projectId: "mock-project-id" };
    } else {
      // Google Cloud에서 실행 중인 경우 기본 인증 사용
      if (
        process.env.GOOGLE_APPLICATION_CREDENTIALS ||
        process.env.FIREBASE_CONFIG
      ) {
        cloudLog("info", "Google Cloud 기본 인증 사용");
        admin.initializeApp();
        throw new Error("기본 인증 사용으로 serviceAccount 로드 건너뜀");
      }
      throw e; // 프로덕션에서는 오류 발생
    }
  }

  // Firebase 앱이 이미 초기화되어 있는지 확인
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: process.env.FIREBASE_DATABASE_URL,
    });
  }
} catch (error) {
  if (error.message !== "기본 인증 사용으로 serviceAccount 로드 건너뜀") {
    cloudLog("error", "Firebase 초기화 오류:", { error: error.toString() });
  }
  // Firebase 없이도 서버는 계속 작동하도록 설정
}

const app = express();
// Cloud Run은 8080 포트를 사용하는 것을 권장
const PORT = process.env.PORT || 8080;

// 미들웨어 설정
app.use(helmet()); // 보안 헤더 설정
app.use(cors()); // CORS 허용
app.use(express.json()); // JSON 파싱

// 로깅 미들웨어
if (!enableCloudLogging) {
  // 개발 환경에서만 morgan 사용
  app.use(morgan("dev"));
}

// Google Cloud에서 요청 로깅을 위한 미들웨어
app.use((req, res, next) => {
  const start = Date.now();

  // 응답이 완료되면 로깅
  res.on("finish", () => {
    const duration = Date.now() - start;
    cloudLog("info", `${req.method} ${req.originalUrl}`, {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get("User-Agent"),
      ip: req.ip,
    });
  });

  next();
});

// 실행 중인 캡처 프로세스 관리
const captureProcesses = {};

// API 라우트
// 1. 학생 출석 체크 및 캡처 요청 API
app.post("/api/attendance/check", async (req, res) => {
  try {
    const { sessionId, classId, className, studentId, studentName, timestamp } =
      req.body;

    // 필수 파라미터 검증
    if (!sessionId || !classId || !studentId) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다",
      });
    }

    console.log(
      `출석 체크 요청: 학생 ID ${studentId}, 세션 ID ${sessionId}, 클래스 ID ${classId}`
    );

    // 1. Firebase에 출석 데이터 저장 (선택적)
    try {
      if (admin.apps.length) {
        const attendanceRef = admin.firestore().collection("attendance_logs");
        await attendanceRef.add({
          sessionId,
          classId,
          className,
          studentId,
          studentName,
          timestamp: admin.firestore.Timestamp.fromDate(
            new Date(timestamp || Date.now())
          ),
          action: "attendance_check",
          captureRequested: true,
          server_timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Firebase에 출석 로그 저장 완료: ${studentId}`);
      }
    } catch (fbError) {
      console.error("Firebase 출석 데이터 저장 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 2. 라즈베리 파이에 캡처 명령 전송
    // 실제 구현에서는 라즈베리 파이 Python 스크립트 실행 또는 API 호출
    console.log(
      `라즈베리 파이에 캡처 명령 전송: 세션 ID ${sessionId}, 학생 ID ${studentId}`
    );

    // 2-1. 클래스별로 캡처 프로세스 관리
    if (!captureProcesses[classId]) {
      // 여기서는 실제 Python 스크립트를 실행하지 않고 로그만 출력 (다른 팀원이 개발 예정)
      console.log(`[시뮬레이션] 클래스 ${classId}의 캡처 프로세스 시작 중...`);

      // 실제 구현 시에는 아래와 같이 Python 스크립트 실행
      /* 
      const captureProcess = spawn('python3', [
        './capture_script.py',
        classId,
        sessionId
      ]);
      
      captureProcesses[classId] = {
        process: captureProcess,
        sessionId: sessionId,
        startTime: new Date()
      };
      
      captureProcess.stdout.on('data', (data) => {
        console.log(`캡처 출력 [${classId}]: ${data}`);
      });
      
      captureProcess.stderr.on('data', (data) => {
        console.error(`캡처 오류 [${classId}]: ${data}`);
      });
      
      captureProcess.on('close', (code) => {
        console.log(`캡처 프로세스 종료 [${classId}]: 코드 ${code}`);
        delete captureProcesses[classId];
      });
      */

      // 개발 단계에서는 모의 객체 생성
      captureProcesses[classId] = {
        sessionId: sessionId,
        startTime: new Date(),
        students: {},
      };
    }

    // 학생 캡처 정보 추가
    if (captureProcesses[classId]) {
      captureProcesses[classId].students[studentId] = {
        name: studentName,
        lastCapture: new Date(),
        captureCount:
          (captureProcesses[classId].students[studentId]?.captureCount || 0) +
          1,
      };
    }

    // 성공 응답
    res.status(200).json({
      success: true,
      message: "출석 체크가 완료되었습니다. CSI 데이터 캡처가 요청되었습니다.",
      captureStarted: true,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("출석 처리 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 2. 교수 수업 시작 API
app.post("/api/class/start", async (req, res) => {
  try {
    const { classId, className, professorId, timestamp } = req.body;

    // 필수 파라미터 검증
    if (!classId || !professorId) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다",
      });
    }

    console.log(
      `수업 시작 요청: 교수 ID ${professorId}, 클래스 ID ${classId}, 클래스명 ${className}`
    );

    // 1. Firebase에 세션 데이터 저장 (선택적)
    let sessionId = `session_${Date.now()}`;
    try {
      if (admin.apps.length) {
        const sessionRef = admin.firestore().collection("session_logs");
        const doc = await sessionRef.add({
          classId,
          className,
          professorId,
          startTime: admin.firestore.Timestamp.fromDate(
            new Date(timestamp || Date.now())
          ),
          isActive: true,
          server_timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        sessionId = doc.id;
        console.log(`Firebase에 세션 로그 저장 완료: ${sessionId}`);
      }
    } catch (fbError) {
      console.error("Firebase 세션 데이터 저장 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 2. 라즈베리 파이에 캡처 준비 명령 전송
    console.log(
      `라즈베리 파이에 캡처 준비 명령 전송: 클래스 ID ${classId}, 세션 ID ${sessionId}`
    );

    // 개발 단계에서는 모의 객체 생성
    captureProcesses[classId] = {
      sessionId: sessionId,
      startTime: new Date(),
      students: {},
    };

    // 성공 응답
    res.status(200).json({
      success: true,
      message: "수업이 시작되었습니다. 캡처 시스템이 준비되었습니다.",
      sessionId: sessionId,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업 시작 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 교수 수업 시작 API (업데이트된 엔드포인트)
app.post("/api/classes/start", async (req, res) => {
  try {
    const { classId, className, professorId, timestamp } = req.body;

    // 필수 파라미터 검증
    if (!classId || !professorId) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다",
      });
    }

    console.log(
      `수업 시작 요청: 교수 ID ${professorId}, 클래스 ID ${classId}, 클래스명 ${className}`
    );

    // 1. Firebase에 세션 데이터 저장 (선택적)
    let sessionId = `session_${Date.now()}`;
    try {
      if (admin.apps.length) {
        const sessionRef = admin.firestore().collection("session_logs");
        const doc = await sessionRef.add({
          classId,
          className,
          professorId,
          startTime: admin.firestore.Timestamp.fromDate(
            new Date(timestamp || Date.now())
          ),
          isActive: true,
          server_timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        sessionId = doc.id;
        console.log(`Firebase에 세션 로그 저장 완료: ${sessionId}`);
      }
    } catch (fbError) {
      console.error("Firebase 세션 데이터 저장 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 2. 라즈베리 파이에 캡처 준비 명령 전송
    console.log(
      `라즈베리 파이에 캡처 준비 명령 전송: 클래스 ID ${classId}, 세션 ID ${sessionId}`
    );

    // 개발 단계에서는 모의 객체 생성
    captureProcesses[classId] = {
      sessionId: sessionId,
      startTime: new Date(),
      students: {},
    };

    // 성공 응답
    res.status(200).json({
      success: true,
      message: "수업이 시작되었습니다. 캡처 시스템이 준비되었습니다.",
      sessionId: sessionId,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업 시작 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 3. 교수 수업 종료 API
app.post("/api/class/end", async (req, res) => {
  try {
    const { sessionId, classId, timestamp } = req.body;

    // 필수 파라미터 검증
    if (!sessionId || !classId) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다",
      });
    }

    console.log(`수업 종료 요청: 클래스 ID ${classId}, 세션 ID ${sessionId}`);

    // 1. Firebase에 세션 종료 상태 업데이트 (선택적)
    try {
      if (admin.apps.length) {
        const sessionRef = admin
          .firestore()
          .collection("sessions")
          .doc(sessionId);
        await sessionRef.update({
          isActive: false,
          endTime: admin.firestore.Timestamp.fromDate(
            new Date(timestamp || Date.now())
          ),
          server_timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Firebase에 세션 종료 상태 업데이트 완료: ${sessionId}`);
      }
    } catch (fbError) {
      console.error("Firebase 세션 종료 상태 업데이트 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 2. 캡처 프로세스 종료
    if (captureProcesses[classId]) {
      console.log(`클래스 ${classId}의 캡처 프로세스 종료 중...`);

      // 실제 구현 시에는 프로세스 종료
      /*
      if (captureProcesses[classId].process) {
        captureProcesses[classId].process.kill();
      }
      */

      // 캡처 통계 정보 출력
      const captureInfo = captureProcesses[classId];
      const duration = Math.round((new Date() - captureInfo.startTime) / 1000);
      const studentCount = Object.keys(captureInfo.students).length;

      console.log(
        `캡처 세션 통계: 세션 ID ${sessionId}, 지속 시간 ${duration}초, 학생 수 ${studentCount}`
      );

      // 프로세스 정보 삭제
      delete captureProcesses[classId];
    } else {
      console.log(`클래스 ${classId}에 대한 활성 캡처 프로세스가 없습니다.`);
    }

    // 성공 응답
    res.status(200).json({
      success: true,
      message: "수업이 종료되었습니다. CSI 데이터 캡처가 중지되었습니다.",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업 종료 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 교수 수업 종료 API (업데이트된 엔드포인트)
app.post("/api/classes/end", async (req, res) => {
  try {
    const { sessionId, classId, timestamp } = req.body;

    // 필수 파라미터 검증
    if (!sessionId || !classId) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다",
      });
    }

    console.log(`수업 종료 요청: 클래스 ID ${classId}, 세션 ID ${sessionId}`);

    // 1. Firebase에 세션 종료 상태 업데이트 (선택적)
    try {
      if (admin.apps.length) {
        const sessionRef = admin
          .firestore()
          .collection("sessions")
          .doc(sessionId);
        await sessionRef.update({
          isActive: false,
          endTime: admin.firestore.Timestamp.fromDate(
            new Date(timestamp || Date.now())
          ),
          server_timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Firebase에 세션 종료 상태 업데이트 완료: ${sessionId}`);
      }
    } catch (fbError) {
      console.error("Firebase 세션 종료 상태 업데이트 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 2. 캡처 프로세스 종료
    if (captureProcesses[classId]) {
      console.log(`클래스 ${classId}의 캡처 프로세스 종료 중...`);

      // 실제 구현 시에는 프로세스 종료
      /*
      if (captureProcesses[classId].process) {
        captureProcesses[classId].process.kill();
      }
      */

      // 캡처 통계 정보 출력
      const captureInfo = captureProcesses[classId];
      const duration = Math.round((new Date() - captureInfo.startTime) / 1000);
      const studentCount = Object.keys(captureInfo.students).length;

      console.log(
        `캡처 세션 통계: 세션 ID ${sessionId}, 지속 시간 ${duration}초, 학생 수 ${studentCount}`
      );

      // 프로세스 정보 삭제
      delete captureProcesses[classId];
    } else {
      console.log(`클래스 ${classId}에 대한 활성 캡처 프로세스가 없습니다.`);
    }

    // 성공 응답
    res.status(200).json({
      success: true,
      message: "수업이 종료되었습니다. CSI 데이터 캡처가 중지되었습니다.",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업 종료 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 4. 출석 상태 조회 API
app.get("/api/attendance/status", async (req, res) => {
  try {
    const { sessionId, studentId } = req.query;

    // 필수 파라미터 검증
    if (!sessionId || !studentId) {
      return res.status(400).json({
        success: false,
        error: "필수 정보가 누락되었습니다",
      });
    }

    console.log(
      `출석 상태 조회 요청: 학생 ID ${studentId}, 세션 ID ${sessionId}`
    );

    // Firebase에서 출석 상태 조회 (선택적)
    let status = "unknown";
    let attendanceTime = null;

    try {
      if (admin.apps.length) {
        const attendanceRef = admin.firestore().collection("attendances");
        const snapshot = await attendanceRef
          .where("sessionId", "==", sessionId)
          .where("studentId", "==", studentId)
          .orderBy("recordedTime", "desc")
          .limit(1)
          .get();

        if (!snapshot.empty) {
          const doc = snapshot.docs[0];
          const data = doc.data();
          status = data.status || "unknown";
          attendanceTime = data.recordedTime
            ? data.recordedTime.toDate()
            : null;
        }
      }
    } catch (fbError) {
      console.error("Firebase 출석 상태 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 캡처 정보 확인
    let captureStatus = false;
    let lastCaptureTime = null;

    // 해당 세션의 클래스 ID 찾기
    let classId = null;
    for (const [cId, info] of Object.entries(captureProcesses)) {
      if (info.sessionId === sessionId) {
        classId = cId;
        break;
      }
    }

    if (
      classId &&
      captureProcesses[classId] &&
      captureProcesses[classId].students[studentId]
    ) {
      captureStatus = true;
      lastCaptureTime =
        captureProcesses[classId].students[studentId].lastCapture;
    }

    // 응답 구성
    res.status(200).json({
      success: true,
      sessionId,
      studentId,
      status,
      attendanceTime: attendanceTime ? attendanceTime.toISOString() : null,
      captureStatus,
      lastCaptureTime: lastCaptureTime ? lastCaptureTime.toISOString() : null,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("출석 상태 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 5. 서버 상태 확인 API (헬스 체크)
app.get("/api/health", (req, res) => {
  const uptime = process.uptime();
  const memoryUsage = process.memoryUsage();
  const activeCaptureProcesses = Object.keys(captureProcesses).length;

  res.status(200).json({
    status: "ok",
    uptime: `${Math.floor(uptime / 60)} minutes, ${Math.floor(
      uptime % 60
    )} seconds`,
    memoryUsage: {
      rss: `${Math.round(memoryUsage.rss / 1024 / 1024)} MB`,
      heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)} MB`,
      heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB`,
    },
    activeCaptureProcesses,
    timestamp: new Date().toISOString(),
  });
});

// 수업 관리 관련 엔드포인트

// 1. 특정 수업 정보 조회 API
app.get("/api/classes/:classId", async (req, res) => {
  try {
    const { classId } = req.params;

    // 필수 파라미터 검증
    if (!classId) {
      return res.status(400).json({
        success: false,
        error: "수업 ID가 필요합니다.",
      });
    }

    console.log(`수업 정보 조회 요청: 클래스 ID ${classId}`);

    // Firebase에서 수업 데이터 조회 (선택적)
    let classData = null;
    try {
      if (admin.apps.length) {
        const classRef = admin.firestore().collection("classes").doc(classId);
        const doc = await classRef.get();

        if (doc.exists) {
          classData = doc.data();
        } else {
          return res.status(404).json({
    success: false,
            error: "요청한 수업을 찾을 수 없습니다.",
          });
        }
      }
    } catch (fbError) {
      console.error("Firebase 수업 데이터 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (!classData && process.env.NODE_ENV === "development") {
      classData = {
        id: classId,
        name: "샘플 수업",
        professor: "김교수",
        schedule: "월수금 10:00-11:30",
        room: "공학관 401호",
        students: [
          { id: "student1", name: "이학생" },
          { id: "student2", name: "박학생" },
        ],
      };
    }

    res.status(200).json({
      success: true,
      data: classData,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업 정보 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 2. 교수별 수업 목록 조회 API
app.get("/api/classes/professor/:professorId", async (req, res) => {
  try {
    const { professorId } = req.params;

    // 필수 파라미터 검증
    if (!professorId) {
      return res.status(400).json({
        success: false,
        error: "교수 ID가 필요합니다.",
      });
    }

    console.log(`교수별 수업 목록 조회 요청: 교수 ID ${professorId}`);

    // Firebase에서 교수별 수업 목록 조회 (선택적)
    let classes = [];
    try {
      if (admin.apps.length) {
        const classesRef = admin.firestore().collection("classes");
        const snapshot = await classesRef
          .where("professorId", "==", professorId)
          .get();

        snapshot.forEach((doc) => {
          classes.push({
            id: doc.id,
            ...doc.data(),
          });
        });
      }
    } catch (fbError) {
      console.error("Firebase 교수별 수업 목록 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (classes.length === 0 && process.env.NODE_ENV === "development") {
      classes = [
        {
          id: "class1",
          name: "캡스톤 디자인",
          professor: professorId,
          schedule: "월수금 10:00-11:30",
          room: "공학관 401호",
        },
        {
          id: "class2",
          name: "데이터베이스",
          professor: professorId,
          schedule: "화목 13:00-14:30",
          room: "공학관 302호",
        },
      ];
    }

    res.status(200).json({
      success: true,
      data: classes,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("교수별 수업 목록 조회 오류:", error);
  res.status(500).json({
    success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 3. 학생별 수업 목록 조회 API
app.get("/api/classes/student/:studentId", async (req, res) => {
  try {
    const { studentId } = req.params;

    // 필수 파라미터 검증
    if (!studentId) {
      return res.status(400).json({
        success: false,
        error: "학생 ID가 필요합니다.",
      });
    }

    console.log(`학생별 수업 목록 조회 요청: 학생 ID ${studentId}`);

    // Firebase에서 학생별 수업 목록 조회 (선택적)
    let classes = [];
    try {
      if (admin.apps.length) {
        const classesRef = admin.firestore().collection("classes");
        const snapshot = await classesRef
          .where("students", "array-contains", studentId)
          .get();

        snapshot.forEach((doc) => {
          classes.push({
            id: doc.id,
            ...doc.data(),
          });
        });
      }
    } catch (fbError) {
      console.error("Firebase 학생별 수업 목록 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (classes.length === 0 && process.env.NODE_ENV === "development") {
      classes = [
        {
          id: "class1",
          name: "캡스톤 디자인",
          professor: "prof123",
          schedule: "월수금 10:00-11:30",
          room: "공학관 401호",
        },
        {
          id: "class2",
          name: "데이터베이스",
          professor: "prof456",
          schedule: "화목 13:00-14:30",
          room: "공학관 302호",
        },
      ];
    }

    res.status(200).json({
      success: true,
      data: classes,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("학생별 수업 목록 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 4. 수업에 학생 추가 API
app.post("/api/classes/:classId/students", async (req, res) => {
  try {
    const { classId } = req.params;
    const { studentId, studentName } = req.body;

    // 필수 파라미터 검증
    if (!classId || !studentId) {
      return res.status(400).json({
        success: false,
        error: "수업 ID와 학생 ID가 필요합니다.",
      });
    }

    console.log(
      `수업에 학생 추가 요청: 수업 ID ${classId}, 학생 ID ${studentId}`
    );

    // Firebase에 학생 추가 (선택적)
    try {
      if (admin.apps.length) {
        const classRef = admin.firestore().collection("classes").doc(classId);

        // 먼저 클래스가 존재하는지 확인
        const doc = await classRef.get();

        if (!doc.exists) {
          return res.status(404).json({
            success: false,
            error: "요청한 수업을 찾을 수 없습니다.",
          });
        }

        // 학생 배열에 추가
        await classRef.update({
          students: admin.firestore.FieldValue.arrayUnion({
            id: studentId,
            name: studentName || "학생",
            joinedAt: admin.firestore.Timestamp.now(),
          }),
        });
      }
    } catch (fbError) {
      console.error("Firebase 학생 추가 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: `학생이 수업에 성공적으로 추가되었습니다.`,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("학생 추가 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 5. 수업에서 학생 제거 API
app.delete("/api/classes/:classId/students/:studentId", async (req, res) => {
  try {
    const { classId, studentId } = req.params;

    // 필수 파라미터 검증
    if (!classId || !studentId) {
      return res.status(400).json({
        success: false,
        error: "수업 ID와 학생 ID가 필요합니다.",
      });
    }

    console.log(
      `수업에서 학생 제거 요청: 수업 ID ${classId}, 학생 ID ${studentId}`
    );

    // Firebase에서 학생 제거 (선택적)
    try {
      if (admin.apps.length) {
        const classRef = admin.firestore().collection("classes").doc(classId);

        // 먼저 클래스가 존재하는지 확인
        const doc = await classRef.get();

        if (!doc.exists) {
          return res.status(404).json({
            success: false,
            error: "요청한 수업을 찾을 수 없습니다.",
          });
        }

        // 학생 정보 찾기 및 제거
        const classData = doc.data();
        const students = classData.students || [];
        const studentIndex = students.findIndex((s) => s.id === studentId);

        if (studentIndex === -1) {
          return res.status(404).json({
            success: false,
            error: "해당 수업에서 학생을 찾을 수 없습니다.",
          });
        }

        students.splice(studentIndex, 1);

        // 업데이트
        await classRef.update({ students });
      }
    } catch (fbError) {
      console.error("Firebase 학생 제거 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: `학생이 수업에서 성공적으로 제거되었습니다.`,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("학생 제거 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 출석 관리 관련 엔드포인트

// 1. 출석 세션 생성 API
app.post("/api/attendance/sessions", async (req, res) => {
  try {
    const { classId, className, professorId } = req.body;

    // 필수 파라미터 검증
    if (!classId || !professorId) {
      return res.status(400).json({
        success: false,
        error: "수업 ID와 교수 ID가 필요합니다.",
      });
    }

    console.log(
      `출석 세션 생성 요청: 수업 ID ${classId}, 교수 ID ${professorId}`
    );

    // Firebase에 세션 데이터 저장 (선택적)
    let sessionId = `session_${Date.now()}`;
    try {
      if (admin.apps.length) {
        const sessionRef = admin.firestore().collection("attendance_sessions");
        const doc = await sessionRef.add({
          classId,
          className,
          professorId,
          startTime: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
          students: [],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        sessionId = doc.id;
        console.log(`Firebase에 출석 세션 저장 완료: ${sessionId}`);
      }
    } catch (fbError) {
      console.error("Firebase 출석 세션 저장 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: "출석 세션이 성공적으로 생성되었습니다.",
      sessionId,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("출석 세션 생성 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 2. 출석 세션 종료 API
app.put("/api/attendance/sessions/:sessionId/end", async (req, res) => {
  try {
    const { sessionId } = req.params;

    // 필수 파라미터 검증
    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: "세션 ID가 필요합니다.",
      });
    }

    console.log(`출석 세션 종료 요청: 세션 ID ${sessionId}`);

    // Firebase에 세션 종료 상태 업데이트 (선택적)
    try {
      if (admin.apps.length) {
        const sessionRef = admin
          .firestore()
          .collection("attendance_sessions")
          .doc(sessionId);
        const doc = await sessionRef.get();

        if (!doc.exists) {
          return res.status(404).json({
            success: false,
            error: "요청한 세션을 찾을 수 없습니다.",
          });
        }

        await sessionRef.update({
          isActive: false,
          endTime: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Firebase에 세션 종료 상태 업데이트 완료: ${sessionId}`);
      }
    } catch (fbError) {
      console.error("Firebase 세션 종료 상태 업데이트 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: "출석 세션이 성공적으로 종료되었습니다.",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("출석 세션 종료 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 3. 특정 세션의 출석 정보 조회 API
app.get("/api/attendance/sessions/:sessionId", async (req, res) => {
  try {
    const { sessionId } = req.params;

    // 필수 파라미터 검증
    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: "세션 ID가 필요합니다.",
      });
    }

    console.log(`세션 출석 정보 조회 요청: 세션 ID ${sessionId}`);

    // Firebase에서 세션 데이터 조회 (선택적)
    let sessionData = null;
    try {
      if (admin.apps.length) {
        const sessionRef = admin
          .firestore()
          .collection("attendance_sessions")
          .doc(sessionId);
        const doc = await sessionRef.get();

        if (doc.exists) {
          sessionData = doc.data();

          // 출석 데이터 가져오기
          const attendanceRef = admin.firestore().collection("attendance_logs");
          const snapshot = await attendanceRef
            .where("sessionId", "==", sessionId)
            .get();

          const attendances = [];
          snapshot.forEach((doc) => {
            attendances.push({
              id: doc.id,
              ...doc.data(),
            });
          });

          sessionData.attendances = attendances;
        } else {
          return res.status(404).json({
            success: false,
            error: "요청한 세션을 찾을 수 없습니다.",
          });
        }
      }
    } catch (fbError) {
      console.error("Firebase 세션 데이터 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (!sessionData && process.env.NODE_ENV === "development") {
      sessionData = {
        id: sessionId,
        classId: "class123",
        className: "캡스톤 디자인",
        professorId: "prof123",
        startTime: new Date(Date.now() - 3600000).toISOString(), // 1시간 전
        endTime: new Date().toISOString(),
        isActive: false,
        attendances: [
          {
            id: "att1",
            studentId: "student1",
            studentName: "이학생",
            status: "present",
            timestamp: new Date(Date.now() - 3300000).toISOString(), // 55분 전
          },
          {
            id: "att2",
            studentId: "student2",
            studentName: "박학생",
            status: "late",
            timestamp: new Date(Date.now() - 2700000).toISOString(), // 45분 전
          },
        ],
      };
    }

    res.status(200).json({
      success: true,
      data: sessionData,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("세션 출석 정보 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 4. 수업별 전체 세션 목록 조회 API
app.get("/api/attendance/classes/:classId/sessions", async (req, res) => {
  try {
    const { classId } = req.params;

    // 필수 파라미터 검증
    if (!classId) {
      return res.status(400).json({
        success: false,
        error: "수업 ID가 필요합니다.",
      });
    }

    console.log(`수업별 세션 목록 조회 요청: 수업 ID ${classId}`);

    // Firebase에서 수업별 세션 목록 조회 (선택적)
    let sessions = [];
    try {
      if (admin.apps.length) {
        const sessionsRef = admin.firestore().collection("attendance_sessions");
        const snapshot = await sessionsRef
          .where("classId", "==", classId)
          .orderBy("startTime", "desc")
          .get();

        snapshot.forEach((doc) => {
          sessions.push({
            id: doc.id,
            ...doc.data(),
          });
        });
      }
    } catch (fbError) {
      console.error("Firebase 수업별 세션 목록 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (sessions.length === 0 && process.env.NODE_ENV === "development") {
      const now = Date.now();
      sessions = [
        {
          id: "session1",
          classId,
          className: "캡스톤 디자인",
          professorId: "prof123",
          startTime: new Date(now - 86400000).toISOString(), // 어제
          endTime: new Date(now - 82800000).toISOString(),
          isActive: false,
          studentCount: 15,
          presentCount: 12,
          lateCount: 2,
          absentCount: 1,
        },
        {
          id: "session2",
          classId,
          className: "캡스톤 디자인",
          professorId: "prof123",
          startTime: new Date(now - 259200000).toISOString(), // 3일 전
          endTime: new Date(now - 255600000).toISOString(),
          isActive: false,
          studentCount: 15,
          presentCount: 13,
          lateCount: 1,
          absentCount: 1,
        },
      ];
    }

    res.status(200).json({
      success: true,
      data: sessions,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업별 세션 목록 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 5. 수업의 학생 출석 상태 조회 API
app.get("/api/attendance/classes/:classId/students", async (req, res) => {
  try {
    const { classId } = req.params;
    const { sessionId } = req.query;

    // 필수 파라미터 검증
    if (!classId) {
      return res.status(400).json({
        success: false,
        error: "수업 ID가 필요합니다.",
      });
    }

    console.log(`수업 학생 출석 상태 조회 요청: 수업 ID ${classId}`);

    // Firebase에서 학생 출석 데이터 조회 (선택적)
    let studentAttendances = [];
    try {
      if (admin.apps.length) {
        // 먼저 수업에 등록된 학생 목록 가져오기
        const classRef = admin.firestore().collection("classes").doc(classId);
        const classDoc = await classRef.get();

        if (!classDoc.exists) {
          return res.status(404).json({
            success: false,
            error: "요청한 수업을 찾을 수 없습니다.",
          });
        }

        const classData = classDoc.data();
        const students = classData.students || [];

        // 세션 ID가 있는 경우, 해당 세션의 출석 데이터 가져오기
        if (sessionId) {
          const attendanceRef = admin.firestore().collection("attendance_logs");
          const snapshot = await attendanceRef
            .where("sessionId", "==", sessionId)
            .get();

          const attendanceMap = {};
          snapshot.forEach((doc) => {
            const data = doc.data();
            attendanceMap[data.studentId] = data;
          });

          // 학생별 출석 상태 구성
          studentAttendances = students.map((student) => {
            const attendance = attendanceMap[student.id] || {
              status: "absent",
            };
            return {
              studentId: student.id,
              studentName: student.name,
              status: attendance.status || "absent",
              timestamp: attendance.timestamp
                ? attendance.timestamp.toDate().toISOString()
                : null,
              sessionId,
            };
          });
        }
        // 세션 ID가 없는 경우, 학생별 전체 출석 통계 가져오기
        else {
          // 수업의 모든 세션 가져오기
          const sessionsRef = admin
            .firestore()
            .collection("attendance_sessions");
          const sessionsSnapshot = await sessionsRef
            .where("classId", "==", classId)
            .get();

          const sessionIds = [];
          sessionsSnapshot.forEach((doc) => {
            sessionIds.push(doc.id);
          });

          // 학생별 출석 통계 구성
          for (const student of students) {
            const attendanceRef = admin
              .firestore()
              .collection("attendance_logs");
            const snapshot = await attendanceRef
              .where("studentId", "==", student.id)
              .where("sessionId", "in", sessionIds)
              .get();

            let presentCount = 0;
            let lateCount = 0;
            let absentCount = 0;

            snapshot.forEach((doc) => {
              const data = doc.data();
              if (data.status === "present") presentCount++;
              else if (data.status === "late") lateCount++;
              else if (data.status === "absent") absentCount++;
            });

            // 결석 수 계산 (전체 세션 수 - 출석/지각 수)
            absentCount = sessionIds.length - (presentCount + lateCount);
            if (absentCount < 0) absentCount = 0;

            studentAttendances.push({
              studentId: student.id,
              studentName: student.name,
              totalSessions: sessionIds.length,
              presentCount,
              lateCount,
              absentCount,
              attendanceRate:
                sessionIds.length > 0
                  ? Math.round(
                      ((presentCount + lateCount) / sessionIds.length) * 100
                    )
                  : 0,
            });
          }
        }
      }
    } catch (fbError) {
      console.error("Firebase 학생 출석 데이터 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (
      studentAttendances.length === 0 &&
      process.env.NODE_ENV === "development"
    ) {
      if (sessionId) {
        studentAttendances = [
          {
            studentId: "student1",
            studentName: "이학생",
            status: "present",
            timestamp: new Date(Date.now() - 1800000).toISOString(), // 30분 전
            sessionId,
          },
          {
            studentId: "student2",
            studentName: "박학생",
            status: "late",
            timestamp: new Date(Date.now() - 1200000).toISOString(), // 20분 전
            sessionId,
          },
          {
            studentId: "student3",
            studentName: "김학생",
            status: "absent",
            timestamp: null,
            sessionId,
          },
        ];
      } else {
        studentAttendances = [
          {
            studentId: "student1",
            studentName: "이학생",
            totalSessions: 10,
            presentCount: 8,
            lateCount: 1,
            absentCount: 1,
            attendanceRate: 90,
          },
          {
            studentId: "student2",
            studentName: "박학생",
            totalSessions: 10,
            presentCount: 7,
            lateCount: 2,
            absentCount: 1,
            attendanceRate: 90,
          },
          {
            studentId: "student3",
            studentName: "김학생",
            totalSessions: 10,
            presentCount: 5,
            lateCount: 3,
            absentCount: 2,
            attendanceRate: 80,
          },
        ];
      }
    }

    res.status(200).json({
      success: true,
      data: studentAttendances,
      sessionSpecific: !!sessionId,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업 학생 출석 상태 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 6. 학생 출석 상태 수동 변경 API
app.put("/api/attendance/students/:studentId/status", async (req, res) => {
  try {
    const { studentId } = req.params;
    const { sessionId, status, reason } = req.body;

    // 필수 파라미터 검증
    if (!studentId || !sessionId || !status) {
      return res.status(400).json({
        success: false,
        error: "학생 ID, 세션 ID, 상태 정보가 필요합니다.",
      });
    }

    // 상태값 유효성 검증
    if (!["present", "late", "absent", "excused"].includes(status)) {
      return res.status(400).json({
        success: false,
        error:
          "유효하지 않은 출석 상태입니다. present, late, absent, excused 중 하나여야 합니다.",
      });
    }

    console.log(
      `학생 출석 상태 변경 요청: 학생 ID ${studentId}, 세션 ID ${sessionId}, 상태 ${status}`
    );

    // Firebase에 출석 상태 업데이트 (선택적)
    try {
      if (admin.apps.length) {
        const attendanceRef = admin.firestore().collection("attendance_logs");
        const snapshot = await attendanceRef
          .where("sessionId", "==", sessionId)
          .where("studentId", "==", studentId)
          .limit(1)
          .get();

        if (snapshot.empty) {
          // 새로운 출석 기록 생성
          await attendanceRef.add({
            sessionId,
            studentId,
            status,
            reason: reason || null,
            updatedBy: "manual",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          // 기존 출석 기록 업데이트
          const doc = snapshot.docs[0];
          await doc.ref.update({
            status,
            reason: reason || null,
            updatedBy: "manual",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (fbError) {
      console.error("Firebase 출석 상태 업데이트 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: `학생 출석 상태가 성공적으로 변경되었습니다.`,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("학생 출석 상태 변경 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// CSI 데이터 관련 엔드포인트

// 1. 학생 기기에서 CSI 데이터 전송 API
app.post("/api/csi/data", async (req, res) => {
  try {
    const {
      sessionId,
      studentId,
      studentName,
      csiData,
      deviceInfo,
      timestamp,
    } = req.body;

    // 필수 파라미터 검증
    if (!sessionId || !studentId || !csiData) {
      return res.status(400).json({
        success: false,
        error: "세션 ID, 학생 ID, CSI 데이터가 필요합니다.",
      });
    }

    console.log(`CSI 데이터 수신: 학생 ID ${studentId}, 세션 ID ${sessionId}`);

    // Firebase에 CSI 데이터 저장 (선택적)
    try {
      if (admin.apps.length) {
        const csiRef = admin.firestore().collection("csi_data");
        await csiRef.add({
          sessionId,
          studentId,
          studentName,
          csiData,
          deviceInfo: deviceInfo || null,
          timestamp: timestamp
            ? admin.firestore.Timestamp.fromDate(new Date(timestamp))
            : admin.firestore.FieldValue.serverTimestamp(),
          receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (fbError) {
      console.error("Firebase CSI 데이터 저장 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 캡처 프로세스 정보 업데이트
    if (captureProcesses[sessionId]) {
      if (!captureProcesses[sessionId].students) {
        captureProcesses[sessionId].students = {};
      }

      captureProcesses[sessionId].students[studentId] = {
        name: studentName,
        lastCapture: new Date(),
        captureCount:
          (captureProcesses[sessionId].students[studentId]?.captureCount || 0) +
          1,
      };
    }

    res.status(200).json({
      success: true,
      message: "CSI 데이터가 성공적으로 수신되었습니다.",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("CSI 데이터 수신 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 2. 학생의 활동 상태 조회 API
app.get("/api/csi/status/:studentId", async (req, res) => {
  try {
    const { studentId } = req.params;
    const { sessionId } = req.query;

    // 필수 파라미터 검증
    if (!studentId || !sessionId) {
      return res.status(400).json({
        success: false,
        error: "학생 ID와 세션 ID가 필요합니다.",
      });
    }

    console.log(
      `학생 활동 상태 조회 요청: 학생 ID ${studentId}, 세션 ID ${sessionId}`
    );

    // 활동 상태 정보 초기화
    let status = "inactive";
    let lastActivity = null;
    let activityLevel = 0;
    let details = {};

    // 캡처 프로세스에서 학생 정보 확인
    if (
      captureProcesses[sessionId] &&
      captureProcesses[sessionId].students &&
      captureProcesses[sessionId].students[studentId]
    ) {
      const studentInfo = captureProcesses[sessionId].students[studentId];
      lastActivity = studentInfo.lastCapture;

      // 마지막 활동 시간이 5분 이내인 경우 활동 중으로 판단
      const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
      if (lastActivity && lastActivity > fiveMinutesAgo) {
        status = "active";

        // 활동 수준 계산 (1-10)
        const minutesSinceLastActivity =
          (Date.now() - lastActivity) / (60 * 1000);
        activityLevel = Math.max(
          1,
          Math.min(10, Math.round(10 - minutesSinceLastActivity * 2))
        );
      }

      details = {
        captureCount: studentInfo.captureCount || 0,
        lastCaptureTime: lastActivity ? lastActivity.toISOString() : null,
      };
    }

    // Firebase에서 학생의 CSI 데이터 조회 (최근 10개)
    try {
      if (admin.apps.length) {
        const csiRef = admin.firestore().collection("csi_data");
        const snapshot = await csiRef
          .where("sessionId", "==", sessionId)
          .where("studentId", "==", studentId)
          .orderBy("timestamp", "desc")
          .limit(10)
          .get();

        const csiData = [];
        snapshot.forEach((doc) => {
          csiData.push({
            id: doc.id,
            ...doc.data(),
            timestamp: doc.data().timestamp.toDate().toISOString(),
          });
        });

        details.recentCSIData = csiData;
      }
    } catch (fbError) {
      console.error("Firebase CSI 데이터 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      studentId,
      sessionId,
      status,
      activityLevel,
      lastActivity: lastActivity ? lastActivity.toISOString() : null,
      details,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("학생 활동 상태 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 3. 세션 내 모든 학생의 활동 상태 조회 API
app.get("/api/csi/sessions/:sessionId/students", async (req, res) => {
  try {
    const { sessionId } = req.params;

    // 필수 파라미터 검증
    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: "세션 ID가 필요합니다.",
      });
    }

    console.log(`세션 학생 활동 상태 조회 요청: 세션 ID ${sessionId}`);

    // 학생 활동 상태 목록 초기화
    const studentStatuses = [];

    // 캡처 프로세스에서 학생 정보 확인
    if (captureProcesses[sessionId] && captureProcesses[sessionId].students) {
      const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

      for (const [studentId, studentInfo] of Object.entries(
        captureProcesses[sessionId].students
      )) {
        const lastActivity = studentInfo.lastCapture;

        // 상태 및 활동 수준 계산
        let status = "inactive";
        let activityLevel = 0;

        if (lastActivity && lastActivity > fiveMinutesAgo) {
          status = "active";
          const minutesSinceLastActivity =
            (Date.now() - lastActivity) / (60 * 1000);
          activityLevel = Math.max(
            1,
            Math.min(10, Math.round(10 - minutesSinceLastActivity * 2))
          );
        }

        studentStatuses.push({
          studentId,
          studentName: studentInfo.name || "Unknown",
          status,
          activityLevel,
          lastActivity: lastActivity ? lastActivity.toISOString() : null,
          captureCount: studentInfo.captureCount || 0,
        });
      }
    }

    // Firebase에서 세션에 등록된 모든 학생 조회
    let registeredStudents = [];
    try {
      if (admin.apps.length) {
        // 세션 정보 가져오기
        const sessionRef = admin
          .firestore()
          .collection("attendance_sessions")
          .doc(sessionId);
        const sessionDoc = await sessionRef.get();

        if (sessionDoc.exists) {
          const sessionData = sessionDoc.data();
          const classId = sessionData.classId;

          // 클래스에 등록된 학생 가져오기
          if (classId) {
            const classRef = admin
              .firestore()
              .collection("classes")
              .doc(classId);
            const classDoc = await classRef.get();

            if (classDoc.exists) {
              const classData = classDoc.data();
              registeredStudents = classData.students || [];
            }
          }
        }

        // 등록된 학생 중 상태 정보가 없는 학생 추가
        for (const student of registeredStudents) {
          const exists = studentStatuses.some(
            (s) => s.studentId === student.id
          );
          if (!exists) {
            studentStatuses.push({
              studentId: student.id,
              studentName: student.name || "Unknown",
              status: "not_present",
              activityLevel: 0,
              lastActivity: null,
              captureCount: 0,
            });
          }
        }
      }
    } catch (fbError) {
      console.error("Firebase 학생 목록 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 추가
    if (
      studentStatuses.length === 0 &&
      process.env.NODE_ENV === "development"
    ) {
      studentStatuses.push(
        {
          studentId: "student1",
          studentName: "이학생",
          status: "active",
          activityLevel: 8,
          lastActivity: new Date(Date.now() - 60000).toISOString(), // 1분 전
          captureCount: 12,
        },
        {
          studentId: "student2",
          studentName: "박학생",
          status: "active",
          activityLevel: 5,
          lastActivity: new Date(Date.now() - 180000).toISOString(), // 3분 전
          captureCount: 10,
        },
        {
          studentId: "student3",
          studentName: "김학생",
          status: "inactive",
          activityLevel: 0,
          lastActivity: new Date(Date.now() - 420000).toISOString(), // 7분 전
          captureCount: 5,
        }
      );
    }

    res.status(200).json({
      success: true,
      sessionId,
      data: studentStatuses,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("세션 학생 활동 상태 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 4. CSI 데이터 분석 시작 API
app.post("/api/csi/analysis/start", async (req, res) => {
  try {
    const { sessionId, parameters } = req.body;

    // 필수 파라미터 검증
    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: "세션 ID가 필요합니다.",
      });
    }

    console.log(`CSI 데이터 분석 시작 요청: 세션 ID ${sessionId}`);

    // 분석 파라미터 설정 (기본값 또는 제공된 값 사용)
    const analysisParams = {
      activityThreshold: parameters?.activityThreshold || 0.3,
      samplingRate: parameters?.samplingRate || 1.0,
      windowSize: parameters?.windowSize || 10,
      ...parameters,
    };

    // 분석 프로세스 시작 (현재는 시뮬레이션만 제공)
    console.log(`CSI 데이터 분석 파라미터:`, analysisParams);

    // 분석 정보를 Firebase에 저장 (선택적)
    try {
      if (admin.apps.length) {
        const analysisRef = admin.firestore().collection("csi_analysis");
        await analysisRef.doc(sessionId).set({
          sessionId,
          status: "running",
          parameters: analysisParams,
          startedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (fbError) {
      console.error("Firebase 분석 정보 저장 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: "CSI 데이터 분석이 시작되었습니다.",
      parameters: analysisParams,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("CSI 데이터 분석 시작 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 5. CSI 데이터 분석 종료 API
app.post("/api/csi/analysis/stop", async (req, res) => {
  try {
    const { sessionId } = req.body;

    // 필수 파라미터 검증
    if (!sessionId) {
      return res.status(400).json({
        success: false,
        error: "세션 ID가 필요합니다.",
      });
    }

    console.log(`CSI 데이터 분석 종료 요청: 세션 ID ${sessionId}`);

    // 분석 상태를 Firebase에 업데이트 (선택적)
    try {
      if (admin.apps.length) {
        const analysisRef = admin
          .firestore()
          .collection("csi_analysis")
          .doc(sessionId);
        const doc = await analysisRef.get();

        if (doc.exists) {
          await analysisRef.update({
            status: "completed",
            endedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          return res.status(404).json({
            success: false,
            error: "요청한 분석 세션을 찾을 수 없습니다.",
          });
        }
      }
    } catch (fbError) {
      console.error("Firebase 분석 상태 업데이트 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: "CSI 데이터 분석이 중지되었습니다.",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("CSI 데이터 분석 중지 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 알림 관련 엔드포인트

// 1. 특정 사용자에게 알림 전송 API
app.post("/api/notifications/send", async (req, res) => {
  try {
    const { userId, title, body, data } = req.body;

    // 필수 파라미터 검증
    if (!userId || !title || !body) {
      return res.status(400).json({
        success: false,
        error: "사용자 ID, 제목, 내용이 필요합니다.",
      });
    }

    console.log(`알림 전송 요청: 사용자 ID ${userId}`);

    // Firebase Cloud Messaging을 통한 알림 전송 (선택적)
    try {
      if (admin.apps.length) {
        // 사용자의 FCM 토큰 가져오기
        const userRef = admin.firestore().collection("users").doc(userId);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
          return res.status(404).json({
            success: false,
            error: "사용자를 찾을 수 없습니다.",
          });
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          return res.status(400).json({
            success: false,
            error: "사용자의 FCM 토큰이 등록되어 있지 않습니다.",
          });
        }

        // 알림 메시지 구성
        const message = {
          notification: {
            title,
            body,
          },
          data: data || {},
          token: fcmToken,
        };

        // FCM 전송
        const response = await admin.messaging().send(message);
        console.log("알림 전송 성공:", response);

        // 알림 기록 저장
        const notificationRef = admin.firestore().collection("notifications");
        await notificationRef.add({
          userId,
          title,
          body,
          data: data || {},
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (fbError) {
      console.error("Firebase 알림 전송 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: "알림이 성공적으로 전송되었습니다.",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("알림 전송 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 2. 수업의 모든 학생에게 알림 전송 API
app.post("/api/notifications/broadcast/:classId", async (req, res) => {
  try {
    const { classId } = req.params;
    const { title, body, data } = req.body;

    // 필수 파라미터 검증
    if (!classId || !title || !body) {
      return res.status(400).json({
        success: false,
        error: "수업 ID, 제목, 내용이 필요합니다.",
      });
    }

    console.log(`수업 전체 알림 전송 요청: 수업 ID ${classId}`);

    // Firebase에서 수업 학생 목록 조회 (선택적)
    try {
      if (admin.apps.length) {
        // 수업에 등록된 학생 목록 가져오기
        const classRef = admin.firestore().collection("classes").doc(classId);
        const classDoc = await classRef.get();

        if (!classDoc.exists) {
          return res.status(404).json({
            success: false,
            error: "요청한 수업을 찾을 수 없습니다.",
          });
        }

        const classData = classDoc.data();
        const students = classData.students || [];

        if (students.length === 0) {
          return res.status(404).json({
            success: false,
            error: "수업에 등록된 학생이 없습니다.",
          });
        }

        // 각 학생에게 알림 전송
        const failedStudents = [];
        let successCount = 0;

        for (const student of students) {
          try {
            // 학생의 FCM 토큰 가져오기
            const userRef = admin
              .firestore()
              .collection("users")
              .doc(student.id);
            const userDoc = await userRef.get();

            if (!userDoc.exists) {
              failedStudents.push({
                id: student.id,
                reason: "사용자 찾을 수 없음",
              });
              continue;
            }

            const userData = userDoc.data();
            const fcmToken = userData.fcmToken;

            if (!fcmToken) {
              failedStudents.push({ id: student.id, reason: "FCM 토큰 없음" });
              continue;
            }

            // 알림 메시지 구성
            const message = {
              notification: {
                title,
                body,
              },
              data: {
                ...data,
                classId,
              },
              token: fcmToken,
            };

            // FCM 전송
            await admin.messaging().send(message);

            // 알림 기록 저장
            const notificationRef = admin
              .firestore()
              .collection("notifications");
            await notificationRef.add({
              userId: student.id,
              title,
              body,
              data: { ...data, classId },
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            successCount++;
          } catch (error) {
            failedStudents.push({ id: student.id, reason: error.message });
          }
        }

        return res.status(200).json({
          success: true,
          message: `${successCount}명의 학생에게 알림이 전송되었습니다.`,
          failedCount: failedStudents.length,
          failedStudents,
          timestamp: new Date().toISOString(),
        });
      }
    } catch (fbError) {
      console.error("Firebase 수업 학생 목록 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 성공 응답 반환
    res.status(200).json({
      success: true,
      message: "알림이 모든 학생에게 성공적으로 전송되었습니다. (개발 모드)",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업 전체 알림 전송 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 3. 사용자별 알림 목록 조회 API
app.get("/api/notifications/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit, page } = req.query;

    // 필수 파라미터 검증
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: "사용자 ID가 필요합니다.",
      });
    }

    // 페이징 처리를 위한 파라미터 설정
    const pageLimit = parseInt(limit) || 20;
    const pageNumber = parseInt(page) || 1;
    const offset = (pageNumber - 1) * pageLimit;

    console.log(`사용자별 알림 목록 조회 요청: 사용자 ID ${userId}`);

    // Firebase에서 사용자별 알림 목록 조회 (선택적)
    let notifications = [];
    let totalCount = 0;
    try {
      if (admin.apps.length) {
        const notificationRef = admin.firestore().collection("notifications");

        // 총 알림 수 카운트
        const countSnapshot = await notificationRef
          .where("userId", "==", userId)
          .count()
          .get();
        totalCount = countSnapshot.data().count;

        // 알림 목록 조회
        const snapshot = await notificationRef
          .where("userId", "==", userId)
          .orderBy("createdAt", "desc")
          .limit(pageLimit)
          .offset(offset)
          .get();

        snapshot.forEach((doc) => {
          notifications.push({
            id: doc.id,
            ...doc.data(),
            createdAt: doc.data().createdAt.toDate().toISOString(),
          });
        });
      }
    } catch (fbError) {
      console.error("Firebase 사용자별 알림 목록 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (notifications.length === 0 && process.env.NODE_ENV === "development") {
      notifications = [
        {
          id: "notification1",
          userId,
          title: "수업 시작 알림",
          body: "캡스톤 디자인 수업이 5분 후에 시작됩니다.",
          isRead: false,
          createdAt: new Date(Date.now() - 300000).toISOString(), // 5분 전
        },
        {
          id: "notification2",
          userId,
          title: "출석 확인 알림",
          body: "데이터베이스 수업의 출석이 확인되었습니다.",
          isRead: true,
          createdAt: new Date(Date.now() - 86400000).toISOString(), // 1일 전
        },
      ];
      totalCount = 2;
    }

    res.status(200).json({
      success: true,
      data: notifications,
      pagination: {
        total: totalCount,
        limit: pageLimit,
        page: pageNumber,
        pages: Math.ceil(totalCount / pageLimit),
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("사용자별 알림 목록 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 4. 알림 읽음 상태로 변경 API
app.put("/api/notifications/:notificationId/read", async (req, res) => {
  try {
    const { notificationId } = req.params;
    const { userId } = req.body;

    // 필수 파라미터 검증
    if (!notificationId) {
      return res.status(400).json({
        success: false,
        error: "알림 ID가 필요합니다.",
      });
    }

    console.log(`알림 읽음 상태 변경 요청: 알림 ID ${notificationId}`);

    // Firebase에서 알림 읽음 상태 업데이트 (선택적)
    try {
      if (admin.apps.length) {
        const notificationRef = admin
          .firestore()
          .collection("notifications")
          .doc(notificationId);
        const doc = await notificationRef.get();

        if (!doc.exists) {
          return res.status(404).json({
            success: false,
            error: "요청한 알림을 찾을 수 없습니다.",
          });
        }

        // 권한 확인 (선택적)
        if (userId && doc.data().userId !== userId) {
          return res.status(403).json({
            success: false,
            error: "이 알림에 대한 접근 권한이 없습니다.",
          });
        }

        // 상태 업데이트
        await notificationRef.update({
          isRead: true,
          readAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (fbError) {
      console.error("Firebase 알림 읽음 상태 업데이트 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    res.status(200).json({
      success: true,
      message: "알림이 읽음 상태로 변경되었습니다.",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("알림 읽음 상태 변경 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 통계 및 보고서 관련 엔드포인트

// 1. 수업별 출석 통계 조회 API
app.get("/api/statistics/classes/:classId/attendance", async (req, res) => {
  try {
    const { classId } = req.params;
    const { startDate, endDate } = req.query;

    // 필수 파라미터 검증
    if (!classId) {
      return res.status(400).json({
        success: false,
        error: "수업 ID가 필요합니다.",
      });
    }

    console.log(`수업별 출석 통계 조회 요청: 수업 ID ${classId}`);

    // 날짜 범위 설정
    let start = startDate ? new Date(startDate) : new Date();
    start.setHours(0, 0, 0, 0);
    start.setMonth(start.getMonth() - 1); // 기본값: 1개월 전

    let end = endDate ? new Date(endDate) : new Date();
    end.setHours(23, 59, 59, 999);

    // Firebase에서 수업별 출석 통계 조회 (선택적)
    let statistics = {
      classId,
      totalSessions: 0,
      totalStudents: 0,
      averageAttendanceRate: 0,
      attendanceByStatus: {
        present: 0,
        late: 0,
        absent: 0,
        excused: 0,
      },
      attendanceByDate: {},
      studentStatistics: [],
    };

    try {
      if (admin.apps.length) {
        // 수업 정보 가져오기
        const classRef = admin.firestore().collection("classes").doc(classId);
        const classDoc = await classRef.get();

        if (!classDoc.exists) {
          return res.status(404).json({
            success: false,
            error: "요청한 수업을 찾을 수 없습니다.",
          });
        }

        const classData = classDoc.data();
        const students = classData.students || [];
        statistics.totalStudents = students.length;

        // 해당 기간의 세션 목록 가져오기
        const sessionsRef = admin.firestore().collection("attendance_sessions");
        const sessionsSnapshot = await sessionsRef
          .where("classId", "==", classId)
          .where("startTime", ">=", admin.firestore.Timestamp.fromDate(start))
          .where("startTime", "<=", admin.firestore.Timestamp.fromDate(end))
          .get();

        const sessions = [];
        sessionsSnapshot.forEach((doc) => {
          sessions.push({
            id: doc.id,
            ...doc.data(),
          });
        });

        statistics.totalSessions = sessions.length;

        // 각 세션별 출석 데이터 가져오기
        const attendanceMap = {};
        for (const session of sessions) {
          const sessionDate = session.startTime
            .toDate()
            .toISOString()
            .split("T")[0];

          const attendanceRef = admin.firestore().collection("attendance_logs");
          const snapshot = await attendanceRef
            .where("sessionId", "==", session.id)
            .get();

          if (!attendanceMap[sessionDate]) {
            attendanceMap[sessionDate] = {
              present: 0,
              late: 0,
              absent: 0,
              excused: 0,
              total: students.length,
            };
          }

          snapshot.forEach((doc) => {
            const data = doc.data();
            if (data.status) {
              attendanceMap[sessionDate][data.status]++;
              statistics.attendanceByStatus[data.status]++;
            }
          });

          // 결석 수 계산 (전체 학생 수 - 출석/지각/공결 수)
          const recorded =
            attendanceMap[sessionDate].present +
            attendanceMap[sessionDate].late +
            attendanceMap[sessionDate].excused;
          attendanceMap[sessionDate].absent = students.length - recorded;
          statistics.attendanceByStatus.absent +=
            attendanceMap[sessionDate].absent;
        }

        statistics.attendanceByDate = attendanceMap;

        // 평균 출석률 계산
        if (statistics.totalSessions > 0 && statistics.totalStudents > 0) {
          const totalPresent =
            statistics.attendanceByStatus.present +
            statistics.attendanceByStatus.late;
          const totalPossible =
            statistics.totalSessions * statistics.totalStudents;
          statistics.averageAttendanceRate = Math.round(
            (totalPresent / totalPossible) * 100
          );
        }

        // 학생별 통계 계산
        for (const student of students) {
          let studentStats = {
            studentId: student.id,
            studentName: student.name,
            present: 0,
            late: 0,
            absent: 0,
            excused: 0,
            attendanceRate: 0,
          };

          for (const session of sessions) {
            const attendanceRef = admin
              .firestore()
              .collection("attendance_logs");
            const snapshot = await attendanceRef
              .where("sessionId", "==", session.id)
              .where("studentId", "==", student.id)
              .limit(1)
              .get();

            if (snapshot.empty) {
              studentStats.absent++;
            } else {
              const data = snapshot.docs[0].data();
              if (data.status) {
                studentStats[data.status]++;
              } else {
                studentStats.absent++;
              }
            }
          }

          // 학생 출석률 계산
          if (statistics.totalSessions > 0) {
            const totalPresent = studentStats.present + studentStats.late;
            studentStats.attendanceRate = Math.round(
              (totalPresent / statistics.totalSessions) * 100
            );
          }

          statistics.studentStatistics.push(studentStats);
        }
      }
    } catch (fbError) {
      console.error("Firebase 수업별 출석 통계 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (
      statistics.totalSessions === 0 &&
      process.env.NODE_ENV === "development"
    ) {
      const now = new Date();
      statistics = {
        classId,
        totalSessions: 10,
        totalStudents: 15,
        averageAttendanceRate: 85,
        attendanceByStatus: {
          present: 120,
          late: 15,
          absent: 12,
          excused: 3,
        },
        attendanceByDate: {
          [`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(
            2,
            "0"
          )}-01`]: {
            present: 12,
            late: 2,
            absent: 1,
            excused: 0,
            total: 15,
          },
          [`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(
            2,
            "0"
          )}-08`]: {
            present: 13,
            late: 1,
            absent: 0,
            excused: 1,
            total: 15,
          },
        },
        studentStatistics: [
          {
            studentId: "student1",
            studentName: "이학생",
            present: 9,
            late: 1,
            absent: 0,
            excused: 0,
            attendanceRate: 100,
          },
          {
            studentId: "student2",
            studentName: "박학생",
            present: 7,
            late: 2,
            absent: 1,
            excused: 0,
            attendanceRate: 90,
          },
          {
            studentId: "student3",
            studentName: "김학생",
            present: 6,
            late: 1,
            absent: 2,
            excused: 1,
            attendanceRate: 70,
          },
        ],
      };
    }

    res.status(200).json({
      success: true,
      data: statistics,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("수업별 출석 통계 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 2. 학생별 출석 통계 조회 API
app.get("/api/statistics/students/:studentId/attendance", async (req, res) => {
  try {
    const { studentId } = req.params;
    const { startDate, endDate } = req.query;

    // 필수 파라미터 검증
    if (!studentId) {
      return res.status(400).json({
        success: false,
        error: "학생 ID가 필요합니다.",
      });
    }

    console.log(`학생별 출석 통계 조회 요청: 학생 ID ${studentId}`);

    // 날짜 범위 설정
    let start = startDate ? new Date(startDate) : new Date();
    start.setHours(0, 0, 0, 0);
    start.setMonth(start.getMonth() - 3); // 기본값: 3개월 전

    let end = endDate ? new Date(endDate) : new Date();
    end.setHours(23, 59, 59, 999);

    // Firebase에서 학생별 출석 통계 조회 (선택적)
    let statistics = {
      studentId,
      totalSessions: 0,
      attendanceByStatus: {
        present: 0,
        late: 0,
        absent: 0,
        excused: 0,
      },
      attendanceByClass: {},
      overallAttendanceRate: 0,
    };

    try {
      if (admin.apps.length) {
        // 학생 정보 가져오기
        const userRef = admin.firestore().collection("users").doc(studentId);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
          return res.status(404).json({
            success: false,
            error: "요청한 학생을 찾을 수 없습니다.",
          });
        }

        // 학생이 수강 중인 클래스 목록 가져오기
        const classesRef = admin.firestore().collection("classes");
        const classesSnapshot = await classesRef
          .where("students", "array-contains", studentId)
          .get();

        const classes = [];
        classesSnapshot.forEach((doc) => {
          classes.push({
            id: doc.id,
            ...doc.data(),
          });
        });

        // 각 수업별 출석 세션 가져오기
        let totalPresent = 0;
        let totalLate = 0;
        let totalAbsent = 0;
        let totalExcused = 0;
        let totalSessions = 0;

        for (const classObj of classes) {
          const classId = classObj.id;

          // 세션 목록 가져오기
          const sessionsRef = admin
            .firestore()
            .collection("attendance_sessions");
          const sessionsSnapshot = await sessionsRef
            .where("classId", "==", classId)
            .where("startTime", ">=", admin.firestore.Timestamp.fromDate(start))
            .where("startTime", "<=", admin.firestore.Timestamp.fromDate(end))
            .get();

          const sessions = [];
          sessionsSnapshot.forEach((doc) => {
            sessions.push({
              id: doc.id,
              ...doc.data(),
            });
          });

          // 수업별 통계 초기화
          statistics.attendanceByClass[classId] = {
            className: classObj.name || classId,
            totalSessions: sessions.length,
            present: 0,
            late: 0,
            absent: 0,
            excused: 0,
            attendanceRate: 0,
          };

          totalSessions += sessions.length;

          // 각 세션별 출석 상태 확인
          for (const session of sessions) {
            const attendanceRef = admin
              .firestore()
              .collection("attendance_logs");
            const snapshot = await attendanceRef
              .where("sessionId", "==", session.id)
              .where("studentId", "==", studentId)
              .limit(1)
              .get();

            if (snapshot.empty) {
              // 출석 기록이 없으면 결석으로 처리
              statistics.attendanceByClass[classId].absent++;
              statistics.attendanceByStatus.absent++;
              totalAbsent++;
            } else {
              const data = snapshot.docs[0].data();
              const status = data.status || "absent";

              // 상태별 카운트 증가
              statistics.attendanceByClass[classId][status]++;
              statistics.attendanceByStatus[status]++;

              if (status === "present") totalPresent++;
              else if (status === "late") totalLate++;
              else if (status === "absent") totalAbsent++;
              else if (status === "excused") totalExcused++;
            }
          }

          // 수업별 출석률 계산
          if (statistics.attendanceByClass[classId].totalSessions > 0) {
            const presentAndLate =
              statistics.attendanceByClass[classId].present +
              statistics.attendanceByClass[classId].late;

            statistics.attendanceByClass[classId].attendanceRate = Math.round(
              (presentAndLate /
                statistics.attendanceByClass[classId].totalSessions) *
                100
            );
          }
        }

        statistics.totalSessions = totalSessions;

        // 전체 출석률 계산
        if (totalSessions > 0) {
          statistics.overallAttendanceRate = Math.round(
            ((totalPresent + totalLate) / totalSessions) * 100
          );
        }
      }
    } catch (fbError) {
      console.error("Firebase 학생별 출석 통계 조회 오류:", fbError);
      // Firebase 오류는 무시하고 계속 진행
    }

    // 개발 단계에서 Firebase 연동이 없는 경우 샘플 데이터 반환
    if (
      statistics.totalSessions === 0 &&
      process.env.NODE_ENV === "development"
    ) {
      statistics = {
        studentId,
        totalSessions: 20,
        attendanceByStatus: {
          present: 16,
          late: 2,
          absent: 1,
          excused: 1,
        },
        attendanceByClass: {
          class1: {
            className: "캡스톤 디자인",
            totalSessions: 10,
            present: 8,
            late: 1,
            absent: 0,
            excused: 1,
            attendanceRate: 90,
          },
          class2: {
            className: "데이터베이스",
            totalSessions: 10,
            present: 8,
            late: 1,
            absent: 1,
            excused: 0,
            attendanceRate: 90,
          },
        },
        overallAttendanceRate: 90,
      };
    }

    res.status(200).json({
      success: true,
      data: statistics,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("학생별 출석 통계 조회 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 3. 수업 출석 보고서 생성 API
app.get("/api/reports/classes/:classId", async (req, res) => {
  try {
    const { classId } = req.params;
    const { startDate, endDate, format } = req.query;

    // 필수 파라미터 검증
    if (!classId) {
      return res.status(400).json({
        success: false,
        error: "수업 ID가 필요합니다.",
      });
    }

    console.log(`수업 보고서 생성 요청: 수업 ID ${classId}`);

    // 날짜 범위 설정
    let start = startDate ? new Date(startDate) : new Date();
    start.setHours(0, 0, 0, 0);
    start.setMonth(start.getMonth() - 1); // 기본값: 1개월 전

    let end = endDate ? new Date(endDate) : new Date();
    end.setHours(23, 59, 59, 999);

    // 보고서 형식 설정 (기본값: json)
    const reportFormat = format || "json";

    // Firebase에서 수업 출석 데이터 조회 (통계 API와 유사)
    let report = {
      classId,
      className: "",
      reportGeneratedAt: new Date().toISOString(),
      dateRange: {
        start: start.toISOString(),
        end: end.toISOString(),
      },
      totalSessions: 0,
      totalStudents: 0,
      averageAttendanceRate: 0,
      sessions: [],
      studentStatistics: [],
    };

    // Firebase 또는 개발 모드의 경우 샘플 데이터 설정 (실제 구현은 통계 API와 유사)
    if (process.env.NODE_ENV === "development") {
      report.className = "캡스톤 디자인";
      report.totalSessions = 10;
      report.totalStudents = 15;
      report.averageAttendanceRate = 85;
      report.sessions = [
        {
          sessionId: "session1",
          date: new Date(Date.now() - 86400000 * 7).toISOString(), // 1주일 전
          attendanceStats: { present: 12, late: 2, absent: 1, excused: 0 },
        },
        {
          sessionId: "session2",
          date: new Date(Date.now() - 86400000 * 14).toISOString(), // 2주일 전
          attendanceStats: { present: 13, late: 1, absent: 1, excused: 0 },
        },
      ];
      report.studentStatistics = [
        {
          studentId: "student1",
          studentName: "이학생",
          attendanceRate: 100,
          attendanceByStatus: { present: 9, late: 1, absent: 0, excused: 0 },
        },
        {
          studentId: "student2",
          studentName: "박학생",
          attendanceRate: 90,
          attendanceByStatus: { present: 8, late: 1, absent: 1, excused: 0 },
        },
      ];
    }

    // 보고서 형식에 따른 응답
    if (reportFormat === "csv") {
      // CSV 형식 응답 (예시)
      let csvContent = `수업명: ${report.className}\n`;
      csvContent += `기간: ${report.dateRange.start} ~ ${report.dateRange.end}\n\n`;
      csvContent += "학생ID,학생명,출석률,출석,지각,결석,공결\n";

      report.studentStatistics.forEach((student) => {
        csvContent += `${student.studentId},${student.studentName},${student.attendanceRate}%,`;
        csvContent += `${student.attendanceByStatus.present},${student.attendanceByStatus.late},`;
        csvContent += `${student.attendanceByStatus.absent},${student.attendanceByStatus.excused}\n`;
      });

      res.setHeader("Content-Type", "text/csv");
      res.setHeader(
        "Content-Disposition",
        `attachment; filename=attendance_report_${classId}.csv`
      );
      return res.send(csvContent);
    } else {
      // JSON 기본 응답
      res.status(200).json({
        success: true,
        data: report,
        timestamp: new Date().toISOString(),
      });
    }
  } catch (error) {
    console.error("수업 보고서 생성 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 4. 학생 출석 보고서 생성 API
app.get("/api/reports/students/:studentId", async (req, res) => {
  try {
    const { studentId } = req.params;
    const { startDate, endDate, format } = req.query;

    // 필수 파라미터 검증
    if (!studentId) {
      return res.status(400).json({
        success: false,
        error: "학생 ID가 필요합니다.",
      });
    }

    console.log(`학생 보고서 생성 요청: 학생 ID ${studentId}`);

    // 날짜 범위 설정
    let start = startDate ? new Date(startDate) : new Date();
    start.setHours(0, 0, 0, 0);
    start.setMonth(start.getMonth() - 3); // 기본값: 3개월 전

    let end = endDate ? new Date(endDate) : new Date();
    end.setHours(23, 59, 59, 999);

    // 보고서 형식 설정 (기본값: json)
    const reportFormat = format || "json";

    // Firebase에서 학생 출석 데이터 조회 (통계 API와 유사)
    let report = {
      studentId,
      studentName: "",
      reportGeneratedAt: new Date().toISOString(),
      dateRange: {
        start: start.toISOString(),
        end: end.toISOString(),
      },
      totalSessions: 0,
      overallAttendanceRate: 0,
      attendanceByStatus: {
        present: 0,
        late: 0,
        absent: 0,
        excused: 0,
      },
      classStatistics: [],
    };

    // Firebase 또는 개발 모드의 경우 샘플 데이터 설정 (실제 구현은 통계 API와 유사)
    if (process.env.NODE_ENV === "development") {
      report.studentName = "이학생";
      report.totalSessions = 20;
      report.overallAttendanceRate = 90;
      report.attendanceByStatus = {
        present: 16,
        late: 2,
        absent: 1,
        excused: 1,
      };
      report.classStatistics = [
        {
          classId: "class1",
          className: "캡스톤 디자인",
          attendanceRate: 90,
          attendanceByStatus: { present: 8, late: 1, absent: 0, excused: 1 },
          sessions: [
            {
              sessionId: "session1",
              date: new Date(Date.now() - 86400000 * 7).toISOString(),
              status: "present",
            },
            {
              sessionId: "session2",
              date: new Date(Date.now() - 86400000 * 14).toISOString(),
              status: "late",
            },
          ],
        },
        {
          classId: "class2",
          className: "데이터베이스",
          attendanceRate: 90,
          attendanceByStatus: { present: 8, late: 1, absent: 1, excused: 0 },
          sessions: [
            {
              sessionId: "session3",
              date: new Date(Date.now() - 86400000 * 5).toISOString(),
              status: "present",
            },
            {
              sessionId: "session4",
              date: new Date(Date.now() - 86400000 * 12).toISOString(),
              status: "present",
            },
          ],
        },
      ];
    }

    // 보고서 형식에 따른 응답
    if (reportFormat === "csv") {
      // CSV 형식 응답 (예시)
      let csvContent = `학생명: ${report.studentName}\n`;
      csvContent += `기간: ${report.dateRange.start} ~ ${report.dateRange.end}\n\n`;
      csvContent += "수업명,출석률,출석,지각,결석,공결\n";

      report.classStatistics.forEach((cls) => {
        csvContent += `${cls.className},${cls.attendanceRate}%,`;
        csvContent += `${cls.attendanceByStatus.present},${cls.attendanceByStatus.late},`;
        csvContent += `${cls.attendanceByStatus.absent},${cls.attendanceByStatus.excused}\n`;
      });

      csvContent += `\n전체,${report.overallAttendanceRate}%,`;
      csvContent += `${report.attendanceByStatus.present},${report.attendanceByStatus.late},`;
      csvContent += `${report.attendanceByStatus.absent},${report.attendanceByStatus.excused}\n`;

      res.setHeader("Content-Type", "text/csv");
      res.setHeader(
        "Content-Disposition",
        `attachment; filename=attendance_report_${studentId}.csv`
      );
      return res.send(csvContent);
    } else {
      // JSON 기본 응답
      res.status(200).json({
        success: true,
        data: report,
        timestamp: new Date().toISOString(),
      });
    }
  } catch (error) {
    console.error("학생 보고서 생성 오류:", error);
    res.status(500).json({
      success: false,
      error: `서버 오류가 발생했습니다: ${error.message}`,
    });
  }
});

// 서버 시작
app.listen(PORT, () => {
  console.log(
    `와이파이 CSI 기반 출결 시스템 서버가 포트 ${PORT}에서 실행 중입니다.`
  );
});
