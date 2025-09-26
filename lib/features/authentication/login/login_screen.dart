import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/login/welcome_screen.dart';
import 'package:roommate/features/authentication/widgets/auth_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const _webClientId =
      '909707662887-ld8djjd1eqbdu7hcellh7689j3q1n9ik.apps.googleusercontent.com';

  void _onSignupTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final google = GoogleSignIn(
        scopes: const ['email'],
        serverClientId: _webClientId,
      );
      final account = await google.signIn();
      if (account == null) return;

      final gauth = await account.authentication;
      final idToken = gauth.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'No Google ID Token',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인 실패: ${e.code}')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인 오류: $e')));
    }
  }

  // ✅ 에뮬레이터 테스트 계정 로그인
  Future<void> _signInWithTestAccount(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('테스트 로그인 실패: ${e.code}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.size40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Gaps.v10,
              Text(
                'RoomMate',
                style: TextStyle(
                  letterSpacing: 3,
                  fontSize: Sizes.size32,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: <Color>[
                        Colors.yellow,
                        Theme.of(context).primaryColor,
                        Colors.green,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(Rect.fromLTWH(0.0, 10.0, 1000, 00)),
                ),
              ),
              Gaps.v20,
              const Text(
                '나와 맞는 룸메이트 찾기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.v1,
              Gaps.v96,
              Gaps.v96,
              InkWell(
                onTap: () => _signInWithGoogle(context),
                borderRadius: BorderRadius.circular(12),
                child: AuthButton(
                  icon: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                  text: '구글로 계속하기',
                ),
              ),

              // ✅ 아주 작은 테스트 계정 로그인 버튼 두 개
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _signInWithTestAccount(
                      context,
                      "test1@test.com",
                      "123456",
                    ),
                    child: const Text(
                      "테스트1",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _signInWithTestAccount(
                      context,
                      "test2@test.com",
                      "123456",
                    ),
                    child: const Text(
                      "테스트2",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
