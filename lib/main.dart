import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/signup/email_screen.dart';
import 'package:roommate/features/authentication/userinfo/sign_up_screen.dart';
import 'package:roommate/features/homepage/widgets/homepage_screen.dart';

void main() {
  runApp(const RoomMate());
}

class RoomMate extends StatelessWidget {
  const RoomMate({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomMate',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Color.fromARGB(255, 103, 104, 171),
        appBarTheme: AppBarTheme(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: Sizes.size16 + Sizes.size2,
            color: Colors.black,
          ),
        ),
      ),
      home: SignUpScreen(),
    );
  }
}
