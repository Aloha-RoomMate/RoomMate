import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart'; // 메인 화면 위젯 import

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth의 인증 상태 변경을 실시간으로 감지하는 StreamBuilder
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 아직 상태를 확인 중이면 로딩 인디케이터를 보여줍니다.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // snapshot.hasData는 로그인된 사용자가 있다는 뜻입니다.
        if (snapshot.hasData) {
          // 로그인 상태이면 MainNavigation 화면을 보여줍니다.
          return const MainNavigation();
        } else {
          // 로그아웃 상태이면 LoginScreen을 보여줍니다.
          return const LoginScreen();
        }
      },
    );
  }
}
