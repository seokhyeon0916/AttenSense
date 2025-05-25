/// 입력 데이터 유효성 검사를 위한 정적 메서드를 제공하는 클래스
class Validators {
  /// 이메일 유효성 검사
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요.';
    }

    // 이메일 형식 검사를 위한 정규식
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegExp.hasMatch(value)) {
      return '유효한 이메일 주소를 입력해주세요.';
    }

    return null;
  }

  /// 비밀번호 유효성 검사
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (value.length < 6) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }

    return null;
  }

  /// 이름 유효성 검사
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요.';
    }

    if (value.trim().length < 2) {
      return '이름은 최소 2자 이상이어야 합니다.';
    }

    return null;
  }

  /// 비밀번호 확인 일치 여부 검사
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }

    if (value != password) {
      return '비밀번호가 일치하지 않습니다.';
    }

    return null;
  }

  /// 빈 필드 검사
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력해주세요.';
    }

    return null;
  }
}
