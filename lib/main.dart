import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// 루트에서 firebase emulators:start
/// 에뮬레이터 콜드 부트
/// 디버깅
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  if (kDebugMode) {
    try {
      final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    } catch (e) {
      debugPrint('에뮬레이터 연결 실패. $e');
    }
  }

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
        primaryColor: Colors.green.shade600,
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
      home: DailyRythmScreen(),
    );
  }
}
