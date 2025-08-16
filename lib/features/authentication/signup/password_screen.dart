import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/userjob_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late final AnimationController _shakeController;
  late final Animation<double> _offsetAnimation;

  String _password = "";
  String _confirmPassword = "";
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(_updatePasswords);
    _confirmPasswordController.addListener(_updatePasswords);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _offsetAnimation = Tween(
      begin: -10.0,
      end: 10.0,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_shakeController);
  }

  void _updatePasswords() {
    setState(() {
      _password = _passwordController.text;
      _confirmPassword = _confirmPasswordController.text;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onScaffoldTap() {
    FocusScope.of(context).unfocus();
  }

  // 형식 조건
  bool get _hasMinLength => _password.length >= 8;
  bool get _hasUppercase => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get _confirmPasswordHasMinLength => _confirmPassword.length >= 8;
  bool get _confirmPasswordHasUppercase =>
      _confirmPassword.contains(RegExp(r'[A-Z]'));
  bool get _confirmPasswordHasNumber =>
      _confirmPassword.contains(RegExp(r'[0-9]'));
  bool get _confirmPasswordHasSpecialChar =>
      _confirmPassword.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  // 버튼 활성화 조건 (양쪽 다 형식 만족)
  bool get _hasValidFormatBoth =>
      _hasMinLength &&
      _hasUppercase &&
      _hasNumber &&
      _hasSpecialChar &&
      _confirmPasswordHasMinLength &&
      _confirmPasswordHasUppercase &&
      _confirmPasswordHasNumber &&
      _confirmPasswordHasSpecialChar;

  // 비밀번호 일치 여부
  bool get _passwordsMatch =>
      _password.isNotEmpty &&
      _confirmPassword.isNotEmpty &&
      _password == _confirmPassword;
  void _onNextTap() async {
    if (!_passwordsMatch) {
      await _shakeController.forward();
      await _shakeController.reverse();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다')));
    } else {
      FocusScope.of(context).unfocus();

      await Future.delayed(const Duration(milliseconds: 200));

      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const UserjobScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(
            milliseconds: 300,
          ), // 팝 시 동일
        ),
      );
    }
  }

  void _onClearTap() {
    _passwordController.clear();
  }

  void _clearConfirm() => _confirmPasswordController.clear();

  void _toogleObscureText() {
    _obscureText = !_obscureText;
    setState(() {});
  }

  void _toogleObscureConfirmText() {
    _obscureConfirmText = !_obscureConfirmText;
    setState(() {});
  }

  Widget _buildRequirement(String label, bool fulfilled) {
    return Row(
      children: [
        Icon(
          fulfilled ? Icons.check_circle : Icons.cancel,
          color: fulfilled ? Colors.green : Colors.red,
          size: 20,
        ),
        Gaps.h8,
        Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('회원가입')),
        body: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_offsetAnimation.value, 0),
              child: child,
            );
          },
          child: SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: Sizes.size24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Gaps.v40,
                    const Text(
                      '비밀번호 생성하기',
                      style: TextStyle(
                        fontSize: Sizes.size24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Gaps.v20,
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      cursorColor: Theme.of(context).primaryColor,
                      decoration: InputDecoration(
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _onClearTap,
                              child: FaIcon(
                                FontAwesomeIcons.solidCircleXmark,
                                color: Colors.grey.shade400,
                                size: Sizes.size20,
                              ),
                            ),
                            Gaps.h14,
                            GestureDetector(
                              onTap: _toogleObscureText,
                              child: FaIcon(
                                _obscureText
                                    ? FontAwesomeIcons.eye
                                    : FontAwesomeIcons.eyeSlash,
                                color: Colors.grey.shade400,
                                size: Sizes.size20,
                              ),
                            ),
                          ],
                        ),
                        hintText: "비밀번호",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Gaps.v20,
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmText,
                      cursorColor: Theme.of(context).primaryColor,
                      decoration: InputDecoration(
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _clearConfirm,
                              child: FaIcon(
                                FontAwesomeIcons.solidCircleXmark,
                                color: Colors.grey.shade400,
                                size: Sizes.size20,
                              ),
                            ),
                            Gaps.h14,
                            GestureDetector(
                              onTap: _toogleObscureConfirmText,
                              child: FaIcon(
                                _obscureConfirmText
                                    ? FontAwesomeIcons.eye
                                    : FontAwesomeIcons.eyeSlash,
                                color: Colors.grey.shade400,
                                size: Sizes.size20,
                              ),
                            ),
                          ],
                        ),
                        hintText: "비밀번호 확인",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                (!_passwordsMatch &&
                                    _confirmPassword.isNotEmpty)
                                ? Theme.of(context).primaryColor
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Gaps.v24,
                    _buildRequirement('8자 이상', _hasMinLength),
                    _buildRequirement('대문자 포함 (A-Z)', _hasUppercase),
                    _buildRequirement('숫자 포함 (0-9)', _hasNumber),
                    _buildRequirement('특수문자 포함 (!@#...)', _hasSpecialChar),
                    _buildRequirement('비밀번호가 일치합니다', _passwordsMatch),
                    Gaps.v32,
                    GestureDetector(
                      onTap: _onNextTap,
                      child: FormButton(
                        disabled: !_hasValidFormatBoth,
                        text: "다음",
                      ),
                    ),
                    Gaps.v20,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
