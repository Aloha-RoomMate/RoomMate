import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/etc_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  List<List<bool>> _selectionStates = [
    List.filled(3, false),
    List.filled(5, false),
    List.filled(5, false),
    List.filled(3, false),
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
          '소리 민감도를 선택해주세요!',
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
                '잠귀 민감도를 선택해주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: List.generate(3, (buttonIndex) {
                  final textOptions = ['둔감해요', '보통이예요', '예민한 편이예요'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(0, buttonIndex),
                    isSelected: _selectionStates[0][buttonIndex],
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '잠버릇을 선택해주세요!',
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
                    '잠 버릇이 없어요',
                    '코를 골아요',
                    '피곤하면 코를 골아요',
                    '이를 갈아요',
                    '피곤하면 이를 갈아요',
                  ];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(1, buttonIndex),
                    isSelected: _selectionStates[1][buttonIndex],
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '선호하는 소리/진동/무음 모드를 알려주세요!',
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
                    '항상 소리',
                    '항상 진동',
                    '항상 무음',
                    '잘 때 진동',
                    '잘 때 무음',
                  ];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(2, buttonIndex),
                    isSelected: _selectionStates[2][buttonIndex],
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '선호하는 이어폰 사용 형태!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: List.generate(3, (buttonIndex) {
                  final textOptions = ['항상', '밤에만', '신경 안써요'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(3, buttonIndex),
                    isSelected: _selectionStates[3][buttonIndex],
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
