import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/selection_chip.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class EtcScreen extends StatefulWidget {
  const EtcScreen({super.key});

  @override
  State<EtcScreen> createState() => _EtcScreenState();
}

class _EtcScreenState extends State<EtcScreen> {
  List<List<bool>> _chipOptionSelected = [
    List.filled(4, false),
    List.filled(4, false),
    List.filled(8, false),
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
          builder: (context) => DiseaseScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '기타 생활 습관을 알려주세요!',
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
                  '연초',
                  '궐련형',
                  '액상 전자담배',
                  '비흡연',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 0,
                question: '흡연 여부를 선택해주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '상관 없어요',
                  '전자담배 가능',
                  '궐련형 가능',
                  '절대 안 돼요',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 1,
                question: '실내 흡연 허용 정도를 알려주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '없음',
                  '강아지',
                  '고양이',
                  '물고기',
                  '양서류',
                  '파충류',
                  '무척추동물(곤충)',
                  '조류',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 2,
                question: '키우는 반려동물을 적어주세요!',
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
