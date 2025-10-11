// 화면 깜빡임을 줄이기 위해 빌드를 너무 자주하게 하면 안된다.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/hobby_screen.dart';
import 'package:roommate/features/authentication/userinfo/searcher_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/authentication/widgets/demand_button.dart';

class UserjobScreen extends StatefulWidget {
  const UserjobScreen({super.key});

  @override
  State<UserjobScreen> createState() => _UserjobScreenState();
}

class _UserjobScreenState extends State<UserjobScreen>
    with SingleTickerProviderStateMixin {
  final List<bool> _jobSelections = List<bool>.filled(4, false);

  int? _selectedIndex;
  Key _leftKey = UniqueKey();
  Key _rightKey = UniqueKey();
  final bool _isSending = false;

  late Future<User?> _userFuture; // ✅ 캐싱용 Future

  // === ⬇️ 추가: "다음" 버튼용 페이드 컨트롤러 ===
  static const _fadeDur = Duration(milliseconds: 300);
  late final AnimationController _btnAC;
  late final Animation<double> _btnFade;
  bool _btnBusy = false;
  // === ⬆️ 추가 ===

  @override
  void initState() {
    super.initState();
    _userFuture = Future.value(FirebaseAuth.instance.currentUser);

    // 버튼 최초 진입 페이드 인
    _btnAC = AnimationController(vsync: this, duration: _fadeDur);
    _btnFade = CurvedAnimation(parent: _btnAC, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _btnAC.forward();
    });
  }

  @override
  void dispose() {
    _btnAC.dispose();
    super.dispose();
  }

  void _onJobTap(int index) {
    setState(() => _jobSelections[index] = !_jobSelections[index]);
  }

  void _onTapLeft() {
    setState(() {
      if (_selectedIndex == 0) {
        _selectedIndex = null;
        _leftKey = UniqueKey();
      } else {
        _selectedIndex = 0;
        _rightKey = UniqueKey();
      }
    });
  }

  void _onTapRight() {
    setState(() {
      if (_selectedIndex == 1) {
        _selectedIndex = null;
        _rightKey = UniqueKey();
      } else {
        _selectedIndex = 1;
        _leftKey = UniqueKey();
      }
    });
  }

  bool _isNextEnabled() {
    final anyJob = _jobSelections.contains(true);
    final oneUserType = _selectedIndex != null;
    return anyJob && oneUserType;
  }

  // 기존 네비게이션 로직
  void _onNextTap() {
    if (_isSending) return;

    final textOptions = ['회사/학교', '재택', '프리랜서', '대학생'];
    final selectedJobsList = <String>[];

    for (int i = 0; i < _jobSelections.length; i++) {
      if (_jobSelections[i]) {
        selectedJobsList.add(textOptions[i]);
      }
    }

    final selectedJobs = selectedJobsList.join('');

    if (_selectedIndex == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HobbyScreen(
            // userType: 'roomOwner',
            // jobKinds: selectedJobs,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SearcherScreen(),
        ),
      );
    }
  }

  // === ⬇️ 추가: 페이드 아웃 후 네비게이션 래퍼 ===
  Future<void> _onNextTapWithFade() async {
    if (_btnBusy || !_isNextEnabled()) return;
    _btnBusy = true;
    try {
      await _btnAC.reverse(); // 버튼 사라짐 (300ms)
      if (!mounted) return;
      _onNextTap(); // 기존 네비게이션 실행
      // push 후 이 화면은 뒤로 남아있으니, 되돌아올 때는 initState에서 다시 페이드 인됨
    } finally {
      _btnBusy = false;
    }
  }
  // === ⬆️ 추가 ===

  @override
  Widget build(BuildContext context) {
    final textOptions = ['회사/학교', '재택', '프리랜서', '대학생'];
    final selectedJobs = <String>[];
    final bool isNextEnabled = _isNextEnabled();
    for (int i = 0; i < _jobSelections.length; i++) {
      if (_jobSelections[i]) {
        selectedJobs.add(textOptions[i]);
      }
    }

    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("데이터가 없습니다."));
        }
        final data = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('')),
          body: SafeArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '현재 하시고 계신 일에\n대해 알려주세요 !',
                        style: TextStyle(
                          fontSize: Sizes.size28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "나중에 더 찰떡궁합 룸메이트를 찾는데 사용되요.",
                        style: TextStyle(
                          fontSize: Sizes.size14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: Sizes.size16),
                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: Sizes.size16),

                      Center(
                        child: Wrap(
                          spacing: Sizes.size10,
                          runSpacing: Sizes.size10,
                          children: List.generate(4, (i) {
                            return CategoryButton(
                              text: textOptions[i],
                              myonTap: () => _onJobTap(i),
                              isSelected: _jobSelections[i],
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: Sizes.size80),

                      const Text(
                        '현재 RoomMate를 \n이용하는 이유는 무엇인가요 ?',
                        style: TextStyle(
                          fontSize: Sizes.size28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "나중에도 변경가능해요 !",
                        style: TextStyle(
                          fontSize: Sizes.size14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: Sizes.size16),
                      const Divider(height: 1, color: Colors.black12),
                      const SizedBox(height: Sizes.size16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DemandButton(
                            key: _leftKey,
                            text: "Room-owner",
                            myonTap: _onTapLeft,
                          ),
                          const SizedBox(width: Sizes.size56),
                          DemandButton(
                            key: _rightKey,
                            text: "Searcher",
                            myonTap: _onTapRight,
                          ),
                        ],
                      ),

                      const SizedBox(height: Sizes.size24),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offsetTween = Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          );
                          return SlideTransition(
                            position: offsetTween.animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _buildDescriptionCard(
                          context,
                          _selectedIndex,
                          data,
                        ),
                      ),

                      const SizedBox(height: Sizes.size28),

                      // ✅ "다음" 버튼 페이드 인/아웃
                      GestureDetector(
                        onTap: isNextEnabled ? _onNextTapWithFade : null,
                        child: FadeTransition(
                          opacity: _btnFade,
                          child: FormButton(
                            disabled: !_isNextEnabled(),
                            text: "다음",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _buildDescriptionCard(BuildContext context, int? index, User data) {
  if (index == null) {
    return const SizedBox(
      height: Sizes.size96 + Sizes.size56 + Sizes.size1,
    );
  }

  final bool isOwner = index == 0;
  final String title = isOwner ? "Room-owner" : "Co-searcher";

  final String ownerDesc =
      "${data.displayName ?? ''}님이 현재 방을 가지고 있고,\n"
      "월세를 같이 부담할 룸메이트를 찾고계시다면 \nRoom-owner입니다 !\n";
  final String searcherDesc =
      "${data.displayName ?? ''}님이 현재 방을 가지고 있지 않지만,\n"
      "월세를 같이 부담하며 누군가의 \n룸메이트가 되려한다면 Searcher입니다.\n";

  final String desc = isOwner ? ownerDesc : searcherDesc;

  return Container(
    key: ValueKey(title),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Sizes.size18),
      color: Colors.transparent,
      border: Border.all(color: Colors.black.withAlpha(15)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black.withAlpha(15)),
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(Sizes.size10),
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: TextStyle(
                  fontSize: Sizes.size12,
                  height: 1.6,
                  color: Colors.black.withAlpha(170),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
