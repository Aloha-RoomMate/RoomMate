import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/category/dining_habit_screen.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/etc_screen.dart';
import 'package:roommate/features/category/introduction_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
