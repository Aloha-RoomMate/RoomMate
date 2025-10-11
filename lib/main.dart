import 'package:roommate/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:roommate/features/authentication/widgets/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  await Supabase.initialize(
    url: 'https://ilukkxdegjhncnvduphh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsdWtreGRlZ2pobmNudmR1cGhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3Mjg1MDEsImV4cCI6MjA3NTMwNDUwMX0.6I7eiO-o3LBvQa9DxJYp1ONpqqfnuqUxMZad_IFmHug',
  );

  runApp(const RoomMate());
}

class RoomMate extends StatelessWidget {
  const RoomMate({super.key});

  @override
  Widget build(BuildContext context) {
    const seedGreen = Color(0xFF16A34A); // 원하는 초록

    final scheme = ColorScheme.fromSeed(
      seedColor: seedGreen,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'RoomMate',
      theme: ThemeData(
        colorScheme: scheme,
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
        inputDecorationTheme: InputDecorationTheme(
          border: const UnderlineInputBorder(),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          floatingLabelStyle: TextStyle(color: scheme.primary),
        ),

        // 진행바 색
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: scheme.primary,
        ),
        // BottomNavigationBar 색
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: scheme.surface,
          selectedItemColor: scheme.primary,
          unselectedItemColor: scheme.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
