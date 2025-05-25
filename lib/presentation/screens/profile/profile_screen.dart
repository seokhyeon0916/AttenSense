import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:capston_design/core/constants/spacing.dart';
import 'package:capston_design/core/constants/colors.dart';
import 'package:capston_design/core/constants/typography.dart';
import 'package:capston_design/presentation/providers/auth_provider.dart';
import 'package:capston_design/widgets/app_button.dart';
import 'package:capston_design/widgets/app_card.dart';
import 'package:capston_design/widgets/app_text_field.dart';
import 'package:capston_design/widgets/app_divider.dart';
import 'package:capston_design/presentation/screens/settings/settings_screen.dart';
import 'package:capston_design/presentation/widgets/app_bar_back_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _departmentController;
  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  String? _profileImageUrl;
  bool _isSimulator = false;
  bool _didCheckSimulator = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _departmentController = TextEditingController();

    // 사용자 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didCheckSimulator) {
      _checkSimulator();
      _didCheckSimulator = true;
    }
  }

  Future<void> _checkSimulator() async {
    // iOS에서는 기본적으로 시뮬레이터일 확률 높음
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      setState(() {
        _isSimulator = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    final user = authProvider.currentUser;

    if (firebaseUser != null) {
      _nameController.text = user?.name ?? firebaseUser.displayName ?? '';
      _emailController.text = user?.email ?? firebaseUser.email ?? '';
      _phoneController.text = '010-1234-5678'; // 임시 데이터
      _departmentController.text =
          user?.isProfessor == true ? '컴퓨터공학과' : '컴퓨터공학과 3학년'; // 임시 데이터

      setState(() {
        _profileImageUrl = firebaseUser.photoURL;
      });
    }
  }

  Future<void> _selectImage() async {
    try {
      // 먼저 카메라 롤이나 갤러리에 접근 가능한지 확인
      bool canAccessGallery = true;

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        // iOS 시뮬레이터 감지 로직을 삭제하고 모든 iOS 기기에서 동일한 방식으로 처리
        try {
          // 시뮬레이터와 실제 기기 모두 동일한 방식으로 처리
          final picker = ImagePicker();
          final XFile? testPickFile = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 100, // 테스트용으로 작은 크기
            imageQuality: 10, // 낮은 품질
          );

          // 만약 이미지를 가져오는데 성공했다면, 실제 이미지를 선택할 수 있게 함
          if (testPickFile != null) {
            _processImage(testPickFile);
            return;
          } else {
            // 사용자가 취소한 경우
            return;
          }
        } catch (e) {
          // 이미지 선택 중 오류 발생 - 갤러리 접근 불가
          print('갤러리 접근 오류: $e');
          canAccessGallery = false;
        }
      }

      // 갤러리 접근이 가능하면 일반적인 이미지 선택 대화상자 표시
      if (canAccessGallery) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('프로필 이미지 선택'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('갤러리에서 선택'),
                      onTap: () {
                        Navigator.pop(context);
                        _getImageFromSource(ImageSource.gallery);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('기본 아바타 생성'),
                      onTap: () {
                        Navigator.pop(context);
                        _createVirtualAvatar();
                      },
                    ),
                  ],
                ),
              ),
        );
      } else {
        // 갤러리 접근이 불가능한 경우 (iOS 시뮬레이터 등)
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('프로필 이미지 선택'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('갤러리에 접근할 수 없습니다. 기본 아바타를 사용하시겠습니까?'),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('기본 아바타 생성'),
                      onTap: () {
                        Navigator.pop(context);
                        _createVirtualAvatar();
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('취소'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('이미지 선택 프로세스 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 선택한 이미지 처리를 위한 새 메소드
  Future<void> _processImage(XFile imageFile) async {
    setState(() {
      _imageFile = File(imageFile.path);
      _isLoading = true;
    });

    try {
      await _uploadImage();
    } catch (e) {
      print('이미지 업로드 실패: $e');
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 업로드 중 오류가 발생했습니다: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _getImageFromSource(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final picker = ImagePicker();

      // source 매개변수 사용
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _processImage(pickedFile);
      } else {
        // 사용자가 이미지 선택을 취소한 경우
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // 오류 발생 시 기본 아바타 사용 제안
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('이미지 선택 실패'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('이미지 선택 중 오류가 발생했습니다: $e'),
                  const SizedBox(height: 16),
                  const Text('기본 아바타를 사용하시겠습니까?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _createVirtualAvatar();
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _createVirtualAvatar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자 이름 기반 아바타 URL 생성
      final userName =
          _nameController.text.isNotEmpty ? _nameController.text : '사용자';
      final encodedName = Uri.encodeComponent(userName);
      final sampleImageUrl =
          'https://ui-avatars.com/api/?name=$encodedName&size=200&background=random&color=fff';

      if (_isSimulator || kIsWeb) {
        // 시뮬레이터나 웹 환경에서는 URL만 사용
        await _updateProfileUrl(sampleImageUrl);
      } else {
        // 실제 기기에서는 이미지를 다운로드하여 Firebase에 업로드
        await _downloadAndUploadImage(sampleImageUrl);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필 이미지가 업데이트되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('가상 아바타 생성 오류: $e');
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 이미지 업데이트 실패: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadAndUploadImage(String imageUrl) async {
    try {
      // 이미지 URL에서 이미지 다운로드
      final response = await http.get(Uri.parse(imageUrl));

      // 임시 디렉토리 가져오기
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/temp_avatar.jpg';

      // 파일로 저장
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(response.bodyBytes);

      // 파일 업로드
      setState(() {
        _imageFile = tempFile;
      });

      await _uploadImage();
    } catch (e) {
      print('이미지 다운로드 및 업로드 오류: $e');
      // 실패하면 URL만 업데이트
      await _updateProfileUrl(imageUrl);
    }
  }

  Future<void> _updateProfileUrl(String imageUrl) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePhotoURL(imageUrl);
      }

      setState(() {
        _profileImageUrl = imageUrl;
        _isLoading = false;
      });
    } catch (e) {
      print('프로필 URL 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      // 이미지 업로드 시작 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지 업로드 중...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Firebase Storage에 이미지 업로드
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profileImages')
          .child('${user.uid}.jpg');

      // 파일 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': user.uid,
          'date': DateTime.now().toIso8601String(),
        },
      );

      // 이미지 업로드
      final uploadTask = storageRef.putFile(_imageFile!, metadata);

      // 업로드 진행 상황 모니터링
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        print('업로드 진행률: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // 업로드 완료 대기
      await uploadTask;

      // 다운로드 URL 가져오기
      final downloadUrl = await storageRef.getDownloadURL();

      // 프로필 URL 업데이트
      await _updateProfileUrl(downloadUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필 이미지가 업데이트되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('이미지 업로드 오류: $e');
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      // 업로드 실패 시 가상 아바타 생성 제안
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('업로드 실패'),
              content: const Text('이미지 업로드 중 오류가 발생했습니다. 기본 아바타를 사용하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _createVirtualAvatar();
                  },
                  child: const Text('기본 아바타 사용'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    final user = authProvider.currentUser;

    if (firebaseUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = user?.name ?? firebaseUser.displayName ?? '사용자';
    final isProfessor = user?.isProfessor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: '설정',
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // 편집 취소
                  _loadUserData();
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    // 프로필 이미지 및 업로드 버튼
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primaryColor.withOpacity(
                              0.1,
                            ),
                            backgroundImage:
                                _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                            child:
                                _profileImageUrl == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.primaryColor,
                                    )
                                    : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _selectImage,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.verticalSpaceLG,

                    _buildProfileHeader(context, userName, isProfessor),
            AppSpacing.verticalSpaceLG,
            _isEditing
                ? _buildEditProfileForm(context)
                        : _buildProfileInfo(context, isProfessor),
          ],
        ),
      ),
      bottomNavigationBar:
          _isEditing
              ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton(
                    text: '변경사항 저장',
                    onPressed: _saveChanges,
                    isFullWidth: true,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    bool isProfessor,
  ) {
    return Center(
      child: Column(
        children: [
          Text(name, style: AppTypography.headline2(context)),
          AppSpacing.verticalSpaceXS,
          Text(
            isProfessor ? '교수' : '학생',
            style: AppTypography.body(context).copyWith(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, bool isProfessor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기본 정보', style: AppTypography.headline3(context)),
        AppSpacing.verticalSpaceMD,
        AppCard(
          child: Column(
            children: [
              _buildInfoItem(context, '이름', _nameController.text),
              const AppDivider(),
              _buildInfoItem(context, '이메일', _emailController.text),
              const AppDivider(),
              _buildInfoItem(context, '연락처', _phoneController.text),
              const AppDivider(),
              _buildInfoItem(
                context,
                isProfessor ? '소속' : '학과/학년',
                _departmentController.text,
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpaceLG,
        Text(
          isProfessor ? '담당 수업' : '수강 과목',
          style: AppTypography.headline3(context),
        ),
        AppSpacing.verticalSpaceMD,
        _buildClassesList(context, isProfessor),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.label(context)),
          Text(value, style: AppTypography.body(context)),
        ],
      ),
    );
  }

  Widget _buildClassesList(BuildContext context, bool isProfessor) {
    // 임시 데이터
    final classes =
        isProfessor
            ? ['캡스톤 디자인', '데이터베이스', '인공지능']
            : ['캡스톤 디자인', '데이터베이스', '인공지능', '모바일 프로그래밍'];

    return AppCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: classes.length,
        separatorBuilder: (_, __) => const AppDivider(),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(classes[index]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 수업 상세 화면으로 이동
            },
          );
        },
      ),
    );
  }

  Widget _buildEditProfileForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기본 정보 수정', style: AppTypography.headline3(context)),
        AppSpacing.verticalSpaceMD,
        AppTextField(
          label: '이름',
          controller: _nameController,
          keyboardType: TextInputType.name,
        ),
        AppSpacing.verticalSpaceMD,
        AppTextField(
          label: '이메일',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          readOnly: true, // 이메일은 변경 불가
          hintText: '이메일은 변경할 수 없습니다',
        ),
        AppSpacing.verticalSpaceMD,
        AppTextField(
          label: '연락처',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        AppSpacing.verticalSpaceMD,
        AppTextField(
          label: '소속/학과',
          controller: _departmentController,
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  void _saveChanges() {
    // 여기에 사용자 정보 업데이트 로직 구현
    // 지금은 간단히 편집 모드만 종료
    setState(() {
      _isEditing = false;
    });

    // 저장 성공 알림 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필이 업데이트되었습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
