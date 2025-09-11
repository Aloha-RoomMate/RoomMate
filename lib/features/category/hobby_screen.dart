import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/hobby_widget.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';

class HobbyScreen extends StatefulWidget {
  const HobbyScreen({super.key});

  @override
  State<HobbyScreen> createState() => HobbyScreenState();
}

class HobbyScreenState extends State<HobbyScreen> {
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

  Future<User?> _getUserName() async {
    return FirebaseAuth.instance.currentUser;
  }

  bool _isNextEnable() {
    return true;
  }

  Future<void> _onNextTap() async {
    if (!_isNextEnable()) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("데이터가 없습니다."));
        }
        final data = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text("")),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 상단 텍스트
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${data.displayName} 님의 관심사는 \n무엇인가요 ?",
                      style: const TextStyle(
                        fontSize: Sizes.size28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "룸메이트와 좋아하는 취미를 공유할 수도 있어요.",
                      style: TextStyle(
                        fontSize: Sizes.size14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: Sizes.size16),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: Sizes.size14),

              // ✅ 섹션들
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HobbyWidgetStateful(section: sportSection),
                        HobbyWidgetStateful(section: foodSection),
                        HobbyWidgetStateful(section: interestSection),
                        const SizedBox(height: Sizes.size10),
                        GestureDetector(
                          onTap: _onNextTap,
                          child: const FormButton(enabled: true, text: "다음"),
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
