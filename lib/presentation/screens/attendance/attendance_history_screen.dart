import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/widgets/app_button.dart';
import 'package:capston_design/widgets/app_divider.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 출석 기록을 조회하는 화면
/// 교수는 전체 학생의 출석을 볼 수 있고, 학생은 자신의 출석만 볼 수 있음
class AttendanceHistoryScreen extends StatefulWidget {
  final String classId;
  final String className;

  const AttendanceHistoryScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final List<Map<String, dynamic>> _attendanceHistory = [
    {
      'date': DateTime.now().subtract(const Duration(days: 0)),
      'title': '2023년 2학기 15주차',
      'present': 28,
      'absent': 2,
      'total': 30,
      'students': [
        {
          'id': 'student1',
          'name': '홍길동',
          'studentId': '2020123456',
          'status': 'present', // present, late, absent
          'checkInTime': '09:05',
          'duration': '2시간 55분',
        },
        {
          'id': 'student2',
          'name': '김철수',
          'studentId': '2020654321',
          'status': 'late',
          'checkInTime': '09:25',
          'duration': '2시간 35분',
        },
        {
          'id': 'student3',
          'name': '이영희',
          'studentId': '2020345678',
          'status': 'absent',
          'checkInTime': '-',
          'duration': '-',
        },
      ],
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'title': '2023년 2학기 14주차',
      'present': 29,
      'absent': 1,
      'total': 30,
      'students': [
        {
          'id': 'student1',
          'name': '홍길동',
          'studentId': '2020123456',
          'status': 'present',
          'checkInTime': '09:02',
          'duration': '2시간 58분',
        },
        {
          'id': 'student2',
          'name': '김철수',
          'studentId': '2020654321',
          'status': 'present',
          'checkInTime': '09:05',
          'duration': '2시간 55분',
        },
        {
          'id': 'student3',
          'name': '이영희',
          'studentId': '2020345678',
          'status': 'absent',
          'checkInTime': '-',
          'duration': '-',
        },
      ],
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'title': '2023년 2학기 13주차',
      'present': 30,
      'absent': 0,
      'total': 30,
      'students': [
        {
          'id': 'student1',
          'name': '홍길동',
          'studentId': '2020123456',
          'status': 'present',
          'checkInTime': '09:01',
          'duration': '2시간 59분',
        },
        {
          'id': 'student2',
          'name': '김철수',
          'studentId': '2020654321',
          'status': 'present',
          'checkInTime': '09:03',
          'duration': '2시간 57분',
        },
        {
          'id': 'student3',
          'name': '이영희',
          'studentId': '2020345678',
          'status': 'present',
          'checkInTime': '09:10',
          'duration': '2시간 50분',
        },
      ],
    },
  ];

  String _selectedFilter = '전체';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isProfessor = false;

