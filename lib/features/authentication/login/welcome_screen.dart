import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/userjob_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _fadeDur = Duration(milliseconds: 300);

  late final AnimationController _ac;
  late final Animation<double> _fade;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: _fadeDur);
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);

    // 첫 진입 시 자연스러운 페이드 인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _createUserDocIfNeeded(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 실패 시 화면을 다시 페이드 인 시키고 안내
      if (mounted) {
        await _ac.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다. 다시 시도해주세요.')),
        );
      }
      return;
    }

    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await docRef.set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  PageRouteBuilder _buildFadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: _fadeDur,
      reverseTransitionDuration: _fadeDur,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  Future<void> _onNextTap(BuildContext context) async {
    if (_busy) return;
    setState(() => _busy = true);

    // 1) 현재 화면 페이드 아웃
    await _ac.reverse();

    try {
      // 2) 프로필 생성
      await _createUserDocIfNeeded(context);
      if (!mounted) return;

      // 3) 다음 화면으로 페이드 인 네비게이션
      await Navigator.of(
        context,
      ).pushReplacement(_buildFadeRoute(const UserjobScreen()));
    } catch (e) {
      // 실패: 다시 페이드 인 후 에러 안내
      if (mounted) {
        await _ac.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        // ✅ 화면 전체 페이드 인/아웃
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.all(Sizes.size32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '환영합니다. $name님',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: Sizes.size32,
                  ),
                ),
                Gaps.v60,
                // 기존 제스처 유지, 로딩 중엔 탭 차단 + 버튼 비활성화
                GestureDetector(
                  onTap: _busy ? null : () => _onNextTap(context),
                  child: FormButton(
                    // 프로젝트에 쓰는 시그니처에 맞춰 값 전달
                    // (당신의 FormButton이 disabled/ text를 받는 형태)
                    disabled: _busy,
                    text: "시작하기",
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
