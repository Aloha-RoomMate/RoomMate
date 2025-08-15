import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/roomowner_screen.dart';
import 'package:roommate/features/authentication/userinfo/searcher_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/authentication/widgets/demand_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

class UserjobScreen extends StatefulWidget {
  const UserjobScreen({super.key});

  @override
  State<UserjobScreen> createState() => _UserjobScreenState();
}

class _UserjobScreenState extends State<UserjobScreen> {
  // 4개 카테고리 선택 상태(다중 선택 허용)
  final List<bool> _jobSelections = List<bool>.filled(4, false);

  // 2개 유저 타입 선택 상태(단일 선택)
  int? _selectedIndex; // 0: Room-owner, 1: Searcher
  Key _leftKey = UniqueKey();
  Key _rightKey = UniqueKey();

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

  void _onNextTap() {
    if (!_isNextEnabled()) return;
    if (_selectedIndex == 0) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RoomownerScreen()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SearcherScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textOptions = ['회사/학교', '재택', '프리랜서', '대학생'];
    final bool isNextEnabled = _isNextEnabled();

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4개 카테고리 영역
                    const Text(
                      '출퇴근 형태를 알려주세요',
                      style: TextStyle(
                        fontSize: Sizes.size16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gaps.v6,
                    Wrap(
                      spacing: Sizes.size10,
                      runSpacing: Sizes.size10,
                      children: List.generate(4, (i) {
                        return CategoryButton(
                          text: textOptions[i],
                          myonTap: () => _onJobTap(i),
                          // 선택 시각화가 필요하면 CategoryButton에 selected 전달하도록 위젯 수정 권장
                          // selected: _jobSelections[i],
                        );
                      }),
                    ),

                    const SizedBox(height: Sizes.size32),

                    // 2개 유저 타입 영역
                    const Text(
                      '유저 타입을 선택해주세요',
                      style: TextStyle(
                        fontSize: Sizes.size16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Sizes.size20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DemandButton(
                          key: _leftKey,
                          text: "Room-owner",
                          myonTap: _onTapLeft,
                          // selected: _selectedIndex == 0,  // 위젯이 지원하면 사용
                        ),
                        const SizedBox(width: Sizes.size56),
                        DemandButton(
                          key: _rightKey,
                          text: "Searcher",
                          myonTap: _onTapRight,
                          // selected: _selectedIndex == 1,
                        ),
                      ],
                    ),

                    const SizedBox(height: Sizes.size24),

                    // 설명 카드 + 애니메이션 (원래 UserdemandScreen 로직 복원)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final offsetTween = Tween<Offset>(
                          begin: const Offset(0, 1),
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
                      child: _buildDescriptionCard(context, _selectedIndex),
                    ),

                    const SizedBox(height: Sizes.size28),

                    // 다음 버튼
                    GestureDetector(
                      onTap: isNextEnabled ? _onNextTap : null,
                      child: _supportsEnabledProp()
                          ? FormButton(enabled: isNextEnabled, text: "다음")
                          : FormButton(enabled: !isNextEnabled, text: "다음"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 원래 설명 카드 빌더
  Widget _buildDescriptionCard(BuildContext context, int? index) {
    if (index == null) {
      return const SizedBox.shrink(key: ValueKey('empty'));
    }

    final bool isOwner = index == 0;
    final String title = isOwner ? "Room-owner" : "Co-searcher";

    const String ownerDesc =
        "Room-owner 는 현재 방을 가지고 있고,\n월세를 같이 부담할 룸메이트를 찾는 사람입니다.\n";
    const String searcherDesc =
        "Searcher 는 현재 방을 가지고 있지 않지만,\n월세를 같이 부담하며 누군가의 룸메이트가 되려는 사람입니다.";

    final String desc = isOwner ? ownerDesc : searcherDesc;
    final IconData icon = isOwner ? Icons.home_rounded : Icons.search_rounded;

    return Container(
      key: ValueKey(title),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface.withAlpha(120),
        border: Border.all(color: Colors.black.withAlpha(15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
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

  // 프로젝트마다 FormButton 시그니처가 달라 충돌 방지용 헬퍼
  bool _supportsEnabledProp() {
    // enabled/disabled 중 어떤 생성자를 쓰는지 컴파일 타임에 결정되므로
    // 실제론 둘 중 하나만 남기면 됩니다.
    // 팀 컨벤션에 맞춰 하나로 통일해 주세요.
    return true;
  }
}
