import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/login/login_email_screen.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // ✅ 에뮬레이터로 요청이 날아갑니다(메인에서 useAuthEmulator 설정했기 때문)
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );

      // 가입 성공 → 홈(or 다음 화면)으로 이동
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // 에러 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '회원가입 실패')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.size40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Gaps.v80,
                Text(
                  'RoomMate',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: Sizes.size32,
                    color: theme.primaryColor,
                  ),
                ),
                Gaps.v24,
                const Text(
                  '나의 룸메이트를 찾아보기',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: Sizes.size16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                Gaps.v12,
                const Text(
                  '회원가입',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: Sizes.size20,
                    color: Colors.black,
                  ),
                ),
                Gaps.v24,

                // ✅ 이메일
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: '이메일'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요';
                    if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다';
                    return null;
                  },
                ),
                Gaps.v16,

                // ✅ 비밀번호
                TextFormField(
                  controller: _pwCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '비밀번호(6자 이상)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                    if (v.length < 6) return '6자 이상 입력해주세요';
                    return null;
                  },
                ),
                Gaps.v24,

                // 가입 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    child: Text(_loading ? '가입 중...' : '회원가입'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Sizes.size14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('이미 계정이 있다면 ?'),
              Gaps.h4,
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoginEmailScreen(),
                    ),
                  );
                },
                child: Text(
                  'Log In',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
