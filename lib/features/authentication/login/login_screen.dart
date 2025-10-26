import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/authentication/login/welcome_screen.dart';
import 'package:roommate/features/authentication/widgets/auth_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        // 웹: 토큰 직접 다루지 말고 팝업으로
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // 모바일
        final googleUser = await GoogleSignIn(
          scopes: ['email', 'profile'],
        ).signIn();
        if (googleUser == null) return;

        final gauth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: gauth.idToken,
          accessToken: gauth.accessToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!context.mounted) return;

      final userRepo = UserRepository();
      final appUser = await userRepo.fetchMe();

      final isRegistered =
          appUser?.userType?.jobKinds.isNotEmpty == true &&
          appUser?.birthYear != null &&
          appUser?.gender != null &&
          appUser?.userType != null;

      if (context.mounted) {
        if (isRegistered) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            ),
            (route) => false,
          );
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSizes.p(context, 40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Gaps.v10(context),
              Text(
                'RoomMate',
                style: TextStyle(
                  letterSpacing: 3,
                  fontSize: ResponsiveSizes.f(context, 32),
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
              Gaps.v20(context),
              Text(
                '최고의 룸메이틀 찾아보세요',
                style: TextStyle(
                  fontSize: ResponsiveSizes.f(context, 24),
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.v1(context),
              Gaps.v96(context),
              Gaps.v96(context),
              InkWell(
                onTap: () => _signInWithGoogle(context),
                borderRadius: BorderRadius.circular(12),
                child: AuthButton(
                  icon: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                  text: '구글로 계속하기',
                ),
              ),

              // ✅ 아주 작은 테스트 계정 로그인 버튼 두 개
            ],
          ),
        ),
      ),
    );
  }
}
