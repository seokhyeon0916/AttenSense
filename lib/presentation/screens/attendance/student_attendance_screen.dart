import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/widgets/app_button.dart';
import 'package:capston_design/widgets/app_divider.dart';
import 'package:capston_design/domain/repositories/attendance_repository.dart';
import 'package:capston_design/domain/repositories/class_repository.dart';
import 'package:capston_design/domain/entities/class.dart';
import 'package:capston_design/domain/entities/attendance_entity.dart'
    as entity;
import 'package:capston_design/domain/entities/activity_log.dart';
import 'package:capston_design/domain/models/attendance_model.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'attendance_history_screen.dart';
import 'package:capston_design/services/api_service.dart';
import 'package:capston_design/services/attendance_monitoring_service.dart';
import 'package:capston_design/core/dependency_injection.dart' as di;
import 'package:flutter/services.dart';

/// 학생이 수업에 참여하고 출석을 확인하는 화면
class StudentAttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;

  const StudentAttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with WidgetsBindingObserver {
  bool _isClassActive = false;
  bool _isAttendanceChecked = false;
  String _attendanceStatus = '출석안함';
  DateTime? _lastCheckTime;
  String? _activeSessionId;
  StreamSubscription? _sessionSubscription; // Firestore 리스너 구독 관리
  bool _isLoading = false; // 로딩 상태 추가
  Timer? _activityUpdateTimer; // 활동 상태 업데이트 타이머 추가
  Timer? _refreshTimer; // 자동 새로고침 타이머
  final bool _isRefreshing = false; // 새로고침 중 상태 추적

  // 최초 앱 실행 여부를 추적하는 플래그 추가
  bool _isInitialLoad = true;

  // 마지막으로 알림을 표시한 세션 ID를 추적
  String? _lastNotifiedSessionId;

  // Snackbar가 표시되는지 여부를 추적하는 변수
  bool _isSnackbarVisible = false;

  // 클래스 선택 관련 변수
  String _selectedClassId = '';
  String _selectedClassName = '';
  final List<Map<String, dynamic>> _classes = [];
  late final ClassRepository _classRepository;

  // API 서비스 인스턴스
  final ApiService _apiService = ApiService();

  // 활동 로그를 위한 리스트
  final List<Map<String, dynamic>> _activityLogs = [];

  // 마지막 새로고침 시간을 추적하기 위한 클래스 변수
  static DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 앱 생명주기 관찰자 등록

    _selectedClassId = widget.classId;
    _selectedClassName = widget.className;
    _classRepository = di.sl<ClassRepository>();

    debugPrint(
      'StudentAttendanceScreen 초기화: 수업 ID $_selectedClassId, 수업명 $_selectedClassName',
    );

    // 출석 상태 명시적 초기화
    _isClassActive = false;
    _isAttendanceChecked = false;
    _attendanceStatus = '수업시작전';
    _lastCheckTime = null;
    _activeSessionId = null;

    // API 서비스 초기화 - 서버 URL 설정
    ApiService.init(
      serverUrl: 'https://csi-server-696186584116.asia-northeast3.run.app',
      useServerApi: true,
    );

    // 최초 시작 시에는 알림 없이 상태만 로드
    _isInitialLoad = true;

    _loadClasses();
    _checkClassStatus();
    _setupSessionListener(); // 실시간 수업 상태 리스너 설정

    // 정기적인 상태 새로고침 설정 (1분마다)
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isRefreshing && mounted) {
        _refreshAttendanceStatus();
      }
    });

    // 3초 후에 초기 로드 플래그를 false로 설정
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          debugPrint('초기 로드 상태 해제됨: _isInitialLoad = $_isInitialLoad');
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 앱 생명주기 관찰자 제거
    // 구독 해제
    _sessionSubscription?.cancel();
    _activityUpdateTimer?.cancel(); // 타이머 구독 해제
    _refreshTimer?.cancel(); // 새로고침 타이머 취소
    super.dispose();
  }

  // 앱 상태 변경 감지 (포그라운드로 돌아올 때)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아오면 상태 갱신
      debugPrint('앱이 포그라운드로 돌아왔습니다. 상태 즉시 갱신 중...');

      // 세션 상태를 완전히 초기화
      setState(() {
        // _activeSessionId는 유지하되 출석 상태만 초기화하여 새로운 세션 감지를 빠르게 함
        _isInitialLoad = false; // 앱이 이미 초기화되었으므로 초기 로드 상태가 아님
      });

      // 세션 리스너 재설정 - 완전히 다시 설정하여 최신 상태 보장
      _sessionSubscription?.cancel();
      _setupSessionListener();

      // 상태 즉시 갱신 - 병렬로 처리하여 UI 반응성 유지
      // 1. 먼저 Firebase에서 직접 세션 상태 확인 (비동기 처리 중에 즉시 UI에 반영)
      FirebaseFirestore.instance
          .collection('sessions')
          .where('classId', isEqualTo: _selectedClassId)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get()
          .then((snapshot) {
            if (mounted) {
              if (snapshot.docs.isEmpty) {
                // 활성 세션 없음
                setState(() {
                  _isClassActive = false;
                  _attendanceStatus = '수업시작전';
                });
                debugPrint('포그라운드 전환 - 직접 쿼리: 활성 세션 없음');
              } else {
                // 활성 세션 있음
                final sessionDoc = snapshot.docs.first;
                final sessionId = sessionDoc.id;
                final bool isNewSession = sessionId != _activeSessionId;
                final startTime =
                    (sessionDoc.data()['startTime'] as Timestamp).toDate();

                setState(() {
                  _isClassActive = true;
                  _activeSessionId = sessionId;

                  if (isNewSession) {
                    _isAttendanceChecked = false;
                    _attendanceStatus = '출석안함';
                  }
                });

                debugPrint(
                  '포그라운드 전환 - 직접 쿼리: 활성 세션 발견 $sessionId, 시작 시간: $startTime, 새 세션: $isNewSession',
                );

                // 새 세션이거나 10분 이내 시작된 세션이면 알림 표시
                final now = DateTime.now();
                if (isNewSession && now.difference(startTime).inMinutes <= 10) {
                  _showSessionStartedNotification();
                  // 세션 시작 시간 체크 및 출석 상태 안내
                  _checkSessionStartDuration(sessionId, startTime);
                }
              }
            }
          })
          .catchError((e) => debugPrint('포그라운드 전환 직접 쿼리 오류: $e'));

      // 2. 전체 상태 갱신 프로세스 실행 (UI 업데이트 우선순위 높임)
      Future.microtask(() async {
        if (mounted) {
          await _refreshAttendanceStatus();

          // 디버그 로그 추가
          debugPrint(
            '포그라운드 전환 후 전체 상태 갱신 완료: 수업활성=$_isClassActive, 출석상태=$_attendanceStatus, 세션ID=$_activeSessionId',
          );
        }
      });
    } else if (state == AppLifecycleState.inactive) {
      // 앱이 비활성화될 때 (다른 앱으로 전환, 알림 드롭다운 등)
      debugPrint('앱이 비활성화 상태로 전환되었습니다.');
    } else if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 갈 때
      debugPrint('앱이 백그라운드 상태로 전환되었습니다.');
    } else if (state == AppLifecycleState.detached) {
      // 앱이 완전히 종료될 때
      debugPrint('앱이 종료되고 있습니다.');
    }
  }

  // 학생이 수강 중인 클래스 목록 로드
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

      // 학생의 수업 목록 가져오기
      final classesResult = await _classRepository.getClassesByStudentId(
        currentUser.id,
      );

      classesResult.fold(
        (failure) {
          debugPrint('수업 목록 조회 실패: ${failure.message}');
          _showSnackBar(
            '수업 목록을 불러올 수 없습니다: ${failure.message}',
            AppColors.errorColor,
          );
        },
        (classList) {
          setState(() {
            _classes.clear();
            // Class 객체를 Map으로 변환하여 _classes 리스트에 추가
            for (final classObj in classList) {
              _classes.add({'id': classObj.id, 'name': classObj.name});
            }

            // 현재 선택된 클래스가 목록에 없으면 첫 번째 클래스 선택
            if (!_classes.any((c) => c['id'] == _selectedClassId) &&
                _classes.isNotEmpty) {
              _selectedClassId = _classes.first['id'] as String;
              _selectedClassName = _classes.first['name'] as String;
              _resetAttendanceState();
              _checkClassStatus();
            }
          });
        },
      );
    } catch (e) {
      debugPrint('수업 목록 불러오기 중 오류 발생: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 클래스 변경 시 호출되는 함수
  void _onClassChanged(String classId) {
    final selectedClass = _classes.firstWhere(
      (c) => c['id'] == classId,
      orElse: () => {'id': classId, 'name': '알 수 없는 수업'},
    );

    setState(() {
      _selectedClassId = classId;
      _selectedClassName = selectedClass['name'] as String;

      // 출석 상태 초기화 및 세션 리스너 재설정
      _resetAttendanceState();
    });

    // 세션 리스너 초기화 및 클래스 상태 확인
    _sessionSubscription?.cancel();
    _checkClassStatus();
    _setupSessionListener();
  }

  // 출석 상태 초기화
  void _resetAttendanceState() {
    setState(() {
      _isClassActive = false;
      _isAttendanceChecked = false;
      _attendanceStatus = '출석안함';
      _lastCheckTime = null;
      _activeSessionId = null;
      _activityLogs.clear();
    });
  }

  // 교수가 시작한 활성 세션이 있는지 확인
  Future<void> _checkClassStatus() async {
    // 교수가 시작한 활성 세션이 있는지 확인
    try {
      final attendanceRepo = AttendanceRepositoryImpl();
      final result = await attendanceRepo.getActiveSession(_selectedClassId);

      result.fold(
        (failure) {
          // 활성 세션이 없으면 수업이 시작되지 않은 것으로 처리
          if (mounted) {
            setState(() {
              _isClassActive = false;
              _attendanceStatus = '수업시작전';
              _isAttendanceChecked = false; // 출석 상태 초기화
              _lastCheckTime = null;
            });
          }
        },
        (activeSession) {
          // 활성 세션이 있으면 수업이 시작된 것으로 처리
          final bool isNewSession = _activeSessionId != activeSession.id;

          if (mounted) {
            setState(() {
              _isClassActive = true;
              _activeSessionId = activeSession.id;

              // 새 세션이거나 이전에 수업이 시작되지 않았다면 출석 상태 초기화
              if (isNewSession) {
                _attendanceStatus =
                    '출석안함'; // 수업이 시작되었지만 아직 출석 체크 전이므로 '출석안함'으로 설정
                _isAttendanceChecked = false; // 새 세션 시작 시 출석 체크 상태 초기화
              }
            });
          }

          // 새 세션이면서 초기 로드 상태가 아닐 때만 세션 시작 알림 표시
          if (isNewSession && !_isInitialLoad && mounted) {
            _showSessionStartedNotification();
            // 알림을 표시한 세션 ID 저장
            setState(() {
              _lastNotifiedSessionId = activeSession.id;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('수업 상태 확인 중 오류 발생: $e');
    }
  }

  // 실시간 수업 상태 감지를 위한 리스너 설정 최적화
  void _setupSessionListener() {
    // 기존 구독이 있으면 취소
    _sessionSubscription?.cancel();

    try {
      debugPrint('세션 리스너 설정 중... 수업 ID: $_selectedClassId');

      // Firestore 쿼리 최적화 - 세션 정보를 가져오는 쿼리
      final sessionsRef = FirebaseFirestore.instance
          .collection('sessions')
          .where('classId', isEqualTo: _selectedClassId)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .limit(1);

      // 세션 변화 첫 감지 여부를 추적하는 변수 (초기 로드와 구분하기 위함)
      bool isFirstSnapshot = true;

      // Firestore 실시간 리스너 설정 - 메타데이터 변경 포함하여 모든 변경 감지
      _sessionSubscription = sessionsRef
          .snapshots(
            includeMetadataChanges: true, // 메타데이터 변경도 감지하여 실시간성 향상
          )
          .listen(
            (snapshot) {
              // 원격 서버에서 최신 데이터를 가져오기 위한 처리
              // hasPendingWrites 검사는 로컬 변경 사항이 있을 때만 해당됨 (서버 변경은 감지하지 못함)
              // 따라서 이 검사는 제거하고 항상 스냅샷을 처리하도록 변경
              /*
              if (snapshot.metadata.hasPendingWrites) {
                debugPrint('로컬 캐시 변경 감지됨, 서버 확인 대기 중...');
                return;
              }
              */

              // 대신 로그에 스냅샷 출처 기록
              debugPrint(
                '세션 스냅샷 수신: ${snapshot.docs.length}개의 세션, 원본: ${snapshot.metadata.isFromCache ? "캐시" : "서버"}, 초기 로드: $_isInitialLoad, hasPendingWrites: ${snapshot.metadata.hasPendingWrites}',
              );

              // 첫 번째 스냅샷인 경우 (앱 시작 시 초기 상태 로드)
              if (isFirstSnapshot) {
                isFirstSnapshot = false;

                // 첫 스냅샷에서는 상태만 업데이트하고 알림은 표시하지 않음
                if (snapshot.docs.isEmpty) {
                  // 활성 세션 없음 - 상태만 업데이트
                  if (mounted) {
                    setState(() {
                      _isClassActive = false;
                      _attendanceStatus = '수업시작전';
                      _activeSessionId = null;
                    });
                  }
                } else {
                  // 활성 세션 있음 - 상태만 업데이트
                  final sessionDoc = snapshot.docs.first;
                  final sessionId = sessionDoc.id;

                  if (mounted) {
                    setState(() {
                      _isClassActive = true;
                      _activeSessionId = sessionId;
                      _lastNotifiedSessionId = sessionId; // 알림 중복 방지를 위해 저장

                      // 출석 상태가 아직 초기화되지 않았다면 설정
                      if (_attendanceStatus == '수업시작전') {
                        _attendanceStatus = '출석안함';
                      }
                    });

                    // 출석 상태 확인만 하고 알림은 표시하지 않음
                    _checkAttendanceStatus();
                  }
                }
                return; // 첫 스냅샷 처리 후 반환
              }

              // 두 번째 이후 스냅샷 - 실제 변화 감지 및 알림 표시
              if (snapshot.docs.isEmpty) {
                // 활성 세션이 없음 (수업 시작 전 또는 종료됨)
                final bool wasActive = _isClassActive; // 이전에 수업이 활성화되어 있었는지 저장

                debugPrint('활성 세션 없음. 이전 활성 상태: $wasActive');

                // UI 업데이트는 한 번에 처리
                if (mounted) {
                  setState(() {
                    _isClassActive = false;
                    _attendanceStatus = '수업시작전';
                    _activeSessionId = null;

                    // 수업이 종료된 경우 상태 초기화 및 로그 추가
                    if (wasActive && !_isInitialLoad) {
                      _isAttendanceChecked = false;
                      _lastCheckTime = null;

                      // 활동 로그에 기록
                      _activityLogs.insert(0, {
                        'time': DateTime.now(),
                        'message': '세션 종료로 인한 출석 상태 초기화',
                        'isSuccess': true,
                      });
                    }
                  });

                  // 수업이 종료된 경우 알림 표시
                  if (wasActive && !_isInitialLoad) {
                    _showSessionEndedNotification();
                  }
                }
              } else {
                // 활성 세션 있음 (수업 진행 중)
                final sessionDoc = snapshot.docs.first;
                final sessionId = sessionDoc.id;

                // 새 세션인지 확인: 세션 ID가 다르거나 이전에 비활성화되었던 수업이 활성화된 경우
                final bool isNewSession =
                    sessionId != _activeSessionId || !_isClassActive;

                // 세션 시작 시간 가져오기
                final startTime =
                    (sessionDoc.data()['startTime'] as Timestamp).toDate();
                final now = DateTime.now();
                // 최근에 시작된 세션인지 확인 (10분 이내)
                final bool isRecentlyStarted =
                    now.difference(startTime).inMinutes <= 10;

                debugPrint(
                  '활성 세션 발견: $sessionId, 새 세션: $isNewSession, 시작 시간: $startTime, 초기 로드: $_isInitialLoad, 최근 시작: $isRecentlyStarted',
                );

                // UI 업데이트는 한 번에 처리
                if (mounted) {
                  // 이전 세션 ID 임시 저장 (로그용)
                  final String? previousSessionId = _activeSessionId;

                  setState(() {
                    _isClassActive = true;
                    _activeSessionId = sessionId;

                    // 새로운 세션이거나 이전에 세션이 비활성 상태였으면 출석 상태 초기화
                    if (isNewSession) {
                      _isAttendanceChecked = false;
                      _attendanceStatus = '출석안함';

                      // 활동 로그에 기록
                      _activityLogs.insert(0, {
                        'time': DateTime.now(),
                        'message':
                            '세션 상태 변경: 출석 상태 초기화 (이전: ${previousSessionId ?? "없음"} → 현재: $sessionId)',
                        'isSuccess': true,
                      });
                    }
                  });

                  // 새 세션이거나 최근에 시작된 세션인 경우에 알림 표시
                  // 초기 로드가 아닌 경우에만 알림 표시 (앱 시작 시 알림 폭탄 방지)
                  if ((isNewSession || isRecentlyStarted) && !_isInitialLoad) {
                    debugPrint('새 세션 또는 최근 시작된 세션 감지: $sessionId, 알림 표시');
                    _showSessionStartedNotification();
                    _lastNotifiedSessionId = sessionId;

                    // 세션 시작 시간 체크 및 출석 상태 안내
                    _checkSessionStartDuration(sessionId, startTime);
                  }

                  // 세션이 활성화되면 항상 출석 상태 갱신 - 조건과 상관없이 실행
                  _refreshAttendanceStatus();
                }
              }
            },
            onError: (error) {
              debugPrint('수업 상태 리스너 오류: $error');

              // 오류 발생 시 5초 후 재시도
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  _setupSessionListener();
                }
              });
            },
          );

      debugPrint('세션 리스너 설정 완료');
    } catch (e) {
      debugPrint('세션 리스너 설정 중 오류 발생: $e');

      // 오류 발생 시 5초 후 재시도
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _setupSessionListener();
        }
      });
    }
  }

  // 수업 시작 알림 표시
  void _showSessionStartedNotification() {
    if (!mounted) return;

    debugPrint('수업 시작 알림 표시 시작: 세션 ID: $_activeSessionId');

    // 진동 피드백을 먼저 제공하여 즉각적인 반응 보장
    HapticFeedback.heavyImpact();

    // 연속 진동으로 중요한 알림임을 강조
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });

    // 수업 시작 알림 표시 (_showSnackBar 사용)
    _showSnackBar(
      '수업이 시작되었습니다. 출석 체크를 진행해주세요.',
      AppColors.primaryColor,
      duration: const Duration(seconds: 5),
    );

    debugPrint('스낵바 알림 표시 완료');

    // 활동 로그에 기록
    setState(() {
      _activityLogs.insert(0, {
        'time': DateTime.now(),
        'message': '수업 시작 감지됨 (세션 ID: $_activeSessionId)',
        'isSuccess': true,
      });
    });

    // 앱이 백그라운드에 있을 경우에도 즉시 출석 상태를 갱신 - 항상 갱신하도록 설정
    // 새로운 스레드에서 실행하여 UI 업데이트에 방해되지 않도록 함
    Future.microtask(() async {
      await _refreshAttendanceStatus();
      debugPrint('수업 시작 후 출석 상태 갱신 완료');
    });
  }

  // 수업 종료 알림 표시
  void _showSessionEndedNotification() {
    if (!mounted) return;

    // 수업 종료 알림 표시 (_showSnackBar 사용)
    _showSnackBar(
      '수업이 종료되었습니다.',
      AppColors.warningColor,
      duration: const Duration(seconds: 5),
    );

    // 활동 로그에 기록
    setState(() {
      _activityLogs.insert(0, {
        'time': DateTime.now(),
        'message': '수업 종료 감지됨',
        'isSuccess': true,
      });
    });

    // 앱이 백그라운드에 있을 경우에도 즉시 출석 상태를 갱신
    _refreshAttendanceStatus();

    // 포커스 요청 및 진동 알림 (중요한 알림임을 사용자에게 알림)
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildClassDropdown(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showAttendanceHistory,
            tooltip: '출석 기록',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAttendanceStatus,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    AppSpacing.verticalSpaceMD,
                    _buildWifiConnectionStatus(),
                    AppSpacing.verticalSpaceMD,
                    _buildActivityLogSection(),
                  ],
                ),
              ),
            ),
            // 로딩 표시
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      floatingActionButton: AnimatedPadding(
        padding: EdgeInsets.only(bottom: _isSnackbarVisible ? 60.0 : 0),
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed:
              _isLoading
                  ? null
                  : (_isClassActive
                      ? _manualCheckAttendance
                      : () {
                        _showSnackBar('수업중이 아닙니다', AppColors.errorColor);
                      }),
          tooltip: '출석 체크',
          backgroundColor:
              _isLoading
                  ? Colors.grey
                  : (_isClassActive
                      ? (_isAttendanceChecked
                          ? AppColors.successColor
                          : AppColors.primaryColor)
                      : Colors.grey),
          child: Icon(
            _isAttendanceChecked ? Icons.check_circle : Icons.check,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 클래스 선택 드롭다운 위젯
  Widget _buildClassDropdown() {
    // 수업 목록이 없는 경우 일반 텍스트 표시
    if (_classes.isEmpty) {
      return Text(_selectedClassName);
    }

    return DropdownButton<String>(
      value: _selectedClassId,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      elevation: 16,
      style: AppTypography.headline3(context),
      underline: Container(), // 밑줄 제거
      onChanged: (String? newValue) {
        if (newValue != null) {
          _onClassChanged(newValue);
        }
      },
      items:
          _classes.map<DropdownMenuItem<String>>((classInfo) {
            return DropdownMenuItem<String>(
              value: classInfo['id'] as String,
              child: Text(
                classInfo['name'] as String,
                style: TextStyle(
                  color:
                      _selectedClassId == classInfo['id']
                          ? AppColors.primaryColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
      dropdownColor: Theme.of(context).cardColor,
      isExpanded: false,
    );
  }

  /// 출석 상태 카드 위젯
  Widget _buildStatusCard() {
    // 상태에 따른 색상 및 아이콘 설정
    Color statusColor;
    IconData statusIcon;
    String statusDetails = '';

    switch (_attendanceStatus) {
      case '출석완료':
        statusColor = AppColors.successColor;
        statusIcon = Icons.check_circle;
        statusDetails = '정상 출석되었습니다.';
        break;
      case '출석중':
        statusColor = AppColors.successColor;
        statusIcon = Icons.check_circle;
        statusDetails = 'CSI 예측: 자리에 있음 (sitdown)';
        break;
      case '공석':
        statusColor = AppColors.warningColor;
        statusIcon = Icons.warning;
        statusDetails = 'CSI 예측: 자리에 없음 (empty)';
        break;
      case '지각':
        statusColor = AppColors.warningColor;
        statusIcon = Icons.watch_later;
        statusDetails = '지각 처리되었습니다.';
        break;
      case '결석':
        statusColor = AppColors.errorColor;
        statusIcon = Icons.cancel;
        statusDetails = '결석 처리되었습니다.';
        break;
      case '출석안함':
        statusColor = AppColors.warningColor;
        statusIcon = Icons.help_outline;
        statusDetails = '아직 출석 처리되지 않았습니다.';
        break;
      case '수업시작전':
        statusColor = Colors.grey;
        statusIcon = Icons.access_time;
        statusDetails = '수업 시작 전입니다.';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusDetails = '알 수 없는 상태입니다.';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon, size: 48, color: statusColor),
              AppSpacing.horizontalSpaceMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '출석 상태',
                      style: AppTypography.small(context).copyWith(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                    AppSpacing.verticalSpaceXS,
                    Text(
                      _attendanceStatus,
                      style: AppTypography.headline3(context).copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (statusDetails.isNotEmpty) ...[
                      AppSpacing.verticalSpaceXS,
                      Text(
                        statusDetails,
                        style: AppTypography.small(context).copyWith(
                          fontStyle:
                              _attendanceStatus == '출석중' ||
                                      _attendanceStatus == '공석'
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_lastCheckTime != null) ...[
            AppSpacing.verticalSpaceMD,
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
                AppSpacing.horizontalSpaceXS,
                Text(
                  '출석 확인: ${_formatTime(_lastCheckTime!)}',
                  style: AppTypography.small(context).copyWith(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.verticalSpaceMD,
          if (_isClassActive) ...[
            if (!_isAttendanceChecked)
              // 출석 체크 버튼
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: '출석 체크하기',
                  icon: Icons.check_circle_outline,
                  type: ButtonType.primary,
                  onPressed: _isLoading ? null : _checkAttendance,
                ),
              )
            else
              // 상태 갱신 버튼
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: '상태 갱신하기',
                  icon: Icons.refresh,
                  type: ButtonType.secondary,
                  onPressed: _isLoading ? null : _refreshAttendanceStatus,
                ),
              ),
          ] else
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: '새로고침',
                icon: Icons.refresh,
                type: ButtonType.secondary,
                onPressed: _isLoading ? null : _refreshAttendanceStatus,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWifiConnectionStatus() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wi-Fi 연결 상태', style: AppTypography.headline3(context)),
          AppSpacing.verticalSpaceSM,
          Row(
            children: [
              const Icon(Icons.wifi, color: AppColors.successColor, size: 18),
              AppSpacing.horizontalSpaceXS,
              Text(
                'Capstone_AP_1 (연결됨)',
                style: AppTypography.body(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.verticalSpaceSM,
          const LinearProgressIndicator(
            value: 0.8,
            backgroundColor: Colors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
          AppSpacing.verticalSpaceXS,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('신호 강도: 우수', style: AppTypography.small(context)),
              Text(
                'CSI 데이터 수집 중',
                style: AppTypography.small(context).copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpaceMD,
          AppButton(
            text: 'Wi-Fi 재연결',
            icon: Icons.settings_ethernet,
            type: ButtonType.secondary,
            onPressed: _reconnectWifi,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogSection() {
    if (_activityLogs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('활동 로그', style: AppTypography.headline3(context)),
          AppSpacing.verticalSpaceSM,
          const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('아직 활동 로그가 없습니다.'),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('활동 로그', style: AppTypography.headline3(context)),
        AppSpacing.verticalSpaceSM,
        AppCard(
          child: Column(
            children:
                _activityLogs.map((log) => _buildActivityLogItem(log)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLogItem(Map<String, dynamic> log) {
    final DateTime time = log['time'] as DateTime;
    final String message = log['message'] as String;
    final bool isSuccess = log['isSuccess'] as bool;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? AppColors.successColor : AppColors.errorColor,
            size: 16,
          ),
          AppSpacing.horizontalSpaceSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: AppTypography.body(context)),
                Text(
                  _formatTime(time),
                  style: AppTypography.small(context).copyWith(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 출석 상태 새로고침 함수 최적화
  Future<void> _refreshAttendanceStatus() async {
    // 이미 로딩 중이거나 마운트되지 않은 상태면 중복 호출 방지
    if (_isLoading || !mounted) return;

    final now = DateTime.now();

    // 너무 빈번한 호출 방지 (500ms 내 중복 호출 방지)
    // 단, 세션 ID가 null이거나 변경된 경우는 즉시 처리
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inMilliseconds < 500 &&
        _activeSessionId != null) {
      debugPrint(
        '최근 갱신 후 500ms 이내 호출, 스킵: ${now.difference(_lastRefreshTime!).inMilliseconds}ms',
      );
      return;
    }

    _lastRefreshTime = now;
    debugPrint('출석 상태 새로고침 시작: ${now.toString()}');

    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 수업 상태 확인 (비동기 작업이 완료될 때까지 대기)
      await _checkClassStatus();

      // 출석 상태 확인 로직
      if (_isClassActive && _activeSessionId != null) {
        try {
          final currentUser =
              Provider.of<AuthProvider>(context, listen: false).currentUser;

          if (currentUser != null && mounted) {
            // "attendances" 컬렉션에서 현재 세션ID와 학생ID로 출석 기록 조회
            final snapshot =
                await FirebaseFirestore.instance
                    .collection('attendances')
                    .where('sessionId', isEqualTo: _activeSessionId)
                    .where('studentId', isEqualTo: currentUser.id)
                    .limit(1)
                    .get();

            // 마운트 여부 재확인 (비동기 작업 사이에 위젯이 해제될 수 있음)
            if (!mounted) return;

            if (snapshot.docs.isNotEmpty) {
              // 출석 기록이 있으면 체크된 것으로 처리
              final data = snapshot.docs.first.data();
              final status = data['status'] as String? ?? 'unknown';
              final recordedTime =
                  data['recordedTime'] != null
                      ? (data['recordedTime'] as Timestamp).toDate()
                      : (data['checkInTime'] as Timestamp?)?.toDate();

              setState(() {
                _isAttendanceChecked = true;
                _attendanceStatus =
                    status == 'present'
                        ? '출석완료'
                        : status == 'late'
                        ? '지각'
                        : '결석';

                // 출석 시간 가져오기
                if (recordedTime != null) {
                  _lastCheckTime = recordedTime;
                }

                // 활동 로그 업데이트
                _activityLogs.insert(0, {
                  'time': now,
                  'message': '출석 상태를 새로고침했습니다. ($_attendanceStatus)',
                  'isSuccess': true,
                });
              });

              debugPrint(
                '출석 상태 새로고침 완료: $_attendanceStatus (세션 ID: $_activeSessionId)',
              );
            } else {
              // 출석 기록이 없으면 체크 안된 것으로 설정
              setState(() {
                _isAttendanceChecked = false;
                _attendanceStatus = '출석안함';

                // 활동 로그 업데이트
                _activityLogs.insert(0, {
                  'time': now,
                  'message': '출석 상태를 새로고침했습니다. (출석 기록 없음)',
                  'isSuccess': true,
                });
              });

              debugPrint('출석 상태 새로고침 완료: 출석 기록 없음 (세션 ID: $_activeSessionId)');
            }
          }
        } catch (e) {
          debugPrint('출석 상태 확인 중 오류 발생: $e');
        }
      } else if (!_isClassActive && mounted) {
        // 활성화된 수업이 없으면 출석 상태 초기화
        setState(() {
          _isAttendanceChecked = false;
          _attendanceStatus = '수업시작전';
          _lastCheckTime = null;

          // 활동 로그 업데이트
          _activityLogs.insert(0, {
            'time': now,
            'message': '출석 상태를 새로고침했습니다. (수업 시작 전)',
            'isSuccess': true,
          });
        });

        debugPrint('출석 상태 새로고침 완료: 수업 시작 전');
      }
    } catch (e) {
      debugPrint('출석 상태 새로고침 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _activityLogs.insert(0, {
            'time': now,
            'message': '출석 상태 새로고침 실패: $e',
            'isSuccess': false,
          });
        });
      }
    } finally {
      // 로딩 상태 해제
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _manualCheckAttendance() {
    // 수업이 시작되지 않았다면 오류 메시지 표시
    if (!_isClassActive) {
      _showSnackBar('수업중이 아닙니다', AppColors.errorColor);
      return;
    }

    // 이미 출석 체크를 했다면 재확인 다이얼로그 표시
    if (_isAttendanceChecked) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('출석 재확인'),
              content: const Text('이미 출석 처리가 완료되었습니다.\n다시 출석 체크를 진행하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkAttendance(); // 사용자 확인 시 출석 처리 진행
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
      );
      return;
    }

    _checkAttendance();
  }

  void _checkAttendance() async {
    // 로그인한 유저 정보 확인
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      _showSnackBar('사용자 정보를 찾을 수 없습니다.', AppColors.errorColor);
      return;
    }

    // 현재 시간 기록
    final now = DateTime.now();
    bool apiCallSucceeded = false;
    Map<String, dynamic> apiResponse = {
      'success': false,
      'message': '서버 연결 실패, Firebase에만 출석 기록됨',
      'captureStarted': false,
      'timestamp': now.toIso8601String(),
    };

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 서버 API 호출 - 출석 체크 및 캡처 요청
      apiResponse = await _apiService.checkAttendance(
        sessionId: _activeSessionId!,
        classId: _selectedClassId,
        className: _selectedClassName,
        studentId: currentUser.id,
        studentName: currentUser.name,
      );
      apiCallSucceeded = true;
      debugPrint('API 호출 성공: ${apiResponse['message']}');
    } catch (e) {
      // API 호출 실패
      debugPrint('API 호출 실패: $e');
      apiCallSucceeded = false;
      // 서버 통신 실패 시에도 계속 진행 (Firebase에만 저장)
    }

    try {
      // 2. Firestore에 출석 데이터 저장 (API 실패 여부와 관계없이 진행)
      final attendanceRepo = AttendanceRepositoryImpl();
      final attendanceModel = model.AttendanceModel(
        id: '', // Firestore에서 자동 생성
        classId: _selectedClassId,
        className: _selectedClassName,
        studentId: currentUser.id,
        studentName: currentUser.name,
        date: now,
        status: model.AttendanceStatus.present,
        checkInTime: now,
        captureRequested: apiResponse['captureStarted'] ?? false, // 서버 응답 기반
      );

      // 3. 데이터베이스에 출석 기록 저장
      final result = await attendanceRepo.createAttendance(attendanceModel);

      // 3. 세션에 학생의 출석 상태 업데이트 - 교수용 앱에서 볼 수 있게 함
      if (_activeSessionId != null) {
        await FirebaseFirestore.instance.collection('attendances').add({
          'sessionId': _activeSessionId,
          'classId': _selectedClassId,
          'studentId': currentUser.id,
          'studentName': currentUser.name,
          'status': 'present',
          'date': Timestamp.fromDate(now),
          'recordedTime': Timestamp.fromDate(now),
          'activityLogs': [
            {
              'timestamp': Timestamp.fromDate(now),
              'isActive': true,
              'confidenceScore': 1.0,
              'captureRequested': apiResponse['captureStarted'] ?? false,
            },
          ],
        });

        // 정기적으로 활동 상태 업데이트하는 타이머 시작
        _startActivityUpdateTimer();
      }

      // 출석 처리 결과 처리
      result.fold(
        (failure) {
          _showSnackBar('출석 처리 실패: ${failure.message}', AppColors.errorColor);
        },
        (attendanceId) {
          // 출석 성공 처리
          setState(() {
            _isAttendanceChecked = true;
            _attendanceStatus = '출석완료';
            _lastCheckTime = now;

            // 활동 로그 추가
            _activityLogs.insert(0, {
              'time': now,
              'message':
                  apiCallSucceeded
                      ? '출석 체크 완료${apiResponse['captureStarted'] == true ? ' (CSI 캡처 요청됨)' : ''}'
                      : '출석 체크 완료 (서버 연결 없이 Firebase에만 기록됨)',
              'isSuccess': true,
            });
          });

          // 성공 메시지 표시 (API 성공/실패 여부에 따라 다른 메시지)
          _showSnackBar(
            apiCallSucceeded
                ? (apiResponse['message'] ?? '출석이 성공적으로 처리되었습니다.')
                : '서버 연결 없이 출석이 Firebase에 기록되었습니다.',
            AppColors.successColor,
          );
        },
      );
    } catch (e) {
      // Firebase 저장 실패
      debugPrint('Firebase 저장 실패: $e');
      _showSnackBar('출석 데이터 저장 중 오류가 발생했습니다: $e', AppColors.errorColor);
    } finally {
      // 로딩 상태 해제
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAuthCodeInput() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('인증 코드 입력'),
            content: TextField(
              decoration: const InputDecoration(
                hintText: '교수님이 제공한 인증 코드를 입력하세요',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: AppTypography.headline3(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _checkAttendance();
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _reconnectWifi() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Wi-Fi 재연결'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                AppSpacing.verticalSpaceMD,
                const Text('Wi-Fi 연결을 재설정하는 중입니다...\n잠시만 기다려주세요.'),
              ],
            ),
          ),
    );

    // 실제 구현에서는 Wi-Fi 재연결 로직이 들어갈 예정
    // 여기서는 임시로 Future.delayed를 사용하여 비동기 작업 시뮬레이션
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();

      setState(() {
        // 새로운 활동 로그 추가
        _activityLogs.insert(0, {
          'time': DateTime.now(),
          'message': 'Wi-Fi 재연결 완료',
          'isSuccess': true,
        });
      });

      _showSnackBar('Wi-Fi 연결이 재설정되었습니다.', AppColors.successColor);
    });
  }

  void _showHelpInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('도움말'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '출석 체크 방법:',
                    style: AppTypography.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('- 수업이 시작되면 자동으로 출석 체크가 진행됩니다.'),
                  const Text(
                    '- 자동 출석 체크가 작동하지 않을 경우, 인증 코드를 통해 수동으로 출석 체크를 할 수 있습니다.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '출석 상태:',
                    style: AppTypography.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('- 수업시작전: 아직 수업이 시작되지 않았습니다.'),
                  const Text('- 출석안함: 수업이 시작되었지만 아직 출석 체크가 되지 않았습니다.'),
                  const Text('- 출석완료: 정상적으로 출석 처리되었습니다.'),
                  const Text('- 지각: 수업 시작 후 일정 시간이 지난 후 출석했습니다.'),
                  const SizedBox(height: 8),
                  Text(
                    '기타:',
                    style: AppTypography.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('- Wi-Fi 연결에 문제가 있을 경우 "Wi-Fi 재연결" 버튼을 눌러보세요.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AttendanceHistoryScreen(
              classId: _selectedClassId,
              className: _selectedClassName,
            ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  // 활동 상태 업데이트 타이머 시작
  void _startActivityUpdateTimer() {
    // 기존 타이머가 있으면 취소
    _activityUpdateTimer?.cancel();

    // 5분마다 활동 상태 업데이트
    _activityUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isAttendanceChecked && _activeSessionId != null) {
        _updateActivityStatus();
      }
    });
  }

  // 학생 활동 상태 업데이트
  Future<void> _updateActivityStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null || _activeSessionId == null) return;

      // 현재 시간 기록
      final now = DateTime.now();

      // Firestore에 활동 로그 추가
      await FirebaseFirestore.instance.collection('attendances').add({
        'sessionId': _activeSessionId,
        'classId': _selectedClassId,
        'studentId': currentUser.id,
        'studentName': currentUser.name,
        'status': 'present',
        'recordedTime': Timestamp.fromDate(now),
        'activityLogs': [
          {
            'timestamp': Timestamp.fromDate(now),
            'isActive': true,
            'confidenceScore': 1.0,
          },
        ],
      });

      // 로컬 활동 로그 업데이트
      setState(() {
        _lastCheckTime = now;
        _activityLogs.insert(0, {
          'time': now,
          'message': '활동 상태 업데이트',
          'isSuccess': true,
        });
      });

      debugPrint('학생 활동 상태 업데이트: ${now.toIso8601String()}');
    } catch (e) {
      debugPrint('활동 상태 업데이트 오류: $e');
    }
  }

  // Snackbar 표시 함수
  void _showSnackBar(
    String message,
    Color backgroundColor, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
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
          duration: duration,
          action: action,
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

  // 출석 체크 상태 확인 메서드 추가
  Future<void> _checkAttendanceStatus() async {
    if (!_isClassActive || _activeSessionId == null) return;

    try {
      debugPrint('세션 $_activeSessionId에 대한 출석 상태 확인 중');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        debugPrint('사용자 정보를 찾을 수 없음');
        return;
      }

      // 출석 모니터링 서비스 인스턴스 생성
      final monitoringService = AttendanceMonitoringService();

      // CSI 서버에서 예측 결과 가져오기 시도
      final prediction = await monitoringService.fetchCSIPrediction(
        sessionId: _activeSessionId!,
        studentId: currentUser.id,
      );

      // CSI 예측 결과가 있으면 활용
      if (prediction != null) {
        final predictionResult = prediction['prediction'] as String;
        final isPresent = prediction['is_present'] as bool;
        final attendanceStatus = prediction['attendance_status'] as String;

        debugPrint('CSI 예측 결과: $predictionResult, 출석 상태: $attendanceStatus');

        // Firestore에 상태 업데이트
        await FirebaseFirestore.instance.collection('attendances').add({
          'sessionId': _activeSessionId,
          'classId': _selectedClassId,
          'studentId': currentUser.id,
          'studentName': currentUser.name,
          'status': attendanceStatus,
          'predictionResult': predictionResult,
          'isPresent': isPresent,
          'date': FieldValue.serverTimestamp(),
          'recordedTime': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'activityLogs': [
            {
              'timestamp': FieldValue.serverTimestamp(),
              'isActive': isPresent,
              'confidenceScore': 1.0,
            },
          ],
        });

        // 상태 업데이트
        setState(() {
          _isAttendanceChecked = true;
          _attendanceStatus = attendanceStatus;
          _lastCheckTime = DateTime.now();

          // 활동 로그에 기록
          _activityLogs.insert(0, {
            'time': DateTime.now(),
            'message': 'CSI 예측 결과: $predictionResult, 출석 상태: $attendanceStatus',
            'isSuccess': true,
          });
        });

        return;
      }

      // CSI 예측이 실패한 경우 기존 방식으로 Firestore에서 출석 상태 확인
      final snapshot =
          await FirebaseFirestore.instance
              .collection('attendances')
              .where('sessionId', isEqualTo: _activeSessionId)
              .where('studentId', isEqualTo: currentUser.id)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        // 출석 기록이 있으면 체크된 것으로 처리
        final data = snapshot.docs.first.data();
        final status = data['status'] as String? ?? 'unknown';
        final predictionResult =
            data['predictionResult'] as String? ?? 'unknown';

        debugPrint('출석 기록 발견: 상태=$status, 예측 결과=$predictionResult');

        setState(() {
          _isAttendanceChecked = true;

          // CSI 예측 결과 기반 상태 설정
          if (predictionResult.toLowerCase() == 'sitdown') {
            _attendanceStatus = '출석중';
          } else if (predictionResult.toLowerCase() == 'empty') {
            _attendanceStatus = '공석';
          } else {
            // 기존 상태 로직
            _attendanceStatus =
                status == 'present'
                    ? '출석완료'
                    : status == 'late'
                    ? '지각'
                    : '결석';
          }

          // 출석 시간 가져오기
          if (data['recordedTime'] != null) {
            _lastCheckTime = (data['recordedTime'] as Timestamp).toDate();
          }

          // 활동 로그에 기록
          _activityLogs.insert(0, {
            'time': DateTime.now(),
            'message': '출석 상태 확인됨: $_attendanceStatus, 예측: $predictionResult',
            'isSuccess': true,
          });
        });
      } else {
        // 출석 기록이 없으면 체크 안된 것으로 설정
        debugPrint('출석 기록 없음: 출석 체크 필요');

        setState(() {
          _isAttendanceChecked = false;
          _attendanceStatus = '출석안함';
        });
      }
    } catch (e) {
      debugPrint('출석 상태 확인 중 오류 발생: $e');
    }
  }

  // 세션이 시작된 지 얼마나 지났는지 확인하고, 출석 가능 여부를 판단하는 함수
  Future<void> _checkSessionStartDuration(
    String sessionId,
    DateTime startTime,
  ) async {
    if (!mounted) return;

    final now = DateTime.now();
    final differenceInMinutes = now.difference(startTime).inMinutes;

    debugPrint(
      '세션 시작 시간 체크: 시작 시간 ${startTime.toString()}, 현재 ${now.toString()}, 차이: $differenceInMinutes분',
    );

    // 수업 시작 후 출석 상태 확인
    try {
      final currentUser =
          Provider.of<AuthProvider>(context, listen: false).currentUser;

      if (currentUser != null && mounted) {
        // 이미 출석했는지 확인
        final snapshot =
            await FirebaseFirestore.instance
                .collection('attendances')
                .where('sessionId', isEqualTo: sessionId)
                .where('studentId', isEqualTo: currentUser.id)
                .limit(1)
                .get();

        final bool alreadyAttended = snapshot.docs.isNotEmpty;

        // 메시지 생성
        String message;
        Color backgroundColor;
        SnackBarAction? action;

        if (alreadyAttended) {
          // 이미 출석한 경우
          message = '이미 출석이 완료되었습니다.';
          backgroundColor = AppColors.successColor;
          action = null;
        } else if (differenceInMinutes <= 15) {
          // 수업 시작 15분 이내인 경우 출석 가능
          message = '수업이 시작되었습니다. 지금 출석하면 출석으로 인정됩니다.';
          backgroundColor = AppColors.primaryColor;
          action = SnackBarAction(
            label: '출석하기',
            textColor: Colors.white,
            onPressed: _manualCheckAttendance,
          );
        } else if (differenceInMinutes <= 30) {
          // 수업 시작 15-30분 사이인 경우 지각
          message = '수업이 $differenceInMinutes분 전에 시작되었습니다. 지금 출석하면 지각으로 처리됩니다.';
          backgroundColor = AppColors.warningColor;
          action = SnackBarAction(
            label: '출석하기',
            textColor: Colors.white,
            onPressed: _manualCheckAttendance,
          );
        } else {
          // 수업 시작 30분 이후인 경우 결석 처리
          message = '수업이 $differenceInMinutes분 전에 시작되었습니다. 현재 결석 상태입니다.';
          backgroundColor = AppColors.errorColor;
          action = SnackBarAction(
            label: '출석하기',
            textColor: Colors.white,
            onPressed: _manualCheckAttendance,
          );
        }

        // 사용자에게 알림 - _showSnackBar 함수 사용
        if (mounted) {
          _showSnackBar(message, backgroundColor, action: action);
        }
      }
    } catch (e) {
      debugPrint('세션 시작 시간 확인 오류: $e');
    }
  }
}
