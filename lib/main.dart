import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';
import 'firebase_options.dart'; // flutterfire configure가 만든 파일
import 'package:flutter_naver_map/flutter_naver_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase 먼저
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2) 그 다음에 네이버맵 등 다른 SDK 초기화
  await FlutterNaverMap().init(
    clientId: '7j2w13vo27',
    onAuthFailed: (e) => debugPrint('NaverMap auth fail: $e'),
  );

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
      home: MainNavigation(),
    );
  }
}
