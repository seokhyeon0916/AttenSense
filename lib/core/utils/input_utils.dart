import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 앱 입력 필드 타입 정의
enum AppInputType {
  /// 일반 텍스트 입력
  text,

  /// 비밀번호 입력
  password,

  /// 이메일 입력
  email,

  /// 숫자 입력
  number,

  /// 전화번호 입력
  phone,

  /// 검색 필드
  search,

  /// 여러 줄 텍스트 입력
  multiline,
}

/// 앱 입력 필드 크기 정의
enum AppInputSize {
  /// 큰 크기 입력 필드
  large,

  /// 중간 크기 입력 필드
  medium,

  /// 작은 크기 입력 필드
  small,
}

/// 앱에서 사용하는 기본 입력 필드 컴포넌트
///
/// 다양한 입력 필드 유형과 크기를 지원하는 재사용 가능한 입력 필드 위젯입니다.
class AppTextField extends StatefulWidget {
  /// 입력 필드 컨트롤러
  final TextEditingController? controller;

  /// 입력 필드 포커스 노드
  final FocusNode? focusNode;

  /// 입력 필드 라벨
  final String? label;

  /// 입력 필드 힌트 텍스트
  final String? hint;

  /// 입력 필드 헬퍼 텍스트
  final String? helperText;

  /// 입력 필드 에러 텍스트
  final String? errorText;

  /// 입력 필드 유형
  final AppInputType type;

  /// 입력 필드 크기
  final AppInputSize size;

  /// 입력 필드 접두 아이콘
  final IconData? prefixIcon;

  /// 입력 필드 접미 아이콘
  final IconData? suffixIcon;

  /// 접미 아이콘 클릭 콜백
  final VoidCallback? onSuffixIconTap;

  /// 내용 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 제출 콜백
  final ValueChanged<String>? onSubmitted;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 자동 포커스 여부
  final bool autofocus;

  /// 읽기 전용 여부
  final bool readOnly;

  /// 비활성화 여부
  final bool disabled;

  /// 필수 입력 여부
  final bool required;

  /// 최대 길이
  final int? maxLength;

  /// 최대 줄 수
  final int? maxLines;

  /// 최소 줄 수
  final int? minLines;

  /// 입력 포맷터
  final List<TextInputFormatter>? inputFormatters;

  /// 키보드 타입
  final TextInputType? keyboardType;

  /// 텍스트 대문자화 타입
  final TextCapitalization textCapitalization;

  /// 자동 수정 여부
  final bool autocorrect;

  /// 내용 정렬
  final TextAlign textAlign;

  /// 테두리 색상
  final Color? borderColor;

  /// 배경 색상
  final Color? backgroundColor;

  /// 채워진 여부
  final bool filled;

  /// 라벨 스타일
  final TextStyle? labelStyle;

  /// 입력 스타일
  final TextStyle? textStyle;

  /// 자동 완성 여부
  final bool? enableSuggestions;

  /// 테두리 반경
  final double borderRadius;

  /// 접미사 위젯
  final Widget? suffix;

  /// 접두사 위젯
  final Widget? prefix;

  /// 초기값
  final String? initialValue;

  /// 입력 검증
  final String? Function(String?)? validator;

