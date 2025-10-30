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
  /// ✅ 실제 바텀네비 탭 순서에 맞게 인덱스를 설정하세요.
  /// 예) 0=홈, 1=지도, 2=글쓰기, 3=마이페이지(일반적으로 마지막) → 3
  static const int kMyPageTabIndex = 0;

  void _onNextTap() {
    // ✅ 스택 전체 제거 후 메인으로 진입, 마이페이지 탭 선택
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainNavigation(initialIndex: kMyPageTabIndex),
      ),
      (route) => false,
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
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 아이콘
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
