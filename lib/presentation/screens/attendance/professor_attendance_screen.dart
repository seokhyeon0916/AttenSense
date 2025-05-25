import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/widgets/app_button.dart';
import 'package:capston_design/widgets/app_divider.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/domain/entities/session_entity.dart';
import 'package:capston_design/domain/entities/class.dart';
import 'package:capston_design/domain/repositories/attendance_repository.dart';
import 'package:capston_design/domain/repositories/user_repository.dart';
import 'package:capston_design/domain/repositories/class_repository.dart';
import 'package:capston_design/core/dependency_injection.dart' as di;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'attendance_history_screen.dart';
import 'attendance_statistics_screen.dart';
import 'package:capston_design/services/api_service.dart';
import 'package:capston_design/services/attendance_monitoring_service.dart';
import 'package:intl/intl.dart';

/// 교수가 수업 참여 학생들의 출석을 관리하는 화면
class ProfessorAttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ProfessorAttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ProfessorAttendanceScreen> createState() =>
      _ProfessorAttendanceScreenState();
}

class _ProfessorAttendanceScreenState extends State<ProfessorAttendanceScreen> {
  bool _isClassStarted = false;
  DateTime? _classStartTime;
  String? _activeSessionId;
  StreamSubscription? _attendanceSubscription;
  bool _isLoading = false;
  Timer? _attendanceTimeUpdateTimer; // 출석 시간 업데이트를 위한 타이머 추가

  // Snackbar가 표시되는지 여부를 추적하는 변수
  bool _isSnackbarVisible = false;

  // API 서비스 인스턴스
  final ApiService _apiService = ApiService();

  // Repository 인스턴스 - 의존성 주입 사용
  late final UserRepository _userRepository;
  late final ClassRepository _classRepository;

  // 학생 데이터 리스트
  final List<Map<String, dynamic>> _students = [];

  // 수업 목록 및 현재 선택된 수업
  List<Class> _classes = [];
  String _selectedClassId = '';
  String _selectedClassName = '';

  @override
  void initState() {
    super.initState();
    _initRepositories();

    // API 서비스를 Firebase 전용 모드로 초기화
    ApiService.init(
      serverUrl: 'https://csi-server-696186584116.asia-northeast3.run.app',
      useServerApi: false, // 서버 API 비활성화하여 Firebase만 사용
    );

    // 초기에는 위젯에서 전달받은 수업 ID와 이름 사용
    _selectedClassId = widget.classId;
    _selectedClassName = widget.className;
    _loadClasses();
    _loadStudentsForClass(_selectedClassId);
    _checkActiveSession();
  }

  void _initRepositories() {
    _userRepository = di.sl<UserRepository>();
    _classRepository = ClassRepositoryImpl();
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    _attendanceTimeUpdateTimer?.cancel(); // 타이머 정리
    super.dispose();
  }