  /// 입력 필드 생성자
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.type = AppInputType.text,
    this.size = AppInputSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.readOnly = false,
    this.disabled = false,
    this.required = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.textAlign = TextAlign.start,
    this.borderColor,
    this.backgroundColor,
    this.filled = true,
    this.labelStyle,
    this.textStyle,
    this.enableSuggestions,
    this.borderRadius = 8.0,
    this.suffix,
    this.prefix,
    this.initialValue,
    this.validator,
  });

  @override
  _AppTextFieldState createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  late TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.type == AppInputType.password;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);

    if (widget.focusNode != null) {
      widget.focusNode!.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode != null) {
      widget.focusNode!.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.focusNode != null) {
      setState(() {
        _hasFocus = widget.focusNode!.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // 입력 필드 크기 설정
    double fontSize;
    double iconSize;
    double contentPadding;

    switch (widget.size) {
      case AppInputSize.large:
        fontSize = 16.0;
        iconSize = 24.0;
        contentPadding = 16.0;
        break;
      case AppInputSize.medium:
        fontSize = 14.0;
        iconSize = 20.0;
        contentPadding = 12.0;
        break;
      case AppInputSize.small:
        fontSize = 12.0;
        iconSize = 18.0;
        contentPadding = 8.0;
        break;
    }

    // 입력 유형에 따른 키보드 설정
    TextInputType effectiveKeyboardType =
        widget.keyboardType ?? _getKeyboardType();
    List<TextInputFormatter> effectiveInputFormatters =
        widget.inputFormatters ?? [];

    // 입력 유형에 따른 포맷터 추가
    if (widget.type == AppInputType.number) {
      effectiveInputFormatters.add(FilteringTextInputFormatter.digitsOnly);
    } else if (widget.type == AppInputType.phone) {
      effectiveInputFormatters.add(FilteringTextInputFormatter.digitsOnly);
    }

    // 최대 줄 수 설정
    int? effectiveMaxLines = widget.maxLines;
    int? effectiveMinLines = widget.minLines;

    if (widget.type == AppInputType.multiline) {
      effectiveMaxLines = widget.maxLines ?? 5;
      effectiveMinLines = widget.minLines ?? 3;
    } else if (widget.type == AppInputType.password) {
      effectiveMaxLines = 1;
      effectiveMinLines = 1;
    }

    // 접미사 아이콘 설정
    Widget? suffixIconWidget;

    if (widget.suffix != null) {
      suffixIconWidget = widget.suffix;
    } else if (widget.suffixIcon != null) {
      suffixIconWidget = InkWell(
        onTap: widget.onSuffixIconTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            widget.suffixIcon,
            size: iconSize,
            color:
                widget.disabled
                    ? theme.disabledColor
                    : Theme.of(context).iconTheme.color,
          ),
        ),
      );
    } else if (widget.type == AppInputType.password) {
      suffixIconWidget = InkWell(
        onTap: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: iconSize,
            color:
                _hasFocus
                    ? theme.primaryColor
                    : Theme.of(context).iconTheme.color,
          ),
        ),
      );
    } else if (widget.type == AppInputType.search &&
        _controller.text.isNotEmpty) {
      suffixIconWidget = InkWell(
        onTap: () {
          _controller.clear();
          if (widget.onChanged != null) {
            widget.onChanged!('');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.close,
            size: iconSize,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      );
    }

    // 접두사 아이콘 설정
    Widget? prefixIconWidget;

    if (widget.prefix != null) {
      prefixIconWidget = widget.prefix;
    } else if (widget.prefixIcon != null) {
      prefixIconWidget = Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          widget.prefixIcon,
          size: iconSize,
          color:
              widget.disabled
                  ? theme.disabledColor
                  : Theme.of(context).iconTheme.color,
        ),
      );
    } else if (widget.type == AppInputType.search) {
      prefixIconWidget = Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          Icons.search,
          size: iconSize,
          color: Theme.of(context).iconTheme.color,
        ),
      );
    }

    // 라벨 설정
    Widget? labelWidget;
    if (widget.label != null) {
      labelWidget = Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Text(
              widget.label!,
              style:
                  widget.labelStyle ??
                  TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color:
                        widget.disabled
                            ? theme.disabledColor
                            : isDarkMode
                            ? Colors.white70
                            : Colors.black87,
                  ),
            ),
            if (widget.required)
              Text(
                ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      );
    }

    // 입력 필드 배경색 설정
    Color effectiveBackgroundColor =
        widget.backgroundColor ??
        (isDarkMode
            ? theme.canvasColor.withOpacity(0.1)
            : theme.canvasColor.withOpacity(0.05));

    if (widget.disabled) {
      effectiveBackgroundColor =
          isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03);
    }

    // 테두리 색상 설정
    Color effectiveBorderColor =
        widget.borderColor ??
        (widget.errorText != null
            ? theme.colorScheme.error
            : _hasFocus
            ? theme.primaryColor
            : theme.dividerColor);

    if (widget.disabled) {
      effectiveBorderColor = theme.dividerColor.withOpacity(0.3);
    }

    // 입력 필드 위젯 생성
    final textField = TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      style:
          widget.textStyle ??
          TextStyle(
            fontSize: fontSize,
            color:
                widget.disabled
                    ? theme.disabledColor
                    : isDarkMode
                    ? Colors.white
                    : Colors.black87,
          ),
      decoration: InputDecoration(
        filled: widget.filled,
        fillColor: effectiveBackgroundColor,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        hintStyle: TextStyle(fontSize: fontSize, color: theme.hintColor),
        contentPadding: EdgeInsets.all(contentPadding),
        suffixIcon: suffixIconWidget,
        prefixIcon: prefixIconWidget,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: effectiveBorderColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: effectiveBorderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        errorStyle: TextStyle(
          fontSize: fontSize - 2,
          color: theme.colorScheme.error,
        ),
        helperStyle: TextStyle(
          fontSize: fontSize - 2,
          color: isDarkMode ? Colors.white60 : Colors.black54,
        ),
      ),
      keyboardType: effectiveKeyboardType,
      obscureText: widget.type == AppInputType.password && _obscureText,
      readOnly: widget.readOnly,
      enabled: !widget.disabled,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      maxLength: widget.maxLength,
      maxLines: effectiveMaxLines,
      minLines: effectiveMinLines,
      inputFormatters: effectiveInputFormatters,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      textAlign: widget.textAlign,
      enableSuggestions:
          widget.enableSuggestions ?? widget.type != AppInputType.password,
      validator: widget.validator,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [if (labelWidget != null) labelWidget, textField],
    );
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case AppInputType.email:
        return TextInputType.emailAddress;
      case AppInputType.number:
        return TextInputType.number;
      case AppInputType.phone:
        return TextInputType.phone;
      case AppInputType.multiline:
        return TextInputType.multiline;
      case AppInputType.search:
        return TextInputType.text;
      default:
        return TextInputType.text;
    }
  }
}

