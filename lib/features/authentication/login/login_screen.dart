import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/widgets/auth_button.dart';
import 'package:roommate/features/authentication/login/login_email_screen.dart';
import 'package:roommate/features/authentication/login/login_google_screen.dart';
import 'package:roommate/features/authentication/login/login_kakaotalk_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _onSignupTap(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onloginEmailTap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoginEmailScreen()));
  }

  void _onGoogleTap(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LoginGoogleScreen()));
  }

  void _onKakaoTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginKakaotalkScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.size40),
          child: Column(
            children: [
              Gaps.v80,
              Text(
                '로그인',
                style: TextStyle(
                  fontSize: Sizes.size28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v20,
              Text(
                '나의 룸메이트를 찾아보기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
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
                onTap: () => _onloginEmailTap(context),
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
        elevation: 1,
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Sizes.size10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Dont have account?  "),
              GestureDetector(
                onTap: () => _onSignupTap(context),
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
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
