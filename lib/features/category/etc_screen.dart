import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

class EtcScreen extends StatefulWidget {
  const EtcScreen({super.key});

  @override
  State<EtcScreen> createState() => _EtcScreenState();
}

class _EtcScreenState extends State<EtcScreen> {
  final List<List<bool>> _selectionStates = [
    List.filled(4, false),
    List.filled(4, false),
    List.filled(9, false),
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
      ).push(MaterialPageRoute(builder: (context) => DiseaseScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '기타 생활 습관을 알려주세요!',
          style: TextStyle(fontSize: Sizes.size20 + Sizes.size2),
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
                '흡연 여부를 선택해주세요!',
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
                  final textOptions = ['연초', '궐련형', '전자담배', '비흡연'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(0, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '실내 흡연 허용 정도를 알려주세요!',
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
                  final textOptions = ['상관 없어요', '전자담배', '궐련형', '절대 안 돼요'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(1, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '키우는 반려 동물을 적어주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: List.generate(8, (buttonIndex) {
                  final textOptions = [
                    '없음',
                    '강아지',
                    '고양이',
                    '물고기',
                    '양서류',
                    '파충류',
                    '무척추동물(곤충)',
                    '조류',
                    '식물',
                  ];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(2, buttonIndex),
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
