import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';

class CompleteScreen extends StatefulWidget {
  const CompleteScreen({super.key});

  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen> {
  void _onNextTap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Text(
              "${FirebaseAuth.instance.currentUser?.displayName}님의 정보가 입력되었어요.",
            ),
            Text("이제 더 많은 정보에 접근 가능해요."),
            GestureDetector(
              onTap: () => _onNextTap(),
              child: const FormButton(enabled: true, widget: Text("시작하기")),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
