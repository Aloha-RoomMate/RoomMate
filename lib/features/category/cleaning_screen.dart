import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/etc_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/selection_chip.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class CleaningScreen extends StatefulWidget {
  const CleaningScreen({super.key});

  @override
  State<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends State<CleaningScreen> {
  List<List<bool>> _chipOptionSelected = [
    List.filled(3, false),
    List.filled(3, false),
    List.filled(3, false),
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
          builder: (context) => EtcScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '청소 습관을 알려주세요!',
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
              SelectionChip(
                textOptions: [
                  '잘 하지 않아요',
                  '더러워지면 해요',
                  '주 1-2회 정리해요',
                  '매일/자주 정리해요',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 0,
                question: '방 청소 빈도를 선택해주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '주 1회 교대 청소해요',
                  '더러워지면 청소해요',
                  '사용 후 바로 청소해요',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 1,
                question: '화장실 청소 선호도를 알려주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '항상 제자리에 둬요',
                  '일정 기준 아래로는 깔끔하게 유지해요',
                  '필요할 때만 해요',
                  '어지럽혀도 상관없어요',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 2,
                question: '정리정돈 성향을 알려주세요!',
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
