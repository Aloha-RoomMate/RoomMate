import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/etc_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/selection_chip.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  List<List<bool>> _chipOptionSelected = [
    List.filled(3, false),
    List.filled(5, false),
    List.filled(5, false),
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
              SelectionChip(
                textOptions: [
                  '둔감해요',
                  '보통이예요',
                  '예민한 편이예요',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 0,
                question: '잠귀 민감도를 선택해주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '잠버릇이 없어요',
                  '자주 코를 골아요',
                  '피곤하면 코를 골아요',
                  '자주 이를 갈아요',
                  '피곤하면 이를 갈아요',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 1,
                question: '잠버릇을 선택해주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '항상 소리',
                  '항상 진동',
                  '항상 무음',
                  '잘 때 진동',
                  '잘 때 무음',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 2,
                question: '선호하는 소리/진동/무음 모드를 알려주세요!',
              ),
              Gaps.v12,
              SelectionChip(
                textOptions: [
                  '항상',
                  '밤에만',
                  '신경 안 써요',
                ],
                onChipTap: _onChipTap,
                checkList: _chipOptionSelected,
                indexOfQuestion: 3,
                question: '선호하는 이어폰 사용 형태를 선택해주세요!',
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
