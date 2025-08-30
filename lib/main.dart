import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/login/login_screen.dart';

const _AUTH_PORT = 9099;
const _FS_PORT = 8080;

const _EMU_HOST_FROM_ENV = String.fromEnvironment('EMU_HOST', defaultValue: '');

// (중요) $ flutter run -d RFCN100T0SX --dart-define=EMU_HOST=172.30.1.99 << 이런 형식으로 기기이름이랑, 현재 IPv4 를 적으면 연결 가능하다
// 10.0.2.2 << 이건 안드로이드 에뮬레이터 전용이다. 이걸 먼저 탐색하기 때문에 이 IP를 모르는 공기계는 어리둥절 하게 된다. 때문에 위와같은 방법으로 강제하면 된다.

Future<String> _pickEmuHost() async {
  if (_EMU_HOST_FROM_ENV.isNotEmpty) {
    return _EMU_HOST_FROM_ENV;
  }

  if (Platform.isAndroid) return '10.0.2.2';
  if (Platform.isIOS) return 'localhost';
  return '127.0.0.1';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (kDebugMode) {
    final host = await _pickEmuHost();
    await FirebaseAuth.instance.useAuthEmulator(host, _AUTH_PORT);
    FirebaseFirestore.instance.useFirestoreEmulator(host, _FS_PORT);
    debugPrint('🔌 Emulators -> $host:$_AUTH_PORT / $host:$_FS_PORT');
  }

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
      home: const LoginScreen(),
    );
  }
}
