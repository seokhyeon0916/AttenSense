import 'package:cloud_firestore/cloud_firestore.dart';

/// 출석 상태 열거형
enum AttendanceStatus {
  present, // 출석
  late, // 지각
  absent, // 결석
  excused, // 사유 있음
  pending, // 처리 중
}

/// 출석 정보를 관리하는 모델 클래스
class AttendanceModel {
  final String id;
  final String classId;
  final String className;
  final String studentId;
  final String studentName;
  final AttendanceStatus status;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final Map<String, dynamic>? csiData; // Wi-Fi CSI 데이터
  final String? notes;
  final bool captureRequested; // CSI 캡처 요청 여부 필드 추가

  AttendanceModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    this.csiData,
    this.notes,
    this.captureRequested = false, // 기본값은 false
  });

  /// Firestore 문서에서 AttendanceModel 객체를 생성합니다.
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AttendanceModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      status: _parseAttendanceStatus(data['status']),
      date: (data['date'] as Timestamp).toDate(),
      checkInTime: (data['checkInTime'] as Timestamp).toDate(),
      checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
      csiData: data['csiData'],
      notes: data['notes'],
      captureRequested: data['captureRequested'] ?? false,
    );
  }

  /// AttendanceModel 객체를 Firestore 문서 데이터로 변환합니다.
  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'className': className,
      'studentId': studentId,
      'studentName': studentName,
      'status': status.toString().split('.').last,
      'date': Timestamp.fromDate(date),
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime':
          checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'csiData': csiData,
      'notes': notes,
      'captureRequested': captureRequested,
    };
  }

  /// 문자열에서 AttendanceStatus로 변환하는 도우미 함수
  static AttendanceStatus _parseAttendanceStatus(String? statusStr) {
    if (statusStr == null) return AttendanceStatus.pending;

    switch (statusStr) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'absent':
        return AttendanceStatus.absent;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.pending;
    }
  }

  /// 출석 상태를 업데이트하는 복사 생성자
  AttendanceModel copyWith({
    AttendanceStatus? status,
    DateTime? checkOutTime,
    Map<String, dynamic>? csiData,
    String? notes,
    bool? captureRequested,
  }) {
    return AttendanceModel(
      id: id,
      classId: classId,
      className: className,
      studentId: studentId,
      studentName: studentName,
      status: status ?? this.status,
      date: date,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      csiData: csiData ?? this.csiData,
      notes: notes ?? this.notes,
      captureRequested: captureRequested ?? this.captureRequested,
    );
  }
}
