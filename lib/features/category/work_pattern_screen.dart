import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/dining_habit_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class WorkPatternScreen extends StatefulWidget {
  const WorkPatternScreen({super.key});

  @override
  State<WorkPatternScreen> createState() => _WorkPatternScreenState();
}

class _WorkPatternScreenState extends State<WorkPatternScreen> {
  List<List<bool>> _selectionStates = [
    List.filled(4, false),
    List.filled(5, false),
    List.filled(4, false),
    List.filled(5, false),
    List.filled(5, false),
  ];

  void _onChipTap(int groupIndex, int buttonIndex) {
    setState(() {
      _selectionStates[groupIndex][buttonIndex] =
          !_selectionStates[groupIndex][buttonIndex];
    });
  }

  bool _checkNextButtonAvailable() {
    for (final groupState in _selectionStates) {
      if (!groupState.contains(true)) {
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
          builder: (context) => DiningHabitScreen(),
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
            fontSize: Sizes.size20 + Sizes.size2,
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
                '출퇴근 형태를 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: List.generate(4, (buttonIndex) {
                  final textOptions = ['회사/학교', '재택', '프리랜서', '대학생'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(0, buttonIndex),
                  );
                }),
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
                children: List.generate(5, (buttonIndex) {
                  final textOptions = ['5-6시', '6-7시', '7-8시', '8-9시', '9시 이후'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(1, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '출근일 귀가 시간대를 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: List.generate(4, (buttonIndex) {
                  final textOptions = ['18-19시', '19-20시', '20-21시', '21시 이후'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(2, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '주 야근/밤 공부 횟수를 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: List.generate(5, (buttonIndex) {
                  final textOptions = [
                    '1-2회',
                    '2-3회',
                    '3-4회',
                    '4-5회',
                    '5회 이상',
                  ];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(3, buttonIndex),
                  );
                }),
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
                children: List.generate(5, (buttonIndex) {
                  final textOptions = ['1-2회', '2-3회', '3-4회', '4-5회', '5회 이상'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(4, buttonIndex),
                  );
                }),
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
