import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; // 이거 필요
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/sign_up_screen.dart';
import 'package:roommate/features/homepage/widgets/homepage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterNaverMap().init(
    clientId: '7j2w13vo27',
    onAuthFailed: (e) => debugPrint('NaverMap auth fail: $e'),
  );

  runApp(const RoomMate());
}

class RoomMate extends StatelessWidget {
  const RoomMate({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomMate',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color.fromARGB(255, 103, 104, 171),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: Sizes.size18, // size16 + size2
            color: Colors.black,
          ),
        ),
      ),
      home: const SignUpScreen(),
    );
  }
}