  // 교수의 모든 수업 목록 로드
  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        debugPrint('사용자 정보를 불러올 수 없습니다.');
        return;
      }

      // 교수의 수업 목록 가져오기
      final classesResult = await _classRepository.getClassesByProfessorId(
        currentUser.id,
      );

      classesResult.fold(
        (failure) {
          debugPrint('수업 목록 조회 실패: ${failure.message}');
          _showSnackBar('수업 목록을 불러올 수 없습니다: ${failure.message}', Colors.red);
        },
        (classes) {
          setState(() {
            _classes = classes;
            // 수업 목록이 비어있지 않다면 전달받은 수업 ID가 유효한지 확인
            if (_classes.isNotEmpty) {
              // 선택된 수업이 목록에 없다면 첫 번째 수업 선택
              if (!_classes.any((c) => c.id == _selectedClassId)) {
                _selectedClassId = _classes.first.id;
                _selectedClassName = _classes.first.name;
                _loadStudentsForClass(_selectedClassId);
              }
            }
          });
        },
      );
    } catch (e) {
      debugPrint('수업 목록 불러오기 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 수업 변경 시 해당 수업의 학생 목록 로드
  void _onClassChanged(String classId, String className) {
    setState(() {
      _selectedClassId = classId;
      _selectedClassName = className;
      // 기존 학생 목록 초기화
      _students.clear();
    });

    // 선택한 수업의 학생 목록 로드
    _loadStudentsForClass(classId);
    // 선택한 수업의 활성 세션 확인
    _checkActiveSession();
  }

  // Firebase에서 수업에 등록된 학생 목록을 가져오는 함수
  Future<void> _loadStudentsForClass(String classId) async {
    setState(() {
      _isLoading = true;
      // 기존 학생 목록 초기화
      _students.clear();
    });

    try {
      // 1. 수업 정보를 가져와서 학생 ID 목록 확인
      final classResult = await _classRepository.getClassById(classId);

      classResult.fold(
        (failure) {
          debugPrint('수업 정보 조회 실패: ${failure.message}');
          _showSnackBar('수업 정보를 불러올 수 없습니다: ${failure.message}', Colors.red);
        },
        (classData) async {
          if (classData == null) {
            debugPrint('존재하지 않는 수업입니다: $classId');
            return;
          }

          // 수업에 등록된 학생 ID 목록
          final studentIds = classData.studentIds;

          if (studentIds.isEmpty) {
            debugPrint('수업에 등록된 학생이 없습니다');
            setState(() {
              _isLoading = false;
            });
            return;
          }

          // 2. 각 학생 ID에 대한 사용자 정보 조회
          for (final studentId in studentIds) {
            final userResult = await _userRepository.getUserById(studentId);

            userResult.fold(
              (failure) {
                debugPrint('학생 정보 조회 실패: ${failure.message}');
              },
              (user) {
                if (user != null) {
                  if (mounted) {
                    setState(() {
                      _students.add({
                        'id': user.id,
                        'name': user.name,
                        'studentId': studentId, // 학번 대신 학생 ID 사용
                        'isPresent': false,
                        'isActive': false,
                        'lastActiveTime': null,
                        'attendanceDuration': 0,
                      });
                    });
                  }
                }
              },
            );
          }
        },
      );
    } catch (e) {
      debugPrint('학생 목록 불러오기 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 출석 시간 업데이트를 위한 타이머 설정
  void _startAttendanceDurationTimer() {
    _attendanceTimeUpdateTimer?.cancel();
    _attendanceTimeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (
      _,
    ) {
      if (mounted && _isClassStarted) {
        setState(() {
          // 출석한 학생들의 출석 시간을 1분씩 증가
          for (var student in _students) {
            if (student['isPresent'] == true) {
              student['attendanceDuration'] = student['attendanceDuration'] + 1;
            }
          }
        });
      }
    });
  }

  // 활성 세션이 있는지 확인하고 있으면 출석 상태 리스닝 시작
  Future<void> _checkActiveSession() async {
    try {
      final attendanceRepo = AttendanceRepositoryImpl();
      final result = await attendanceRepo.getActiveSession(_selectedClassId);

      result.fold(
        (failure) {
          // 활성 세션이 없음
          setState(() {
            _isClassStarted = false;
            _classStartTime = null;
            _activeSessionId = null;
          });
        },
        (activeSession) {
          // 활성 세션이 있음
          setState(() {
            _isClassStarted = true;
            _classStartTime = activeSession.startTime;
            _activeSessionId = activeSession.id;
          });

          // 출석 상태 리스닝 시작
          _startListeningAttendance(activeSession.id);
          _startAttendanceDurationTimer(); // 출석 시간 타이머 시작
        },
      );
    } catch (e) {
      debugPrint('활성 세션 확인 중 오류 발생: $e');
    }
  }

  // 학생들의 출석 상태를 실시간으로 리스닝
  void _startListeningAttendance(String sessionId) {
    try {
      // Firestore 컬렉션 직접 구독
      _attendanceSubscription = FirebaseFirestore.instance
          .collection('attendances')
          .where('sessionId', isEqualTo: sessionId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isEmpty) return;

              final updatedStudents = List<Map<String, dynamic>>.from(
                _students,
              );

              for (final doc in snapshot.docs) {
                final attendance = doc.data();
                final studentId = attendance['studentId'] as String;
                final isPresent = attendance['status'] == 'present';
                final status = attendance['status'] as String;
                final predictionResult =
                    attendance['predictionResult'] as String? ?? 'unknown';
                final lastActiveTime =
                    attendance['lastUpdated'] != null
                        ? (attendance['lastUpdated'] as Timestamp).toDate()
                        : null;
                final recordedTime =
                    attendance['recordedTime'] != null
                        ? (attendance['recordedTime'] as Timestamp).toDate()
                        : null;

                // CSI 예측 결과에 따른 활동 상태
                final isActive = predictionResult.toLowerCase() == 'sitdown';

                // 해당 학생 찾기
                final studentIndex = updatedStudents.indexWhere(
                  (s) => s['id'] == studentId,
                );

                if (studentIndex != -1) {
                  // 학생이 처음 출석했을 때만 lastActiveTime 설정
                  final bool wasPresent =
                      updatedStudents[studentIndex]['isPresent'] as bool;

                  // 학생 정보 업데이트
                  updatedStudents[studentIndex]['isPresent'] = isPresent;
                  updatedStudents[studentIndex]['isActive'] = isActive;
                  updatedStudents[studentIndex]['predictionResult'] =
                      predictionResult;

                  // 출석 시간 설정
                  if (!wasPresent && isPresent) {
                    // 처음 출석한 경우
                    updatedStudents[studentIndex]['lastActiveTime'] =
                        recordedTime;
                    updatedStudents[studentIndex]['attendanceDuration'] = 0;
                  } else if (isActive && lastActiveTime != null) {
                    // 활동 중인 경우 lastActiveTime 업데이트
                    updatedStudents[studentIndex]['lastActiveTime'] =
                        lastActiveTime;
                  }
                }
              }

              // UI 업데이트
              setState(() {
                for (int i = 0; i < _students.length; i++) {
                  final studentIndex = updatedStudents.indexWhere(
                    (s) => s['id'] == _students[i]['id'],
                  );

                  if (studentIndex != -1) {
                    _students[i]['isPresent'] =
                        updatedStudents[studentIndex]['isPresent'];
                    _students[i]['isActive'] =
                        updatedStudents[studentIndex]['isActive'];
                    _students[i]['lastActiveTime'] =
                        updatedStudents[studentIndex]['lastActiveTime'];
                    _students[i]['predictionResult'] =
                        updatedStudents[studentIndex]['predictionResult'];

                    // 출석 중인지 확인 후 출석 시간 복사
                    if (updatedStudents[studentIndex]['isPresent']) {
                      _students[i]['attendanceDuration'] =
                          updatedStudents[studentIndex]['attendanceDuration'];
                    }
                  }
                }
              });
            },
            onError: (error) {
              debugPrint('출석 데이터 리스닝 중 오류 발생: $error');
            },
          );
    } catch (e) {
      debugPrint('출석 리스너 설정 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 타이틀을 드롭다운 버튼으로 변경
        title: _buildClassDropdown(),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showAttendanceStatistics,
            tooltip: '출석 통계',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildClassStatusCard(),
              Expanded(child: _buildStudentList()),
            ],
          ),
          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: AnimatedPadding(
        padding: EdgeInsets.only(bottom: _isSnackbarVisible ? 60.0 : 0),
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed:
              _isLoading ? null : (_isClassStarted ? _endClass : _startClass),
          backgroundColor:
              _isClassStarted ? AppColors.errorColor : AppColors.successColor,
          child: Icon(
            _isClassStarted ? Icons.stop : Icons.play_arrow,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 수업 선택 드롭다운 위젯
  Widget _buildClassDropdown() {
    // 수업 목록이 없는 경우 일반 텍스트 표시
    if (_classes.isEmpty) {
      return Text(_selectedClassName);
    }

    return DropdownButton<String>(
      value: _selectedClassId,
      icon: const Icon(Icons.arrow_drop_down),
      elevation: 16,
      style: AppTypography.headline3(context),
      underline: Container(), // 밑줄 제거
      onChanged: (String? newValue) {
        if (newValue != null) {
          // 선택된 수업 이름 찾기
          final selectedClass = _classes.firstWhere((c) => c.id == newValue);
          _onClassChanged(newValue, selectedClass.name);
        }
      },
      items:
          _classes.map<DropdownMenuItem<String>>((Class classItem) {
            return DropdownMenuItem<String>(
              value: classItem.id,
              child: Text(
                classItem.name,
                style: TextStyle(
                  color:
                      _selectedClassId == classItem.id
                          ? AppColors.primaryColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildClassStatusCard() {
    return AppCard(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('출석 현황', style: AppTypography.headline3(context)),
                  AppSpacing.verticalSpaceSM,
                  Text(
                    _isClassStarted ? '수업 중: ${_getElapsedTime()}' : '수업 시작 전',
                    style: AppTypography.body(context).copyWith(
                      color:
                          _isClassStarted
                              ? AppColors.successColor
                              : Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              _buildStatistics(),
            ],
          ),
          AppSpacing.verticalSpaceMD,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: '출석 목록 갱신',
                  icon: Icons.refresh,
                  type: ButtonType.secondary,
                  onPressed: _refreshAttendance,
                ),
              ),
              AppSpacing.horizontalSpaceSM,
              Expanded(
                child: AppButton(
                  text: '모든 학생에게 알림',
                  icon: Icons.notifications,
                  type: ButtonType.primary,
                  onPressed: _sendNotificationToAll,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    // 출석 통계 계산
    final totalStudents = _students.length;
    final presentStudents =
        _students.where((s) => s['isPresent'] as bool).length;
    final activeStudents = _students.where((s) => s['isActive'] as bool).length;

    return Row(
      children: [
        _buildStatisticItem(
          '$presentStudents/$totalStudents',
          '출석',
          AppColors.successColor,
        ),
        AppSpacing.horizontalSpaceSM,
        _buildStatisticItem(
          '$activeStudents/$presentStudents',
          '활동',
          AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildStatisticItem(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.subhead(context).copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.small(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _students.length,
      separatorBuilder: (_, __) => AppSpacing.verticalSpaceSM,
      itemBuilder: (context, index) {
        final student = _students[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final bool isPresent = student['isPresent'] as bool;
    final bool isActive = student['isActive'] as bool;
    final DateTime? lastActiveTime = student['lastActiveTime'] as DateTime?;

    // 예측 결과 및 상태 추출
    final String predictionResult =
        student['predictionResult'] as String? ?? 'unknown';
    final bool isSitdown = predictionResult.toLowerCase() == 'sitdown';

    // null-safe하게 처리
    final int attendanceDuration =
        (student['attendanceDuration'] == null)
            ? 0
            : (student['attendanceDuration'] as int);

    // 상태에 따른 색상 설정
    final Color statusColor =
        !isPresent
            ? AppColors
                .errorColor // 미출석: 빨간색
            : isSitdown
            ? AppColors
                .successColor // 출석중(sitdown): 초록색
            : AppColors.warningColor; // 공석(empty): 노란색

    // 상태 텍스트 설정
    final String statusText =
        !isPresent
            ? '미출석'
            : isSitdown
            ? '출석중' // sitdown
            : '공석'; // empty

    // 출석 시간 텍스트 (출석한 경우에만 표시)
    final String durationText = isPresent ? '$attendanceDuration분' : '';

    // 마지막 활동 시간
    final String timeText =
        lastActiveTime != null ? '마지막 활동: ${_formatTime(lastActiveTime)}' : '';

    // 예측 결과 표시
    final String predictionText = isPresent ? '예측 결과: $predictionResult' : '';

    return AppCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            !isPresent
                ? Icons.person_off
                : isSitdown
                ? Icons.person
                : Icons.person_outline,
            color: statusColor,
          ),
        ),
        title: Text(student['name'], style: AppTypography.subhead(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  statusText,
                  style: AppTypography.small(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.bold),
                ),
                if (isPresent)
                  Text(
                    ' $durationText',
                    style: AppTypography.small(
                      context,
                    ).copyWith(color: statusColor),
                  ),
              ],
            ),
            if (predictionText.isNotEmpty)
              Text(
                predictionText,
                style: AppTypography.small(context).copyWith(
                  fontStyle: FontStyle.italic,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
              ),
            if (timeText.isNotEmpty)
              Text(timeText, style: AppTypography.small(context)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleStudentAction(value, student),
          itemBuilder:
              (context) => [
                const PopupMenuItem<String>(
                  value: 'status',
                  child: Text('출석 상태 변경'),
                ),
                const PopupMenuItem<String>(
                  value: 'notify',
                  child: Text('알림 보내기'),
                ),
                const PopupMenuItem<String>(
                  value: 'details',
                  child: Text('상세 정보'),
                ),
              ],
        ),
        onTap: () => _showStudentDetails(student),
      ),
    );
  }

  void _startClass() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      _showSnackBar('사용자 정보를 불러올 수 없습니다.', AppColors.errorColor);
      return;
    }

    try {
      // 로딩 상태 설정
      setState(() {
        _isLoading = true;
      });

      // 1. 서버 API 호출 - 수업 시작 및 캡처 시작 요청
      final apiResponse = await _apiService.startClass(
        classId: _selectedClassId,
        className: _selectedClassName,
        professorId: currentUser.id,
      );

      // 2. 세션 생성 (기존 코드)
      final attendanceRepo = AttendanceRepositoryImpl();
      final sessionEntity = SessionEntity(
        id: '', // Firestore에서 자동 생성됨
        classId: _selectedClassId,
        professorId: currentUser.id,
        startTime: DateTime.now(),
        isActive: true,
        studentCount: _students.length,
        attendanceStatusMap: {}, // 초기에는 빈 맵으로 시작
      );

      // 3. Firestore에 세션 저장
      final result = await attendanceRepo.createSession(sessionEntity);

      result.fold(
        (failure) {
          _showSnackBar('수업 시작 실패: ${failure.message}', AppColors.errorColor);
        },
        (sessionId) {
          setState(() {
            _isClassStarted = true;
            _classStartTime = DateTime.now();
            _activeSessionId = sessionId;
          });

          // 출석 상태 리스닝 시작
          _startListeningAttendance(sessionId);
          _startAttendanceDurationTimer(); // 출석 시간 타이머 시작

          _showSnackBar(
            apiResponse['message'] ?? '수업이 시작되었습니다. 학생들에게 알림이 전송됩니다.',
            AppColors.successColor,
          );

          // TODO: FCM을 통해 학생들에게 알림 전송 (향후 구현)
        },
      );
    } catch (e) {
      _showSnackBar('수업 시작 중 오류가 발생했습니다: $e', AppColors.errorColor);
    } finally {
      // 로딩 상태 해제
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _endClass() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('수업 종료'),
            content: const Text('정말 수업을 종료하시겠습니까? 학생들의 출석 정보가 저장됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  try {
                    if (_activeSessionId != null) {
                      // 로딩 상태 설정
                      setState(() {
                        _isLoading = true;
                      });

                      // 1. 서버 API 호출 - 수업 종료 및 캡처 종료 요청
                      final apiResponse = await _apiService.endClass(
                        sessionId: _activeSessionId!,
                        classId: _selectedClassId,
                      );

                      // 2. Firebase 세션 종료 처리
                      final attendanceRepo = AttendanceRepositoryImpl();
                      final endResult = await attendanceRepo.endSession(
                        _activeSessionId!,
                      );

                      endResult.fold(
                        (failure) {
                          _showSnackBar(
                            '수업 종료 실패: ${failure.message}',
                            AppColors.errorColor,
                          );
                        },
                        (_) {
                          // 구독 취소
                          _attendanceSubscription?.cancel();
                          _attendanceTimeUpdateTimer?.cancel(); // 타이머 정리

                          setState(() {
                            _isClassStarted = false;
                            _classStartTime = null;
                            _activeSessionId = null;

                            // 학생들 상태 초기화 (모두 미출석으로)
                            for (final student in _students) {
                              student['isPresent'] = false;
                              student['isActive'] = false;
                              student['lastActiveTime'] = null;
                              student['attendanceDuration'] = 0; // 출석 시간 초기화
                            }
                          });

                          _showSnackBar(
                            apiResponse['message'] ??
                                '수업이 종료되었습니다. 출석 정보가 저장되었습니다.',
                            AppColors.primaryColor,
                          );
                        },
                      );
                    } else {
                      _showSnackBar('활성 세션을 찾을 수 없습니다.', AppColors.errorColor);
                    }
                  } catch (e) {
                    _showSnackBar(
                      '수업 종료 중 오류가 발생했습니다: $e',
                      AppColors.errorColor,
                    );
                  } finally {
                    // 로딩 상태 해제
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: const Text('종료'),
              ),
            ],
          ),
    );
  }

  void _refreshAttendance() {
    // 출석 정보를 수동으로 갱신 (이미 실시간 리스너가 작동 중이지만 이 메서드로도 갱신 가능)
    if (_activeSessionId != null) {
      _showSnackBar('출석 정보를 갱신 중입니다...', AppColors.primaryColor);

      // 리스너를 재시작하여 강제 갱신
      _attendanceSubscription?.cancel();
      _startListeningAttendance(_activeSessionId!);
    } else {
      _showSnackBar('활성화된 수업이 없습니다. 먼저 수업을 시작해주세요.', AppColors.warningColor);
    }
  }

  void _sendNotificationToAll() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('전체 알림 전송'),
            content: const TextField(
              decoration: InputDecoration(
                hintText: '전송할 메시지를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSnackBar('모든 학생에게 알림이 전송되었습니다.', AppColors.successColor);
                },
                child: const Text('전송'),
              ),
            ],
          ),
    );
  }

  void _showAttendanceHistory() {
    // 출석 기록 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AttendanceHistoryScreen(
              classId: _selectedClassId,
              className: _selectedClassName,
            ),
      ),
    );
  }

  void _showAttendanceStatistics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AttendanceStatisticsScreen(
              classId: _selectedClassId,
              className: _selectedClassName,
            ),
      ),
    );
  }

  void _handleStudentAction(String action, Map<String, dynamic> student) {
    switch (action) {
      case 'status':
        _changeStudentStatus(student);
        break;
      case 'notify':
        _sendNotificationToStudent(student);
        break;
      case 'details':
        _showStudentDetails(student);
        break;
    }
  }

  void _changeStudentStatus(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${student['name']}의 출석 상태 변경'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('출석'),
                  leading: Radio<bool>(
                    value: true,
                    groupValue: student['isPresent'],
                    onChanged: (value) {
                      Navigator.of(context).pop();
                      setState(() {
                        student['isPresent'] = true;
                        student['isActive'] = true;
                        student['lastActiveTime'] = DateTime.now();
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('결석'),
                  leading: Radio<bool>(
                    value: false,
                    groupValue: student['isPresent'],
                    onChanged: (value) {
                      Navigator.of(context).pop();
                      setState(() {
                        student['isPresent'] = false;
                        student['isActive'] = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _sendNotificationToStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${student['name']}에게 알림 전송'),
            content: const TextField(
              decoration: InputDecoration(
                hintText: '전송할 메시지를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSnackBar(
                    '${student['name']}에게 알림이 전송되었습니다.',
                    AppColors.successColor,
                  );
                },
                child: const Text('전송'),
              ),
            ],
          ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    // 학생 상세 정보 화면으로 이동 (향후 구현)
    _showSnackBar(
      '${student['name']}의 상세 정보 기능은 아직 개발 중입니다.',
      AppColors.warningColor,
    );
  }

  String _getElapsedTime() {
    if (_classStartTime == null) return '';

    final duration = DateTime.now().difference(_classStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '${hours > 0 ? '$hours시간 ' : ''}$minutes분';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Snackbar 표시 함수
  void _showSnackBar(String message, Color backgroundColor) {
    // Snackbar가 표시됨을 기록
    setState(() {
      _isSnackbarVisible = true;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.fixed, // 하단에 고정 표시
          duration: const Duration(seconds: 3),
          onVisible: () {
            // Snackbar가 표시되었을 때
            setState(() {
              _isSnackbarVisible = true;
            });
          },
        ),
      ).closed.then((_) {
        // Snackbar가 닫혔을 때
        if (mounted) {
          setState(() {
            _isSnackbarVisible = false;
          });
        }
      });
  }
}
