import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class WorkPatternScreen extends StatefulWidget {
  const WorkPatternScreen({super.key});

  @override
  State<WorkPatternScreen> createState() => _WorkPatternScreenState();
}

class _WorkPatternScreenState extends State<WorkPatternScreen> {
  List<bool> answeredQuestion = List.filled(4, false);

  void _onChipTap(int index) {
    answeredQuestion[index] = !answeredQuestion[index];
    setState(() {});
  }

  bool _checkNextButtonAvailable() {
    for (int i = 0; i < answeredQuestion.length; i++) {
      if (answeredQuestion[i] == false) {
        return false;
      }
    }
    return true;
  }

  void _onNextTap() {
    if (_checkNextButtonAvailable()) {
      Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder: (context) => WorkPatternScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '출퇴근 패턴을 선택해주세요!',
          style: TextStyle(
            fontSize: Sizes.size20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: Sizes.size24,
          right: Sizes.size24,
          bottom: Sizes.size24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '출퇴근 형태를 알려주세요!!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: [
                  CategoryButton(
                    text: '회사',
                    myonTap: () => _onChipTap(0),
                  ),
                  CategoryButton(
                    text: '재택',
                    myonTap: () => _onChipTap(0),
                  ),
                  CategoryButton(
                    text: '프리랜서',
                    myonTap: () => _onChipTap(0),
                  ),
                ],
              ),
              Gaps.v12,
              Text(
                '출근 시간대를 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: [
                  CategoryButton(
                    text: '5-6시',
                    myonTap: () => _onChipTap(1),
                  ),
                  CategoryButton(
                    text: '6-7시',
                    myonTap: () => _onChipTap(1),
                  ),
                  CategoryButton(
                    text: '7-8시',
                    myonTap: () => _onChipTap(1),
                  ),
                  CategoryButton(
                    text: '8-9시',
                    myonTap: () => _onChipTap(1),
                  ),
                  CategoryButton(
                    text: '9시 이후',
                    myonTap: () => _onChipTap(1),
                  ),
                ],
              ),
              Gaps.v12,
              Text(
                '귀가 시간대를 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: [
                  CategoryButton(
                    text: '18-19시',
                    myonTap: () => _onChipTap(2),
                  ),
                  CategoryButton(
                    text: '19-20시',
                    myonTap: () => _onChipTap(2),
                  ),
                  CategoryButton(
                    text: '20-21시',
                    myonTap: () => _onChipTap(2),
                  ),
                  CategoryButton(
                    text: '21-22시 이후',
                    myonTap: () => _onChipTap(2),
                  ),
                  CategoryButton(
                    text: '22시 이후',
                    myonTap: () => _onChipTap(2),
                  ),
                ],
              ),
              Gaps.v12,
              Text(
                '주 외출/음주 횟수를 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: [
                  CategoryButton(
                    text: '1-2회',
                    myonTap: () => _onChipTap(3),
                  ),
                  CategoryButton(
                    text: '3-4회',
                    myonTap: () => _onChipTap(3),
                  ),
                  CategoryButton(
                    text: '5회 이상',
                    myonTap: () => _onChipTap(3),
                  ),
                ],
              ),
              Gaps.v12,
              GestureDetector(
                onTap: _onNextTap,
                child: FormButton(
                  enabled: _checkNextButtonAvailable(),
                  text: "다음",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
