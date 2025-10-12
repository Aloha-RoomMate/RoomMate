import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/authentication/widgets/hobby_widget.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class HobbyScreen extends StatefulWidget {
  const HobbyScreen({super.key});

  @override
  State<HobbyScreen> createState() => HobbyScreenState();
}

class HobbyScreenState extends State<HobbyScreen> {
  bool _isSending = false;

  List<String> foodList = <String>[];
  List<String> sportsList = <String>[];
  List<String> interestList = <String>[];
  final UserRepository _userRepository = UserRepository();

  late final Future<User?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _getUser();
  }

  Future<User?> _getUser() async => FirebaseAuth.instance.currentUser;

  final foodSection = HobbyWidget(
    icon: Icons.food_bank_rounded,
    title: '최애 음식',
    items: [
      "피자",
      "치킨",
      "삼겹살",
      "라면",
      "불고기",
      "김치찌개",
      "된장찌개",
      "비빔밥",
      "칼국수",
      "떡볶이",
      "순대국",
      "갈비탕",
      "돈까스",
      "초밥",
      "회",
      "족발",
      "보쌈",
      "쌀국수",
      "버거",
      "파스타",
    ],
    previewCount: 9,
  );

  final sportSection = HobbyWidget(
    icon: Icons.sports_gymnastics_rounded,
    title: '운동과 엑티비티',
    items: [
      "농구",
      "러닝",
      "무술",
      "배드민턴",
      "사이클링",
      "산책",
      "클라이밍",
      "테니스",
      "필라테스",
      "스키",
      "스케이트",
      "테니스",
      "탁구",
      "당구",
      "헬스장",
      "해변 스포츠",
      "폴 댄스",
      "축구",
      "E-스포츠",
    ],
    previewCount: 10,
  );

  final interestSection = HobbyWidget(
    icon: Icons.lightbulb_rounded,
    title: '요즘 관심사',
    items: [
      "아이돌",
      "키링",
      "전시회",
      "애니메이션",
      "IT",
      "부동산",
      "주식",
      "독서",
      "영화감상",
      "음악듣기",
      "공연",
      "넷플릭스",
      "맛집",
      "기후변화",
      "방탈출",
      "클러빙",
      "다꾸",
    ],
    previewCount: 10,
  );

  bool _isNextEnable() =>
      sportsList.isNotEmpty && foodList.isNotEmpty && interestList.isNotEmpty;

  Future<void> _onNextTap() async {
    if (!_isNextEnable()) return;

    try {
      setState(() => _isSending = true);

      final hobby = Hobby(
        foodLike: foodList.toList(),
        interestLike: interestList.toList(), // ✅ key 일치
        sportLike: sportsList.toList(),
      );

      await _userRepository.setHobby(hobby);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } catch (e, st) {
      print("error: $e");
      print("stack: $st");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("데이터가 없습니다.")),
          );
        }
        final data = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text(""),
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: ResponsiveSizes.p(context, 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${data.displayName ?? ''} 님의 관심사는 \n무엇인가요 ?",
                      style: TextStyle(
                        fontSize: ResponsiveSizes.f(context, 28),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gaps.v8(context),
                    Text(
                      "룸메이트와 좋아하는 취미를 공유할 수도 있어요.",
                      style: TextStyle(
                        fontSize: ResponsiveSizes.f(context, 14),
                        color: Colors.black87,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Gaps.v8(context),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12),
              Gaps.v14(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveSizes.p(context, 10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HobbyWidgetStateful(
                          section: sportSection,
                          onSelectionChanged: (selected) {
                            setState(() => sportsList = selected);
                          },
                        ),
                        HobbyWidgetStateful(
                          section: foodSection,
                          onSelectionChanged: (selected) {
                            setState(() => foodList = selected);
                          },
                        ),
                        HobbyWidgetStateful(
                          section: interestSection,
                          onSelectionChanged: (selected) {
                            setState(() => interestList = selected);
                          },
                        ),
                        Gaps.v10(context),
                        GestureDetector(
                          onTap: _isNextEnable() && !_isSending
                              ? _onNextTap
                              : null,
                          child: FormButton(
                            enabled: _isNextEnable(),
                            widget: _isSending
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    '다음',
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