/// 검색 입력 필드 컴포넌트
///
/// 검색 기능에 특화된 입력 필드입니다.
class AppSearchField extends StatelessWidget {
  /// 입력 필드 컨트롤러
  final TextEditingController? controller;

  /// 입력 필드 힌트 텍스트
  final String hint;

  /// 검색 콜백
  final ValueChanged<String>? onSearch;

  /// 내용 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 취소 버튼 클릭 콜백
  final VoidCallback? onCancel;

  /// 취소 버튼 표시 여부
  final bool showCancelButton;

  /// 입력 필드 크기
  final AppInputSize size;

  /// 배경색
  final Color? backgroundColor;

  /// 테두리 반경
  final double borderRadius;

  /// 검색 입력 필드 생성자
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = '검색',
    this.onSearch,
    this.onChanged,
    this.onCancel,
    this.showCancelButton = true,
    this.size = AppInputSize.medium,
    this.backgroundColor,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
            hint: hint,
            type: AppInputType.search,
            size: size,
            onSubmitted: onSearch,
            onChanged: onChanged,
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
          ),
        ),
        if (showCancelButton)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('취소'),
            ),
          ),
      ],
    );
  }
}

/// OTP(One-Time Password) 입력 필드 컴포넌트
///
/// 인증 코드 입력에 특화된 입력 필드입니다.
class AppOtpField extends StatefulWidget {
  /// OTP 길이
  final int length;

  /// 완료 콜백
  final ValueChanged<String> onCompleted;

  /// 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 자동 포커스 여부
  final bool autofocus;

  /// 필드 너비
  final double fieldWidth;

  /// 필드 간격
  final double fieldSpacing;

  /// 필드 높이
  final double fieldHeight;

  /// 테두리 반경
  final double borderRadius;

  /// 활성화된 테두리 색상
  final Color? activeBorderColor;

  /// 비활성화된 테두리 색상
  final Color? inactiveBorderColor;

  /// 텍스트 스타일
  final TextStyle? textStyle;

  /// OTP 입력 필드 생성자
  const AppOtpField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.autofocus = false,
    this.fieldWidth = 50,
    this.fieldSpacing = 12,
    this.fieldHeight = 60,
    this.borderRadius = 8,
    this.activeBorderColor,
    this.inactiveBorderColor,
    this.textStyle,
  });

  @override
  _AppOtpFieldState createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late String _otp;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _otp = '';

    // 첫 번째 필드에 자동 포커스
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNodes.first);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged() {
    _otp = _controllers.map((controller) => controller.text).join();

    if (widget.onChanged != null) {
      widget.onChanged!(_otp);
    }

    if (_otp.length == widget.length) {
      widget.onCompleted(_otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length * 2 - 1, (index) {
        // 필드 사이의 간격
        if (index.isOdd) {
          return SizedBox(width: widget.fieldSpacing);
        }

        final fieldIndex = index ~/ 2;
        return _buildOtpField(fieldIndex);
      }),
    );
  }

  Widget _buildOtpField(int index) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox(
      width: widget.fieldWidth,
      height: widget.fieldHeight,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style:
            widget.textStyle ??
            TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor:
              isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.inactiveBorderColor ?? theme.dividerColor,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.activeBorderColor ?? theme.primaryColor,
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.inactiveBorderColor ?? theme.dividerColor,
              width: 1.0,
            ),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isEmpty) {
            // 이전 필드로 이동
            if (index > 0) {
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
          } else {
            // 다음 필드로 이동
            if (index < widget.length - 1) {
              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
            } else {
              _focusNodes[index].unfocus();
            }
          }

          _onOtpChanged();
        },
      ),
    );
  }
}
