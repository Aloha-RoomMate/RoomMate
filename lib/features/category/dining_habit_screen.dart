import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/sound_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/selection_chip.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class DiningHabitScreen extends StatefulWidget {
  const DiningHabitScreen({super.key});

  @override
  State<DiningHabitScreen> createState() => _DiningHabitScreenState();
}

class _DiningHabitScreenState extends State<DiningHabitScreen> {
  List<List<bool>> _chipOptionSelected = [
    List.filled(6, false),
    List.filled(3, false),
    List.filled(2, false),
    List.filled(6, false),
  ];

  void _onChipTap(int groupIndex, int buttonIndex) {
    setState(() {
      _chipOptionSelected[groupIndex][buttonIndex] =
          !_chipOptionSelected[groupIndex][buttonIndex];
    });
  }

  bool _checkNextButtonAvailable() {
    for (final groupState in _chipOptionSelected) {
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
          builder: (context) => SoundScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '식사 습관을 선택해주세요!',
          style: TextStyle(
            fontSize: Sizes.size24,
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
              SelectionChip(
                textOptions: [
                  '전혀 안 해요',
                  '1-2회',
                  '2-3회',
                  '3-4회',
                  '4-5회',
                  '5회 이상',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 0,
                question: '주 요리 빈도를 선택해주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '둔감해요',
                  '보통이예요',
                  '예민한 편이예요',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 1,
                question: '냄새 민감도를 알려주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: ['같이 써요', '개인 식기를 선호해요'],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 2,
                question: '공용 식기 선호도를 알려주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '전혀 안 시켜요',
                  '1-2회',
                  '2-3회',
                  '3-4회',
                  '4-5회',
                  '5회 이상',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 3,
                question: '주 배달 횟수를 선택해주세요!',
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

