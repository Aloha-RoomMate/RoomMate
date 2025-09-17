import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _onNextTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DailyRhythmScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.all(Sizes.size32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '환영합니다',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: Sizes.size32,
                ),
              ),
              Gaps.v60,
              GestureDetector(
                onTap: () => _onNextTap(context),
                child: FormButton(disabled: false, text: "시작하기"),
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
