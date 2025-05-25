import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/typography.dart';
import '../../../domain/models/class_model.dart';
import '../../../domain/entities/user.dart' show UserEntityRole;
import '../../../data/models/user_model.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_loading_indicator.dart';

/// 교수용 강의 목록 화면 위젯
class ProfessorClassListScreen extends StatefulWidget {
  const ProfessorClassListScreen({super.key});

  @override
  State<ProfessorClassListScreen> createState() =>
      _ProfessorClassListScreenState();
}

class _ProfessorClassListScreenState extends State<ProfessorClassListScreen> {
  bool _isLoading = true;
  List<ClassModel> _classes = [];
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  /// 강의 목록을 불러옵니다.
  Future<void> _loadClasses() async {
    // 실제 구현에서는 Provider나 Bloc 등을 사용하여 데이터를 관리해야 합니다.
    // 여기서는 간단한 예시 구현입니다.
    setState(() {
      _isLoading = true;
    });

    // 임시 데이터 생성 (실제 구현에서는 repository에서 데이터를 가져와야 함)
    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();

    _classes = [
      ClassModel(
        id: '1',
        name: '인공지능 기초',
        professorId: 'prof001',
        professorName: '홍길동',
        location: '공학관 201호',
        description: '인공지능의 기본 개념과 응용에 대해 학습합니다.',
        schedule: [
          {'day': '월', 'startTime': '09:00', 'endTime': '12:00'},
        ],
        studentIds: ['student001', 'student002', 'student003'],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      ClassModel(
        id: '2',
        name: '기계학습',
        professorId: 'prof001',
        professorName: '홍길동',
        location: '공학관 302호',
        description: '머신러닝 알고리즘과 데이터 분석 기법을 학습합니다.',
        schedule: [
          {'day': '수', 'startTime': '13:00', 'endTime': '16:00'},
        ],
        studentIds: ['student002', 'student004', 'student005'],
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now,
      ),
      ClassModel(
        id: '3',
        name: '컴퓨터 네트워크',
        professorId: 'prof001',
        professorName: '홍길동',
        location: '공학관 103호',
        description: '네트워크 프로토콜과 인터넷 아키텍처에 대해 학습합니다.',
        schedule: [
          {'day': '금', 'startTime': '09:00', 'endTime': '12:00'},
        ],
        studentIds: ['student001', 'student003', 'student006'],
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  /// 새 강의를 추가하는 다이얼로그를 표시합니다.
  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddEditClassDialog(),
    ).then((added) {
      if (added == true) {
        _loadClasses();
      }
    });
  }

  /// 강의를 편집하는 다이얼로그를 표시합니다.
  void _showEditClassDialog(ClassModel classModel) {
    showDialog(
      context: context,
      builder: (context) => _AddEditClassDialog(classModel: classModel),
    ).then((edited) {
      if (edited == true) {
        _loadClasses();
      }
    });
  }

  /// 강의 삭제 확인 다이얼로그를 표시합니다.
  void _showDeleteConfirmationDialog(ClassModel classModel) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('강의 삭제'),
            content: Text('정말로 \'${classModel.name}\' 강의를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                child: const Text('취소'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('삭제'),
                onPressed: () {
                  // 실제 구현에서는 repository를 통해 삭제를 수행합니다.
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
    ).then((deleted) {
      if (deleted == true) {
        // 강의 삭제 후 목록 새로고침
        _loadClasses();
      }
    });
  }

  /// 강의 상세 정보 화면으로 이동합니다.
  void _navigateToClassDetail(ClassModel classModel) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => _ClassDetailScreen(classModel: classModel),
          ),
        )
        .then((_) {
          // 돌아왔을 때 목록 새로고침
          _loadClasses();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 강의 목록'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadClasses),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: AppLoadingIndicator())
              : _classes.isEmpty
              ? _buildEmptyState()
              : _buildClassList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        tooltip: '새 강의 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 강의가 없을 때 표시할 위젯을 생성합니다.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.class_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: AppSpacing.md),
          Text('등록된 강의가 없습니다', style: AppTypography.headline3(context)),
          const SizedBox(height: AppSpacing.sm),
          Text('새 강의를 추가해보세요', style: AppTypography.body(context)),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: '강의 추가',
            onPressed: _showAddClassDialog,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  /// 강의 목록을 표시하는 위젯을 생성합니다.
  Widget _buildClassList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classModel = _classes[index];
        return _buildClassCard(classModel);
      },
    );
  }

  /// 개별 강의 카드를 생성합니다.
  Widget _buildClassCard(ClassModel classModel) {
    final schedule =
        classModel.schedule.isNotEmpty ? classModel.schedule.first : null;
    final dayText = schedule != null ? schedule['day'] : '-';
    final timeText =
        schedule != null
            ? '${schedule['startTime']} - ${schedule['endTime']}'
            : '-';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () => _navigateToClassDetail(classModel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  classModel.name,
                  style: AppTypography.subhead(context),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditClassDialog(classModel);
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(classModel);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('편집'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('삭제'),
                          ],
                        ),
                      ),
                    ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '위치: ${classModel.location}',
            style: AppTypography.body(context),
          ),
          Text('일정: $dayText $timeText', style: AppTypography.body(context)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '학생: ${classModel.studentIds.length}명',
                style: AppTypography.small(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            classModel.description,
            style: AppTypography.body(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 강의 추가/편집 다이얼로그
class _AddEditClassDialog extends StatefulWidget {
  final ClassModel? classModel;

  const _AddEditClassDialog({this.classModel});

  @override
  _AddEditClassDialogState createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<_AddEditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dayController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;

  String? _professorId;
  String? _professorName;
  List<String> _studentIds = [];

  @override
  void initState() {
    super.initState();
    final classModel = widget.classModel;
    _nameController = TextEditingController(text: classModel?.name ?? '');
    _locationController = TextEditingController(
      text: classModel?.location ?? '',
    );
    _descriptionController = TextEditingController(
      text: classModel?.description ?? '',
    );

    final schedule =
        classModel?.schedule.isNotEmpty == true
            ? classModel!.schedule.first
            : null;
    _dayController = TextEditingController(text: schedule?['day'] ?? '');
    _startTimeController = TextEditingController(
      text: schedule?['startTime'] ?? '',
    );
    _endTimeController = TextEditingController(
      text: schedule?['endTime'] ?? '',
    );

    _professorId = classModel?.professorId;
    _professorName = classModel?.professorName;
    _studentIds = classModel?.studentIds.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _dayController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // 실제 구현에서는 repository를 통해 저장합니다.
    // 여기서는 임시로 다이얼로그를 닫습니다.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.classModel != null;
    final title = isEditing ? '강의 수정' : '새 강의 추가';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '강의명',
                  hintText: '강의 이름을 입력하세요',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '강의명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '강의실',
                  hintText: '강의실 위치를 입력하세요',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '강의실 위치를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '강의 설명',
                  hintText: '강의에 대한 설명을 입력하세요',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('강의 일정', style: AppTypography.subhead(context)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dayController,
                      decoration: const InputDecoration(
                        labelText: '요일',
                        hintText: '예: 월, 화, 수',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '요일을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: '시작 시간',
                        hintText: '09:00',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '시작 시간을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: '종료 시간',
                        hintText: '12:00',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '종료 시간을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(onPressed: _submit, child: Text(isEditing ? '수정' : '추가')),
      ],
    );
  }
}

/// 강의 상세 정보 화면
class _ClassDetailScreen extends StatefulWidget {
  final ClassModel classModel;

  const _ClassDetailScreen({required this.classModel});

  @override
  State<_ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<_ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<UserModel> _students = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 수강생 정보를 불러옵니다.
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: 실제 데이터베이스에서 학생 목록을 가져오는 로직 구현
    await Future.delayed(const Duration(seconds: 1)); // 가짜 로딩 시간

    // 테스트용 데이터
    _students = [
      UserModel(
        id: 'student001',
        name: '김학생',
        email: 'student1@example.com',
        role: UserEntityRole.student,
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'student002',
        name: '이학생',
        email: 'student2@example.com',
        role: UserEntityRole.student,
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'student003',
        name: '박학생',
        email: 'student3@example.com',
        role: UserEntityRole.student,
        createdAt: DateTime.now(),
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classModel.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '정보'), Tab(text: '학생 관리'), Tab(text: '출석 기록')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInfoTab(), _buildStudentsTab(), _buildAttendanceTab()],
      ),
    );
  }

  /// 강의 정보 탭을 생성합니다.
  Widget _buildInfoTab() {
    final schedule =
        widget.classModel.schedule.isNotEmpty
            ? widget.classModel.schedule.first
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('강의 정보', style: AppTypography.subhead(context)),
                const SizedBox(height: AppSpacing.md),
                _buildInfoRow('강의명', widget.classModel.name),
                _buildInfoRow('강의실', widget.classModel.location),
                _buildInfoRow('담당 교수', widget.classModel.professorName),
                if (schedule != null) ...[
                  _buildInfoRow(
                    '강의 시간',
                    '${schedule['day']}요일 ${schedule['startTime']} - ${schedule['endTime']}',
                  ),
                ],
                _buildInfoRow(
                  '수강생 수',
                  '${widget.classModel.studentIds.length}명',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('강의 설명', style: AppTypography.subhead(context)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.classModel.description,
                  style: AppTypography.body(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: '강의 편집',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => _AddEditClassDialog(
                            classModel: widget.classModel,
                          ),
                    ).then((edited) {
                      if (edited == true) {
                        // 변경사항을 반영하기 위해 전 화면으로 돌아갑니다.
                        Navigator.of(context).pop();
                      }
                    });
                  },
                  icon: Icons.edit,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  text: '출석 관리',
                  onPressed: () {
                    // 출석 관리 화면으로 이동
                    _tabController.animateTo(2);
                  },
                  icon: Icons.how_to_reg,
                  type: ButtonType.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 정보 행을 생성합니다.
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.body(
                context,
              ).copyWith(color: Colors.grey[700]),
            ),
          ),
          Expanded(child: Text(value, style: AppTypography.body(context))),
        ],
      ),
    );
  }

  /// 학생 관리 탭을 생성합니다.
  Widget _buildStudentsTab() {
    return _isLoading
        ? const Center(child: AppLoadingIndicator())
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '수강생 목록 (${_students.length}명)',
                    style: AppTypography.subhead(context),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 학생 추가 다이얼로그 표시
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('학생 추가'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryColor,
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name.substring(0, 1)
                            : 'S',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      student.name,
                      style: AppTypography.body(context),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        // 학생 제거 확인 다이얼로그 표시
                      },
                    ),
                    onTap: () {
                      // 학생 상세 정보 표시
                    },
                  );
                },
              ),
            ),
          ],
        );
  }

  /// 출석 기록 탭을 생성합니다.
  Widget _buildAttendanceTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.date_range, size: 64, color: Colors.grey),
          const SizedBox(height: AppSpacing.md),
          Text('출석 관리', style: AppTypography.subhead(context)),
          const SizedBox(height: AppSpacing.sm),
          Text('수업일을 선택하여 출석을 관리하세요', style: AppTypography.body(context)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                text: '금일 출석 관리',
                onPressed: () {
                  // 출석 관리 화면으로 이동
                },
                icon: Icons.how_to_reg,
              ),
              const SizedBox(width: AppSpacing.md),
              AppButton(
                text: '출석 기록 조회',
                onPressed: () {
                  // 출석 기록 조회 화면으로 이동
                },
                icon: Icons.history,
                type: ButtonType.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
