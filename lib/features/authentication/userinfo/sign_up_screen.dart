import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/userid_screen.dart';
import 'package:roommate/features/authentication/widgets/auth_button.dart';
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/authentication/signup/google_screen.dart';
import 'package:roommate/features/authentication/signup/kakaotalk_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  void _onLoginTap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  void _onEmailTap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => UseridScreen()));
  }

  void _onGoogleTap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const GoogleScreen()));
  }

  void _onKakaoTap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const KakaotalkScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.size40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Gaps.v80,
              Text(
                '회원가입',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Sizes.size28,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.v24,
              Text(
                '나의 룸메이트를 찾아보기',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: Sizes.size16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.v1,
              Text(
                'RoomMate',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Sizes.size20,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.v48,
              GestureDetector(
                onTap: () => _onEmailTap(context),
                child: AuthButton(
                  icon: const FaIcon(FontAwesomeIcons.solidUser),
                  text: 'Use email or password',
                ),
              ),
              Gaps.v16,
              GestureDetector(
                onTap: () => _onGoogleTap(context),
                child: const AuthButton(
                  icon: FaIcon(FontAwesomeIcons.google),
                  text: 'Continue with Google',
                ),
              ),
              Gaps.v16,
              GestureDetector(
                onTap: () => _onKakaoTap(context),
                child: const AuthButton(
                  icon: FaIcon(FontAwesomeIcons.comment),
                  text: 'Continue with KakaoTalk',
                ),
              ),
            ],
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
                onTap: () => _onLoginTap(context),
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
