import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/widgets/app_button.dart';
import 'package:capston_design/widgets/app_text_field.dart';
import 'package:capston_design/domain/entities/class.dart';
import 'package:capston_design/domain/repositories/class_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Class> _classes = [];
  bool _isLoading = true;
  DateTime _selectedWeek = DateTime.now();
  final ClassRepository _classRepository = ClassRepositoryImpl();
  StreamSubscription? _classesSubscription;
  final Set<String> _removedClassIds = {};

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _setupClassesListener();
  }

  @override
  void dispose() {
    _classesSubscription?.cancel();
    super.dispose();
  }

  // Firebase 스트림 리스너 설정
  void _setupClassesListener() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    // Firestore 쿼리를 통해 수업 변경사항을 실시간으로 감지
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 디버깅 로그 추가
    debugPrint(
      '스트림 리스너 설정 - 사용자: ${user.id}, 역할: ${user.isProfessor ? "교수" : "학생"}',
    );

    try {
      if (user.isProfessor) {
        // 교수: 자신이 생성한 수업 조회
        _classesSubscription = firestore
            .collection('classes')
            .where('professorId', isEqualTo: user.id)
            .snapshots()
            .listen(_handleClassesSnapshot);
      } else {
        // 학생: 수강 중인 수업 조회
        _classesSubscription = firestore
            .collection('classes')
            .where('studentIds', arrayContains: user.id)
            .snapshots()
            .listen(_handleClassesSnapshot);
      }

      debugPrint('스트림 리스너 등록 성공');
    } catch (e) {
      debugPrint('스트림 리스너 설정 오류: $e');
      // 오류 발생 시 일반적인 방식으로 데이터 로드
      _loadClasses();
    }
  }

  // 스냅샷 핸들러 함수로 분리
  void _handleClassesSnapshot(QuerySnapshot snapshot) {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    debugPrint(
      '스냅샷 변경 감지: ${snapshot.docs.length}개 문서, 변경사항: ${snapshot.docChanges.length}개',
    );

    // 변경 사항을 별도로 추적하여 UI 업데이트 최적화
    final Map<String, DocumentChangeType> changedDocs = {};

    // 변경 내용 더 자세히 로깅
    for (var change in snapshot.docChanges) {
      final docId = change.doc.id;
      final docData = change.doc.data() as Map<String, dynamic>?;

      // 변경된 문서 ID와 변경 유형 기록
      changedDocs[docId] = change.type;

      if (docData == null) continue;

      switch (change.type) {
        case DocumentChangeType.added:
          debugPrint('문서 추가됨: $docId - ${docData['name']}');
          break;
        case DocumentChangeType.modified:
          debugPrint('문서 수정됨: $docId - ${docData['name']}');
          // studentIds 확인
          final List<dynamic> studentIds = docData['studentIds'] ?? [];
          debugPrint('수정된 문서의 학생 ID 목록: $studentIds');

          // 현재 학생이 포함되어 있는지 확인
          if (!currentUser.isProfessor) {
            final isIncluded = studentIds.contains(currentUser.id);
            debugPrint('현재 학생(${currentUser.id})이 수강 목록에 포함됨: $isIncluded');

            // 수정된 문서에 현재 학생이 없지만 의도적으로 취소한 경우
            // (교수가 수정 중 실수로 학생 목록에서 제외한 경우)
            if (!isIncluded && !_removedClassIds.contains(docId)) {
              debugPrint('교수가 수정 중 학생이 제외됨 - 재추가 고려');
            }
          }
          break;
        case DocumentChangeType.removed:
          debugPrint('문서 제거됨: $docId');
          break;
      }
    }

    try {
      // 기존 클래스 ID 목록 유지 (학생 앱에서 수강 중인 수업 확인용)
      final existingClassIds = _classes.map((c) => c.id).toSet();

      // 기존 클래스 맵 생성 (빠른 조회를 위해)
      final Map<String, Class> existingClassMap = {
        for (var c in _classes) c.id: c,
      };

      // 스냅샷에서 직접 클래스 정보를 파싱하여 상태 업데이트
      final List<Class> updatedClasses = [];

      for (var doc in snapshot.docs) {
        try {
          final String docId = doc.id;

          // 학생이 의도적으로 수강 취소한 수업은 건너뛰기
          if (!currentUser.isProfessor && _removedClassIds.contains(docId)) {
            debugPrint('수강 취소된 수업이므로 건너뛰기: $docId');
            continue;
          }

          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // 필요한 데이터가 있는지 검증
          if (!data.containsKey('name') || !data.containsKey('professorId')) {
            debugPrint('유효하지 않은 클래스 데이터: ${doc.id}');
            continue;
          }

          // 디버깅을 위한 데이터 로깅
          debugPrint('클래스 데이터: ${doc.id} - ${data['name']}');

          // 스케줄 정보 확인
          final List<dynamic> scheduleData = data['schedule'] ?? [];
          if (scheduleData.isEmpty) {
            debugPrint('스케줄 정보 없음: ${doc.id}');
            continue;
          }

          // 첫 번째 스케줄 정보 가져오기
          final Map<String, dynamic> firstSchedule = scheduleData.first;
          final String dayStr = firstSchedule['day'] ?? '월';
          final String startTime = firstSchedule['startTime'] ?? '09:00';
          final String endTime = firstSchedule['endTime'] ?? '10:00';

          // 학생 목록 가져오기
          final List<String> studentIds = List<String>.from(
            data['studentIds'] ?? [],
          );

          // 학생 앱의 경우, 수강 목록에서 학생 ID가 있는지 확인
          if (!currentUser.isProfessor &&
              !studentIds.contains(currentUser.id)) {
            // 수정된 문서에 현재 학생이 없고 의도적으로 취소한 경우
            final bool isModified =
                changedDocs[docId] == DocumentChangeType.modified;
            final bool wasInClass = existingClassIds.contains(docId);

            // 학생이 의도적으로 수강 취소한 경우 건너뛰기
            if (_removedClassIds.contains(docId)) {
              debugPrint('수강 취소된 수업이므로 학생 추가 건너뛰기: $docId');
              continue;
            }

            // 교수가 수정한 수업에서 실수로 학생이 제외되었을 가능성 체크
            if (isModified && wasInClass) {
              debugPrint(
                '교수가 수정한 수업($docId)에서 현재 학생이 제외되어 있지만, 기존 수강 신청 내역이므로 유지',
              );

              // 해당 과목을 수강 목록에 다시 추가하는 작업 수행
              _classRepository.addStudentToClass(docId, currentUser.id).then((
                result,
              ) {
                result.fold(
                  (failure) => debugPrint('수강 목록 재추가 실패: ${failure.message}'),
                  (_) => debugPrint('수강 목록 재추가 성공'),
                );
              });

              // 기존 수강 목록에 있었다면 studentIds에 현재 사용자 추가하여 UI에 표시
              studentIds.add(currentUser.id);
            } else if (!wasInClass) {
              // 수강 신청한 적 없는 과목이면 건너뛰기
              debugPrint('현재 학생이 수강하지 않는 과목: ${doc.id}');
              continue;
            }
          }

          // 학생 목록 디버깅
          debugPrint('파싱된 학생 ID 목록 (${doc.id}): $studentIds');

          // 타임스탬프 처리
          final DateTime createdAt =
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final DateTime updatedAt =
              (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt;

          // 수정된 문서인 경우 변경 시간 확인
          if (changedDocs[docId] == DocumentChangeType.modified &&
              existingClassMap.containsKey(docId)) {
            final existingUpdatedAt =
                existingClassMap[docId]?.lastUpdatedAt ?? createdAt;
            debugPrint(
              '수업 업데이트 시간 변경: ${existingUpdatedAt.toString()} -> ${updatedAt.toString()}',
            );
          }

          // Class 객체 직접 생성
          final classEntity = Class(
            id: doc.id,
            name: data['name'],
            professorId: data['professorId'],
            location: data['location'] ?? '',
            weekDay: _parseWeekDay(dayStr),
            startTime: startTime,
            endTime: endTime,
            status: ClassStatus.scheduled,
            studentIds: studentIds,
            createdAt: createdAt,
            lastUpdatedAt: updatedAt,
          );

          updatedClasses.add(classEntity);
          debugPrint(
            '클래스 파싱 성공: ${classEntity.name} (학생 수: ${studentIds.length})',
          );
        } catch (e) {
          debugPrint('문서 파싱 오류 [${doc.id}]: $e');
        }
      }

      // 변경된 문서가 있거나 클래스 목록이 달라진 경우에만 setState 호출
      if (mounted &&
          (changedDocs.isNotEmpty ||
              _classes.length != updatedClasses.length ||
              !_areClassListsEqual(_classes, updatedClasses))) {
        setState(() {
          _classes = updatedClasses;
          _isLoading = false;
          debugPrint('UI 업데이트: ${_classes.length}개 수업 로드됨');
        });
      } else if (mounted && _isLoading) {
        // 로딩 중인 경우에만 로딩 상태 업데이트
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('스냅샷 처리 오류: $e');

      // 오류 발생 시 일반 로딩 메서드로 대체
      if (mounted) {
        _loadClasses();
      }
    }
  }

  // 두 Class 목록이 동일한지 비교하는 헬퍼 메서드
  bool _areClassListsEqual(List<Class> list1, List<Class> list2) {
    if (list1.length != list2.length) return false;

    // ID 기준으로 정렬
    final sortedList1 = List<Class>.from(list1)
      ..sort((a, b) => a.id.compareTo(b.id));
    final sortedList2 = List<Class>.from(list2)
      ..sort((a, b) => a.id.compareTo(b.id));

    for (int i = 0; i < sortedList1.length; i++) {
      final c1 = sortedList1[i];
      final c2 = sortedList2[i];

      // 기본 속성 비교
      if (c1.id != c2.id ||
          c1.name != c2.name ||
          c1.location != c2.location ||
          c1.weekDay != c2.weekDay ||
          c1.startTime != c2.startTime ||
          c1.endTime != c2.endTime) {
        return false;
      }

      // 학생 목록 비교
      if (!_areListsEqual(c1.studentIds, c2.studentIds)) {
        return false;
      }
    }

    return true;
  }

  // 두 문자열 목록이 동일한지 비교하는 헬퍼 메서드
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;

    final sorted1 = List<String>.from(list1)..sort();
    final sorted2 = List<String>.from(list2)..sort();

    for (int i = 0; i < sorted1.length; i++) {
      if (sorted1[i] != sorted2[i]) return false;
    }

    return true;
  }

  // 문자열에서 WeekDay로 변환하는 도우미 함수
  WeekDay _parseWeekDay(String dayStr) {
    switch (dayStr) {
      case '월':
        return WeekDay.monday;
      case '화':
        return WeekDay.tuesday;
      case '수':
        return WeekDay.wednesday;
      case '목':
        return WeekDay.thursday;
      case '금':
        return WeekDay.friday;
      case '토':
        return WeekDay.saturday;
      case '일':
        return WeekDay.sunday;
      default:
        return WeekDay.monday;
    }
  }

  Future<void> _loadClasses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          user.isProfessor
              ? await _classRepository.getClassesByProfessorId(user.id)
              : await _classRepository.getClassesByStudentId(user.id);

      result.fold(
        (failure) {
          // 에러 처리
          String errorMsg = '시간표를 불러오는데 실패했습니다: ${failure.message}';
          String actionMsg = '';

          // 오류 유형에 따른 추가 메시지
          if (failure.message.contains('network') ||
              failure.message.contains('connection')) {
            actionMsg = '네트워크 연결을 확인하고 다시 시도해주세요.';
          } else if (failure.message.contains('permission') ||
              failure.message.contains('denied')) {
            actionMsg = '수업 접근 권한이 없거나 변경되었습니다. 교수님에게 문의하세요.';
          } else if (!user.isProfessor) {
            actionMsg = '교수님이 최근에 수업 정보를 수정했을 수 있습니다. 교수님에게 문의하세요.';
          }

          // 에러 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMsg),
                  if (actionMsg.isNotEmpty)
                    Text(actionMsg, style: const TextStyle(fontSize: 12)),
                ],
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(label: '재시도', onPressed: _loadClasses),
            ),
          );
        },
        (classesList) {
          setState(() {
            _classes = classesList;
            debugPrint('수업 목록 로드 성공: ${_classes.length}개');
          });
        },
      );
    } catch (e) {
      // 일반적인 예외 처리
      String errorMsg = '시간표를 불러오는데 실패했습니다: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: '재시도', onPressed: _loadClasses),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getWeekRangeText() {
    // 날짜 표시를 제거하고 빈 문자열 반환
    return "";
  }

  int _getWeekOfMonth(DateTime date) {
    // 해당 월의 첫 날
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    // 첫 번째 월요일까지의 오프셋 계산
    final dayOffset = (firstDayOfMonth.weekday - 1) % 7;
    // 주차 계산
    return ((date.day + dayOffset - 1) / 7).ceil();
  }

  void _previousWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isProfessor = user?.isProfessor ?? false;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 화살표 아이콘 버튼 제거
          ],
        ),
        // actions에서 + 버튼 제거
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildScheduleContent(context, isProfessor),
    );
  }

  Widget _buildScheduleContent(BuildContext context, bool isProfessor) {
    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 첫 번째 요일(월요일) 표시 부분에 요일과 + 버튼을 같은 Row에 배치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('월요일', style: AppTypography.headline3(context)),
              // 모든 사용자에게 + 버튼 표시 (교수와 학생 모두)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // 시간표 추가 다이얼로그 표시
                  _showAddClassDialog(context, isProfessor);
                },
              ),
            ],
          ),
          _buildDaySchedule(
            context,
            '월요일',
            WeekDay.monday,
            isProfessor,
            showHeader: false,
          ),
          _buildDaySchedule(context, '화요일', WeekDay.tuesday, isProfessor),
          _buildDaySchedule(context, '수요일', WeekDay.wednesday, isProfessor),
          _buildDaySchedule(context, '목요일', WeekDay.thursday, isProfessor),
          _buildDaySchedule(context, '금요일', WeekDay.friday, isProfessor),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(
    BuildContext context,
    String day,
    WeekDay weekDay,
    bool isProfessor, {
    bool showHeader = true, // 헤더 표시 여부를 제어하는 파라미터 추가
  }) {
    // 해당 요일의 수업 필터링
    final dayClasses = _classes.where((c) => c.weekDay == weekDay).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // showHeader가 true인 경우에만 요일 헤더를 표시
        if (showHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(day, style: AppTypography.headline3(context)),
          ),
        dayClasses.isEmpty
            ? AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text(
                    '수업이 없습니다',
                    style: AppTypography.body(context).copyWith(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
            )
            : Column(
              children:
                  dayClasses
                      .map(
                        (classData) =>
                            _buildClassCard(context, classData, isProfessor),
                      )
                      .toList(),
            ),
        AppSpacing.verticalSpaceMD,
      ],
    );
  }

  // 교수 ID로 교수 이름을 조회하는 함수 추가
  Future<String> _getProfessorName(String professorId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(professorId)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] ?? professorId; // 이름이 없으면 ID 반환
      }
      return professorId; // 문서가 없으면 ID 반환
    } catch (e) {
      debugPrint('교수 이름 조회 오류: $e');
      return professorId; // 오류 발생 시 ID 반환
    }
  }

  Widget _buildClassCard(
    BuildContext context,
    Class classData,
    bool isProfessor,
  ) {
    // StatefulBuilder를 사용하여 비동기적으로 교수 이름 업데이트
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () {
        // 수업 상세 화면으로 이동하는 로직 (미구현)
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    classData.name,
                    style: AppTypography.subhead(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${classData.startTime} - ${classData.endTime}",
                    style: AppTypography.small(
                      context,
                    ).copyWith(color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceSM,
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
                AppSpacing.horizontalSpaceXS,
                Expanded(
                  child: Text(
                    classData.location ?? '장소 미정',
                    style: AppTypography.small(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 교수용 앱에서만 장소 옆에 수정/삭제 버튼 표시
                if (isProfessor) ...[
                  // 수정 버튼 (교수용 앱에만 표시)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditClassDialog(context, classData),
                    tooltip: '수업 수정',
                    visualDensity: VisualDensity.compact,
                    splashRadius: 20,
                    color: AppColors.primaryColor,
                  ),
                  // 삭제 버튼
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _showDeleteClassDialog(context, classData),
                    tooltip: '수업 삭제',
                    visualDensity: VisualDensity.compact,
                    splashRadius: 20,
                    color: AppColors.errorColor,
                  ),
                ],
              ],
            ),
            if (!isProfessor) ...[
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                  AppSpacing.horizontalSpaceXS,
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _getProfessorName(classData.professorId),
                      builder: (context, snapshot) {
                        final displayName =
                            snapshot.data ?? classData.professorId;
                        return Text(
                          displayName,
                          style: AppTypography.small(context),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  // 학생용 앱에서는 삭제 버튼만 표시 (교수 정보 옆에)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _showDeleteClassDialog(context, classData),
                    tooltip: '수강 취소',
                    visualDensity: VisualDensity.compact,
                    splashRadius: 20,
                    color: AppColors.errorColor,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteClassDialog(BuildContext context, Class classData) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final isProfessor = user?.isProfessor ?? false;

    final title = isProfessor ? '시간표 삭제' : '수강 취소';
    final content =
        isProfessor
            ? '${classData.name} 수업을 시간표에서 삭제하시겠습니까?'
            : '${classData.name} 수업 수강을 취소하시겠습니까?';
    final buttonText = isProfessor ? '삭제' : '취소';
    final successMessage = isProfessor ? '수업이 삭제되었습니다' : '수강이 취소되었습니다';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  setState(() {
                    _isLoading = true;
                  });

                  final result =
                      isProfessor
                          ? await _classRepository.deleteClass(classData.id)
                          : await _classRepository.removeStudentFromClass(
                            classData.id,
                            user!.id,
                          );

                  result.fold(
                    (failure) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('실패: ${failure.message}')),
                      );
                    },
                    (_) {
                      // 성공적으로 삭제/취소된 경우, 즉시 로컬 상태에서 해당 수업 제거
                      setState(() {
                        _classes.removeWhere((c) => c.id == classData.id);
                        _isLoading = false;
                      });

                      // 학생 수강 취소의 경우, 리스너에서 자동 재추가 방지를 위해 수업 ID 기록
                      if (!isProfessor) {
                        _removedClassIds.add(classData.id);
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(successMessage)));
                    },
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(buttonText),
              ),
            ],
          ),
    );
  }

  // 시간표 추가 다이얼로그
  void _showAddClassDialog(BuildContext context, bool isProfessor) {
    if (isProfessor) {
      // 교수용 앱 - 기존 UI 유지
      _showProfessorAddClassDialog(context);
    } else {
      // 학생용 앱 - 드롭다운으로 교수가 추가한 수업 선택하는 UI
      _showStudentAddClassDialog(context);
    }
  }

  // 교수용 앱의 수업 추가 다이얼로그
  void _showProfessorAddClassDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    WeekDay selectedDay = WeekDay.monday;
    String startTime = '09:00';
    String endTime = '10:30';

    // 시간 선택 옵션
    final timeOptions = [
      '08:00',
      '08:30',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '12:00',
      '12:30',
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
      '17:00',
      '17:30',
      '18:00',
      '18:30',
      '19:00',
      '19:30',
      '20:00',
      '20:30',
      '21:00',
      '21:30',
      '22:00',
    ];

    // 요일 선택 옵션
    final weekDayOptions = {
      WeekDay.monday: '월요일',
      WeekDay.tuesday: '화요일',
      WeekDay.wednesday: '수요일',
      WeekDay.thursday: '목요일',
      WeekDay.friday: '금요일',
      WeekDay.saturday: '토요일',
      WeekDay.sunday: '일요일',
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('새 수업 추가'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: '수업명',
                      hintText: '수업 이름을 입력하세요',
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                    ),
                    AppSpacing.verticalSpaceMD,
                    AppTextField(
                      label: '장소',
                      hintText: '강의실 또는 장소를 입력하세요',
                      controller: locationController,
                      textInputAction: TextInputAction.next,
                    ),
                    AppSpacing.verticalSpaceMD,
                    Text('요일', style: AppTypography.label(context)),
                    AppSpacing.verticalSpaceSM,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.backgroundSecondaryDark
                                : AppColors.backgroundSecondaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<WeekDay>(
                          isExpanded: true,
                          value: selectedDay,
                          items:
                              weekDayOptions.entries.map((entry) {
                                return DropdownMenuItem<WeekDay>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedDay = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpaceMD,
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '시작 시간',
                                style: AppTypography.label(context),
                              ),
                              AppSpacing.verticalSpaceSM,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.backgroundSecondaryDark
                                          : AppColors.backgroundSecondaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: startTime,
                                    items:
                                        timeOptions.map((time) {
                                          return DropdownMenuItem<String>(
                                            value: time,
                                            child: Text(time),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          startTime = value;
                                          // 시작 시간이 종료 시간보다 늦으면 종료 시간 자동 조정
                                          if (timeOptions.indexOf(startTime) >=
                                              timeOptions.indexOf(endTime)) {
                                            final nextIndex =
                                                timeOptions.indexOf(startTime) +
                                                1;
                                            if (nextIndex <
                                                timeOptions.length) {
                                              endTime = timeOptions[nextIndex];
                                            }
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.horizontalSpaceSM,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '종료 시간',
                                style: AppTypography.label(context),
                              ),
                              AppSpacing.verticalSpaceSM,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.backgroundSecondaryDark
                                          : AppColors.backgroundSecondaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: endTime,
                                    // 시작 시간 이후의 시간만 선택 가능하도록
                                    items:
                                        timeOptions
                                            .where(
                                              (time) =>
                                                  timeOptions.indexOf(time) >
                                                  timeOptions.indexOf(
                                                    startTime,
                                                  ),
                                            )
                                            .map((time) {
                                              return DropdownMenuItem<String>(
                                                value: time,
                                                child: Text(time),
                                              );
                                            })
                                            .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          endTime = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                AppButton(
                  text: '추가',
                  type: ButtonType.primary,
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('수업명을 입력해주세요')),
                      );
                      return;
                    }

                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final user = authProvider.currentUser;

                    if (user == null) {
                      Navigator.of(context).pop();
                      return;
                    }

                    // 새 수업 생성
                    final newClass = Class(
                      id: '', // Firebase에서 자동 생성될 ID
                      name: nameController.text.trim(),
                      professorId: user.id,
                      location:
                          locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                      weekDay: selectedDay,
                      startTime: startTime,
                      endTime: endTime,
                      status: ClassStatus.scheduled,
                      studentIds: const [], // 교수가 생성하는 경우 빈 배열로 시작
                      createdAt: DateTime.now(),
                    );

                    Navigator.of(context).pop();

                    // 로딩 시작
                    setState(() {
                      _isLoading = true;
                    });

                    // 데이터베이스에 저장
                    final result = await _classRepository.saveClass(newClass);

                    result.fold(
                      (failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('저장 실패: ${failure.message}')),
                        );
                      },
                      (savedClass) {
                        // 목록 새로고침
                        _loadClasses();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('수업이 추가되었습니다')),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 학생용 앱의 수업 추가 다이얼로그 - 교수가 추가한 수업 목록에서 선택하는 방식
  void _showStudentAddClassDialog(BuildContext context) {
    Class? selectedClass;
    bool isLoading = true;
    List<Class> availableClasses = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            // 초기 로딩 시 모든 사용 가능한 수업 불러오기
            if (isLoading) {
              // 비동기 로딩을 바로 시작
              _loadAvailableClasses().then((classes) {
                if (dialogContext.mounted) {
                  dialogSetState(() {
                    availableClasses = classes;
                    isLoading = false;
                    if (availableClasses.isNotEmpty) {
                      selectedClass = availableClasses.first;
                    }
                  });
                }
              });
            }

            return AlertDialog(
              title: const Text('수강 과목 추가'),
              content:
                  isLoading
                      ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : availableClasses.isEmpty
                      ? const Center(
                        child: Text('수강 가능한 과목이 없습니다. 교수님의 수업 개설 후 다시 시도해주세요.'),
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '수강할 과목을 선택하세요',
                            style: AppTypography.body(dialogContext),
                          ),
                          AppSpacing.verticalSpaceMD,
                          Text(
                            '과목 선택',
                            style: AppTypography.label(dialogContext),
                          ),
                          AppSpacing.verticalSpaceSM,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(dialogContext).brightness ==
                                          Brightness.dark
                                      ? AppColors.backgroundSecondaryDark
                                      : AppColors.backgroundSecondaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Class>(
                                isExpanded: true,
                                value: selectedClass,
                                items:
                                    availableClasses.map((classItem) {
                                      final weekdayText = _getWeekdayText(
                                        classItem.weekDay,
                                      );
                                      return DropdownMenuItem<Class>(
                                        value: classItem,
                                        child: Text(
                                          '${classItem.name} ($weekdayText ${classItem.startTime}-${classItem.endTime})',
                                        ),
                                      );
                                    }).toList(),
                                onChanged:
                                    availableClasses.isEmpty
                                        ? null
                                        : (value) {
                                          if (value != null) {
                                            dialogSetState(() {
                                              selectedClass = value;
                                            });
                                          }
                                        },
                              ),
                            ),
                          ),
                          if (selectedClass != null) ...[
                            AppSpacing.verticalSpaceMD,
                            Text(
                              '강의실: ${selectedClass?.location ?? '미정'}',
                              style: AppTypography.body(dialogContext),
                            ),
                            AppSpacing.verticalSpaceSM,
                            Text(
                              '교수: ${selectedClass?.professorId}',
                              style: AppTypography.body(dialogContext),
                            ),
                          ],
                        ],
                      ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                AppButton(
                  text: '추가',
                  type: ButtonType.primary,
                  onPressed:
                      isLoading ||
                              availableClasses.isEmpty ||
                              selectedClass == null
                          ? null
                          : () {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final user = authProvider.currentUser;

                            if (user == null || selectedClass == null) {
                              Navigator.of(dialogContext).pop();
                              return;
                            }

                            // 현재 선택된 수업을 저장하고 다이얼로그는 닫기
                            final selectedClassToAdd = selectedClass;
                            Navigator.of(dialogContext).pop();

                            // 외부 위젯의 상태를 업데이트
                            setState(() {
                              _isLoading = true;
                            });

                            // 수업에 학생 추가 - 비동기 작업
                            _addStudentToClass(user.id, selectedClassToAdd!);
                          },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 수업에 학생 추가하는 비동기 메서드
  Future<void> _addStudentToClass(String studentId, Class selectedClass) async {
    // 수업에 학생 추가
    final result = await _classRepository.addStudentToClass(
      selectedClass.id,
      studentId,
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('수강 신청 실패: ${failure.message}')));
      },
      (updatedClass) {
        // 목록 새로고침
        _loadClasses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedClass.name} 과목이 추가되었습니다')),
        );
      },
    );
  }

  // 사용 가능한 수업 목록을 불러오는 메서드
  Future<List<Class>> _loadAvailableClasses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return [];

    try {
      // 모든 수업 목록 불러오기
      final result = await _classRepository.getAllClasses();

      return result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('수업 목록을 불러오는데 실패했습니다: ${failure.message}')),
          );
          return [];
        },
        (classesList) {
          // 이미 수강 중인 수업 필터링
          final myClassIds = _classes.map((c) => c.id).toSet();
          return classesList.where((c) => !myClassIds.contains(c.id)).toList();
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('수업 목록을 불러오는데 실패했습니다: $e')));
      return [];
    }
  }

  // WeekDay 열거형을 텍스트로 변환하는 메서드
  String _getWeekdayText(WeekDay weekDay) {
    switch (weekDay) {
      case WeekDay.monday:
        return '월요일';
      case WeekDay.tuesday:
        return '화요일';
      case WeekDay.wednesday:
        return '수요일';
      case WeekDay.thursday:
        return '목요일';
      case WeekDay.friday:
        return '금요일';
      case WeekDay.saturday:
        return '토요일';
      case WeekDay.sunday:
        return '일요일';
    }
  }

  // 시간표 수정 다이얼로그
  void _showEditClassDialog(BuildContext context, Class classData) {
    final nameController = TextEditingController(text: classData.name);
    final locationController = TextEditingController(
      text: classData.location ?? '',
    );
    WeekDay selectedDay = classData.weekDay;
    String startTime = classData.startTime;
    String endTime = classData.endTime;

    // 학생 목록 복사본 생성 - 원본 유지를 위해
    final List<String> studentIdsCopy = List<String>.from(classData.studentIds);

    debugPrint(
      '수업 수정 다이얼로그 열기: ${classData.id}, 현재 학생 수: ${studentIdsCopy.length}',
    );

    // 시간 선택 옵션
    final timeOptions = [
      '08:00',
      '08:30',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '12:00',
      '12:30',
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
      '17:00',
      '17:30',
      '18:00',
      '18:30',
      '19:00',
      '19:30',
      '20:00',
      '20:30',
      '21:00',
      '21:30',
      '22:00',
    ];

    // 요일 선택 옵션
    final weekDayOptions = {
      WeekDay.monday: '월요일',
      WeekDay.tuesday: '화요일',
      WeekDay.wednesday: '수요일',
      WeekDay.thursday: '목요일',
      WeekDay.friday: '금요일',
      WeekDay.saturday: '토요일',
      WeekDay.sunday: '일요일',
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('수업 정보 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: '수업명',
                      hintText: '수업 이름을 입력하세요',
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                    ),
                    AppSpacing.verticalSpaceMD,
                    AppTextField(
                      label: '장소',
                      hintText: '강의실 또는 장소를 입력하세요',
                      controller: locationController,
                      textInputAction: TextInputAction.next,
                    ),
                    AppSpacing.verticalSpaceMD,
                    Text('요일', style: AppTypography.label(context)),
                    AppSpacing.verticalSpaceSM,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.backgroundSecondaryDark
                                : AppColors.backgroundSecondaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<WeekDay>(
                          isExpanded: true,
                          value: selectedDay,
                          items:
                              weekDayOptions.entries.map((entry) {
                                return DropdownMenuItem<WeekDay>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedDay = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpaceMD,
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '시작 시간',
                                style: AppTypography.label(context),
                              ),
                              AppSpacing.verticalSpaceSM,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.backgroundSecondaryDark
                                          : AppColors.backgroundSecondaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: startTime,
                                    items:
                                        timeOptions.map((time) {
                                          return DropdownMenuItem<String>(
                                            value: time,
                                            child: Text(time),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          startTime = value;
                                          // 시작 시간이 종료 시간보다 늦으면 종료 시간 자동 조정
                                          if (timeOptions.indexOf(startTime) >=
                                              timeOptions.indexOf(endTime)) {
                                            final nextIndex =
                                                timeOptions.indexOf(startTime) +
                                                1;
                                            if (nextIndex <
                                                timeOptions.length) {
                                              endTime = timeOptions[nextIndex];
                                            }
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.horizontalSpaceSM,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '종료 시간',
                                style: AppTypography.label(context),
                              ),
                              AppSpacing.verticalSpaceSM,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.backgroundSecondaryDark
                                          : AppColors.backgroundSecondaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: endTime,
                                    // 시작 시간 이후의 시간만 선택 가능하도록
                                    items:
                                        timeOptions
                                            .where(
                                              (time) =>
                                                  timeOptions.indexOf(time) >
                                                  timeOptions.indexOf(
                                                    startTime,
                                                  ),
                                            )
                                            .map((time) {
                                              return DropdownMenuItem<String>(
                                                value: time,
                                                child: Text(time),
                                              );
                                            })
                                            .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          endTime = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalSpaceMD,
                    // 학생 수 표시
                    Text(
                      '현재 수강 학생 수: ${studentIdsCopy.length}명',
                      style: AppTypography.body(context),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                AppButton(
                  text: '저장',
                  type: ButtonType.primary,
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('수업명을 입력해주세요')),
                      );
                      return;
                    }

                    // 업데이트할 수업 데이터 생성 전에 학생 목록 로깅
                    debugPrint('수업 업데이트 전 학생 ID 목록: $studentIdsCopy');

                    // 수정된 수업 정보 생성
                    final updatedClass = Class(
                      id: classData.id,
                      name: nameController.text.trim(),
                      professorId: classData.professorId,
                      location:
                          locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                      weekDay: selectedDay,
                      startTime: startTime,
                      endTime: endTime,
                      status: classData.status,
                      studentIds: studentIdsCopy, // 복사본 사용하여 학생 목록 유지
                      createdAt: classData.createdAt,
                      lastUpdatedAt: DateTime.now(), // 현재 시간으로 업데이트 시간 설정
                    );

                    debugPrint(
                      '수업 업데이트할 내용 - 학생 수: ${updatedClass.studentIds.length}',
                    );

                    Navigator.of(context).pop();

                    // 로딩 시작 - 부모 위젯의 setState 사용
                    if (mounted) {
                      this.setState(() {
                        _isLoading = true;
                      });
                    }

                    try {
                      // 데이터베이스에 저장
                      final result = await _classRepository.updateClass(
                        updatedClass,
                      );

                      // mounted 체크를 통해 위젯이 아직 존재하는지 확인
                      if (mounted) {
                        this.setState(() {
                          _isLoading = false;

                          // Firestore 업데이트가 완료되면 리스너에 의해 UI가 업데이트됨
                          // 실시간 업데이트를 기다리지 않고 즉시 로컬 UI 갱신
                          // 기존 클래스 목록에서 업데이트된 클래스 찾아 교체
                          final index = _classes.indexWhere(
                            (c) => c.id == updatedClass.id,
                          );
                          if (index >= 0) {
                            _classes[index] = updatedClass;
                          }
                        });

                        result.fold(
                          (failure) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('수정 실패: ${failure.message}'),
                              ),
                            );
                          },
                          (_) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('수업 정보가 수정되었습니다')),
                            );
                          },
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        this.setState(() {
                          _isLoading = false;
                        });

                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