  @override
  void initState() {
    super.initState();
    // 로케일 데이터 초기화 (날짜 포맷팅을 위해 필요)
    initializeDateFormatting('ko_KR', null);

    // 사용자 정보 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _isProfessor = authProvider.currentUser?.isProfessor ?? false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} 출석 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: '날짜 선택',
          ),
          if (_isProfessor)
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportAttendanceData,
              tooltip: '출석 데이터 내보내기',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child:
                _attendanceHistory.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _attendanceHistory.length,
                      separatorBuilder:
                          (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _buildAttendanceCard(_attendanceHistory[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child:
                    _isSearching
                        ? TextField(
                          decoration: InputDecoration(
                            hintText: '이름 또는 학번 검색...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.sm,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchQuery = '';
                                });
                              },
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        )
                        : AppButton(
                          text: '검색',
                          icon: Icons.search,
                          type: ButtonType.secondary,
                          onPressed: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                        ),
              ),
              if (!_isSearching) ...[
                const SizedBox(width: AppSpacing.sm),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: '필터',
                  onSelected: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(value: '전체', child: Text('전체')),
                        const PopupMenuItem(value: '출석', child: Text('출석')),
                        const PopupMenuItem(value: '지각', child: Text('지각')),
                        const PopupMenuItem(value: '결석', child: Text('결석')),
                      ],
                ),
              ],
            ],
          ),
          if (_selectedFilter != '전체' || _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  if (_selectedFilter != '전체')
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Chip(
                        label: Text(_selectedFilter),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedFilter = '전체';
                          });
                        },
                      ),
                    ),
                  if (_searchQuery.isNotEmpty)
                    Chip(
                      label: Text(_searchQuery),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('출석 기록이 없습니다', style: AppTypography.headline3(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '아직 출석 데이터가 없거나 필터와 일치하는 결과가 없습니다.',
            style: AppTypography.body(context).copyWith(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> attendance) {
    final DateTime date = attendance['date'] as DateTime;
    final String title = attendance['title'] as String;
    final int present = attendance['present'] as int;
    final int total = attendance['total'] as int;
    final List<dynamic> students = attendance['students'] as List<dynamic>;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headline3(context)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(date),
                      style: AppTypography.small(context),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '출석: $present/$total',
                      style: AppTypography.subhead(
                        context,
                      ).copyWith(color: AppColors.successColor),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '출석률: ${(present / total * 100).toStringAsFixed(1)}%',
                      style: AppTypography.small(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isProfessor) ...[
            const AppDivider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('학생 목록', style: AppTypography.subhead(context)),
                  const SizedBox(height: AppSpacing.sm),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final student = students[index] as Map<String, dynamic>;
                      return _buildStudentAttendanceItem(student);
                    },
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showAttendanceDetails(attendance),
                  child: const Text('상세 보기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAttendanceItem(Map<String, dynamic> student) {
    final String name = student['name'] as String;
    final String studentId = student['studentId'] as String;
    final String status = student['status'] as String;
    final String checkInTime = student['checkInTime'] as String;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'present':
        statusColor = AppColors.successColor;
        statusIcon = Icons.check_circle;
        statusText = '출석';
        break;
      case 'late':
        statusColor = AppColors.warningColor;
        statusIcon = Icons.warning;
        statusText = '지각';
        break;
      case 'absent':
        statusColor = AppColors.errorColor;
        statusIcon = Icons.cancel;
        statusText = '결석';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = '미확인';
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('$name ($studentId)', style: AppTypography.body(context)),
        ),
        Text(
          statusText,
          style: AppTypography.small(
            context,
          ).copyWith(color: statusColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(checkInTime, style: AppTypography.small(context)),
      ],
    );
  }

  void _selectDateRange() async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      // 날짜 범위로 출석 기록 필터링
      // 실제 구현에서는 서버에서 데이터를 가져와야 함
      setState(() {
        // 임시 코드 - 날짜 범위에 맞게 필터링
      });
    }
  }

  void _exportAttendanceData() {
    // 출석 데이터 내보내기 기능
    // 실제 구현에서는 CSV 또는 엑셀 파일로 내보내기 기능 추가
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출석 데이터 내보내기 기능은 아직 개발 중입니다.')),
    );
  }

  void _showAttendanceDetails(Map<String, dynamic> attendance) {
    final DateTime date = attendance['date'] as DateTime;
    final String title = attendance['title'] as String;
    final List<dynamic> students = attendance['students'] as List<dynamic>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '출석 상세 정보',
                              style: AppTypography.headline3(context),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '$title - ${DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(date)}',
                              style: AppTypography.small(context),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const AppDivider(),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const AppDivider(),
                    itemBuilder: (context, index) {
                      final student = students[index] as Map<String, dynamic>;
                      return _buildDetailedStudentItem(student);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailedStudentItem(Map<String, dynamic> student) {
    final String name = student['name'] as String;
    final String studentId = student['studentId'] as String;
    final String status = student['status'] as String;
    final String checkInTime = student['checkInTime'] as String;
    final String duration = student['duration'] as String;

    Color statusColor;
    String statusText;

    switch (status) {
      case 'present':
        statusColor = AppColors.successColor;
        statusText = '출석';
        break;
      case 'late':
        statusColor = AppColors.warningColor;
        statusText = '지각';
        break;
      case 'absent':
        statusColor = AppColors.errorColor;
        statusText = '결석';
        break;
      default:
        statusColor = Colors.grey;
        statusText = '미확인';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                radius: 24,
                child: Icon(
                  status == 'present'
                      ? Icons.check_circle
                      : status == 'late'
                      ? Icons.watch_later
                      : Icons.cancel,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.subhead(context)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(studentId, style: AppTypography.small(context)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.small(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (status != 'absent') ...[
            _buildAttendanceDetailItem(
              context,
              '체크인 시간',
              checkInTime,
              Icons.access_time,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildAttendanceDetailItem(
              context,
              '수업 참여 시간',
              duration,
              Icons.timelapse,
            ),
          ] else
            _buildAttendanceDetailItem(context, '상태', '결석', Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildAttendanceDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ', style: AppTypography.small(context)),
        Text(value, style: AppTypography.body(context)),
      ],
    );
  }
}
