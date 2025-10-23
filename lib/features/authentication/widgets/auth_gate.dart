import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart'; // 메인 화면 위젯 import

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          return FutureBuilder<AppUser?>(
            future: UserRepository().fetchMe(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final appUser = userSnapshot.data;
              // 필수 목록 다 했나 확인
              final isRegistered =
                  appUser?.userType?.jobKinds.isNotEmpty == true &&
                  appUser?.birthYear != null &&
                  appUser?.gender != null &&
                  appUser?.userType?.type != null;

              if (isRegistered) {
                return const MainNavigation();
              } else {
                return const LoginScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
