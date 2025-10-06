import 'package:roommate/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:roommate/features/authentication/widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FlutterNaverMap().init(
    clientId: '7j2w13vo27',
    onAuthFailed: (ex) {
      debugPrint(
        '[NMAP AUTH FAIL] type=${ex.runtimeType} code=${ex.code} msg=${ex.message}',
      );
    },
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
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: Sizes.size18,
            color: Colors.black,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
