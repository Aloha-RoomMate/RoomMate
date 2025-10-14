// lib/features/authentication/complete_screen.dart
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
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : "회원";

    final t = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // 본문: 가운데 정렬
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 완성 아이콘
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 48,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 제목
                        Text(
                          "$displayName님의 정보 입력이 완료되었어요.",
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // 보조 문구
                        Text(
                          "이제 더 많은 정보에 접근할 수 있어요.",
                          style: t.bodyMedium?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // 버튼: 기존 FormButton “형태 그대로” 사용
                  GestureDetector(
                    onTap: _onNextTap,
                    child: const FormButton(
                      enabled: true,
                      widget: Text("시작하기"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
