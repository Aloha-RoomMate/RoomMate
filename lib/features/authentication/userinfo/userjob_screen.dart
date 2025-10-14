// 화면 깜빡임을 줄이기 위해 빌드를 너무 자주하게 하면 안된다.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/authentication/userinfo/hobby_screen.dart';
import 'package:roommate/features/authentication/userinfo/searcher_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/authentication/widgets/demand_button.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/class/user_repository.dart';

class UserjobScreen extends StatefulWidget {
  const UserjobScreen({super.key, this.returnAfterSave = false});
  final bool returnAfterSave; // ✅ 수정 모드면 true: 저장 후 pop(true)

  @override
  State<UserjobScreen> createState() => _UserjobScreenState();
}

class _UserjobScreenState extends State<UserjobScreen>
    with SingleTickerProviderStateMixin {
  // 직업 선택 (회사/학교, 재택, 프리랜서, 대학생)
  final List<bool> _jobSelections = List<bool>.filled(4, false);

  // 성별
  String? _selectedGender; // '남성' | '여성'
  bool _genderLocked = false; // ✅ 저장된 성별이 있으면 잠금(수정 불가)

  // 룸메이트 이용 이유 (0: owner, 1: searcher)
  int? _selectedIndex;
  Key _leftKey = UniqueKey();
  Key _rightKey = UniqueKey();

  // 저장/전환 제어
  bool _isSending = false;
  late Future<User?> _userFuture; // 캐싱용
  final _repo = UserRepository();

  // "다음" 버튼 페이드
  static const _fadeDur = Duration(milliseconds: 300);
  late final AnimationController _btnAC;
  late final Animation<double> _btnFade;
  bool _btnBusy = false;

  @override
  void initState() {
    super.initState();
    _userFuture = Future.value(FirebaseAuth.instance.currentUser);

    _btnAC = AnimationController(vsync: this, duration: _fadeDur);
    _btnFade = CurvedAnimation(parent: _btnAC, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _btnAC.forward();
    });

    _prefill(); // ✅ 기존 저장값 프리필(직업/성별/유형)
  }

  Future<void> _prefill() async {
    try {
      final me = await _repo.fetchMe();
      if (me == null) return;

      // 성별 프리필 + 잠금
      final rawGender = (me.gender ?? '').trim();
      if (rawGender.isNotEmpty) {
        _selectedGender = rawGender; // '남성' 또는 '여성'
        _genderLocked = true;
      }

      // 유저 타입 프리필
      final t = (me.userType?.type ?? 'searcher').toLowerCase();
      _selectedIndex = (t == 'roomowner' || t == 'room_owner') ? 0 : 1;

      // 직업 프리필
      final rawJobs = (me.userType?.jobKinds ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // index 0: 회사/학교 → 저장에는 '회사' 또는 '학교'가 들어있을 수 있음
      final hasCompany = rawJobs.any((j) => j.contains('회사'));
      final hasSchool = rawJobs.any((j) => j.contains('학교'));
      _jobSelections[0] = hasCompany || hasSchool;
      _jobSelections[1] = rawJobs.any((j) => j.contains('재택'));
      _jobSelections[2] = rawJobs.any((j) => j.contains('프리랜서'));
      _jobSelections[3] = rawJobs.any((j) => j.contains('대학생'));

      if (mounted) setState(() {});
    } catch (_) {
      // silent
    }
  }

  @override
  void dispose() {
    _btnAC.dispose();
    super.dispose();
  }

  // 직업 토글
  void _onJobTap(int index) {
    setState(() => _jobSelections[index] = !_jobSelections[index]);
  }

  // 유저 타입 토글
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

  // 성별 선택
  void _onGenderTap(String gender) {
    if (_genderLocked) return; // 잠금이면 무시
    setState(() => _selectedGender = gender);
  }

  // 버튼 활성 조건: 직업 ≥1, 성별(잠금이거나 직접 선택), 타입 선택, 그리고 저장 중이 아닐 때
  bool _isNextEnabled() {
    final anyJob = _jobSelections.contains(true);
    final genderOk = _genderLocked || (_selectedGender != null);
    final typeOk = _selectedIndex != null;
    return anyJob && genderOk && typeOk && !_isSending;
  }

  // 저장 + 네비
  Future<void> _saveAndNavigate() async {
    setState(() => _isSending = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) throw Exception('User not logged in');

      // 저장용 텍스트 정규화(회사/학교 → '회사'로 저장 통일)
      const storageText = ['회사', '재택', '프리랜서', '대학생'];
      final selectedJobsList = <String>[];
      for (int i = 0; i < _jobSelections.length; i++) {
        if (_jobSelections[i]) {
          selectedJobsList.add(storageText[i]);
        }
      }
      final jobKinds = selectedJobsList.join(', ');

      // 성별 저장: 잠금이 아닐 때만 업데이트
      if (!_genderLocked && _selectedGender != null) {
        await _repo.updateProfile(gender: _selectedGender);
      }

      final userType = _selectedIndex == 0 ? 'roomOwner' : 'searcher';
      await _repo.setUserTypeData(
        uid: authUser.uid,
        type: userType,
        jobKinds: jobKinds,
        address: '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 성공')),
      );

      if (widget.returnAfterSave) {
        Navigator.of(context).pop(true); // ✅ 수정 모드: 마이페이지로 복귀
      } else {
        if (_selectedIndex == 0) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HobbyScreen()),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearcherScreen()),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터 저장 중 에러 발생')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // 페이드 아웃 후 저장/이동
  Future<void> _onNextTapWithFade() async {
    if (_btnBusy || !_isNextEnabled()) return;
    _btnBusy = true;
    try {
      await _btnAC.reverse();
      if (!mounted) return;
      await _saveAndNavigate();
    } finally {
      _btnBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textOptions = ['회사/학교', '재택', '프리랜서', '대학생'];
    final bool isNextEnabled = _isNextEnabled();
    final genderHint = _genderLocked ? ' (설정됨 · 수정 불가)' : '';

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
          appBar: AppBar(
            title: const Text(''),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSizes.p(context, 20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== 1) 직업 =====
                      Text(
                        '현재 하시고 계신 일에\n대해 알려주세요 !',
                        style: TextStyle(
                          fontSize: ResponsiveSizes.f(context, 28),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Gaps.v6(context),
                      Text(
                        "나중에 더 찰떡궁합 룸메이트를 찾는데 사용되요.",
                        style: TextStyle(
                          fontSize: ResponsiveSizes.f(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Gaps.v16(context),
                      const Divider(height: 1, color: Colors.black12),
                      Gaps.v16(context),

                      Center(
                        child: Wrap(
                          spacing: ResponsiveSizes.p(context, 10),
                          runSpacing: ResponsiveSizes.p(context, 10),
                          children: List.generate(4, (i) {
                            return CategoryButton(
                              text: textOptions[i],
                              myonTap: () => _onJobTap(i),
                              isSelected: _jobSelections[i],
                            );
                          }),
                        ),
                      ),

                      Gaps.v80(context),

                      // ===== 2) 성별 =====
                      Text(
                        '성별을 선택해주세요 !$genderHint',
                        style: TextStyle(
                          fontSize: ResponsiveSizes.f(context, 28),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Gaps.v6(context),
                      Text(
                        "동성의 룸메이트만 찾으실수 있습니다.",
                        style: TextStyle(
                          fontSize: ResponsiveSizes.f(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Gaps.v16(context),
                      const Divider(height: 1, color: Colors.black12),
                      Gaps.v16(context),

                      Center(
                        child: Wrap(
                          spacing: ResponsiveSizes.p(context, 40),
                          runSpacing: ResponsiveSizes.p(context, 10),
                          children: [
                            Opacity(
                              opacity: _genderLocked ? 0.5 : 1.0,
                              child: CategoryButton(
                                text: '남성',
                                myonTap: _genderLocked
                                    ? () {}
                                    : () => _onGenderTap('남성'),
                                isSelected:
                                    _selectedGender == '남성', // ✅ 잠겨도 색상 유지
                              ),
                            ),
                            Opacity(
                              opacity: _genderLocked ? 0.5 : 1.0,
                              child: CategoryButton(
                                text: '여성',
                                myonTap: _genderLocked
                                    ? () {}
                                    : () => _onGenderTap('여성'),
                                isSelected:
                                    _selectedGender == '여성', // ✅ 잠겨도 색상 유지
                              ),
                            ),
                          ],
                        ),
                      ),

                      Gaps.v80(context),

                      // ===== 3) 이용 이유(소유/탐색) =====
                      Text(
                        '현재 RoomMate를 \n이용하는 이유는 무엇인가요 ?',
                        style: TextStyle(
                          fontSize: ResponsiveSizes.f(context, 28),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Gaps.v6(context),
                      Text(
                        "나중에도 변경가능해요 !",
                        style: TextStyle(
                          fontSize: ResponsiveSizes.f(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Gaps.v16(context),
                      const Divider(height: 1, color: Colors.black12),
                      Gaps.v16(context),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DemandButton(
                            key: _leftKey,
                            text: "Room-owner",
                            myonTap: _onTapLeft,
                            isSelected: _selectedIndex == 0, // ✅ 선택 표시
                          ),
                          Gaps.h56(context),
                          DemandButton(
                            key: _rightKey,
                            text: "Searcher",
                            myonTap: _onTapRight,
                            isSelected: _selectedIndex == 1, // ✅ 선택 표시
                          ),
                        ],
                      ),

                      Gaps.v24(context),

                      // 설명 카드 (기존 로직 유지)
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

                      Gaps.v28(context),

                      // ===== 4) 다음/저장 버튼 =====
                      GestureDetector(
                        onTap: isNextEnabled ? _onNextTapWithFade : null,
                        child: FadeTransition(
                          opacity: _btnFade,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FormButton(
                              enabled: isNextEnabled,
                              widget: Text(
                                widget.returnAfterSave ? "저장" : "다음",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
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
    return SizedBox(
      height: ResponsiveSizes.height(context, (96 + 56 + 1) / 800),
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
    padding: EdgeInsets.all(ResponsiveSizes.p(context, 16)),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, 18)),
      color: Colors.transparent,
      border: Border.all(color: Colors.black.withAlpha(15)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ResponsiveSizes.p(context, 44),
          height: ResponsiveSizes.p(context, 44),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black.withAlpha(15)),
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, 10)),
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white),
        ),
        Gaps.h12(context),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveSizes.f(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6(context),
              Text(
                desc,
                style: TextStyle(
                  fontSize: ResponsiveSizes.f(context, 12),
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
