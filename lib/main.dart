import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';
import 'package:roommate/features/post/room_owner_post.dart';
import 'package:roommate/features/post/searcher_post.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';
import 'package:roommate/features/view/user_profile_view.dart';

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

      home: DailyRythmScreen(),
    );
  }
}
