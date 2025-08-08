import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class DailyRythmScreen extends StatefulWidget {
  const DailyRythmScreen({super.key});

  @override
  State<DailyRythmScreen> createState() => _DailyRythmScreenState();
}

class _DailyRythmScreenState extends State<DailyRythmScreen> {
  List<List<bool>> _selectionStates = [
    List.filled(7, false),
    List.filled(4, false),
    List.filled(4, false),
    List.filled(5, false),
    List.filled(4, false),
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
          '하루 리듬을 선택해주세요!',
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
              Text(
                '출근일을 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: List.generate(7, (buttonIndex) {
                  final textOptions = ['월', '화', '수', '목', '금', '토', '일'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(0, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '출근일 기상 시간을 알려주세요!',
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
                  final textOptions = ['5-6시', '6-7시', '7-8시', '8-9시', '9시 이후'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(1, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '출근일 취침 시간을 알려주세요!',
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
                  final textOptions = ['21-22시', '22-23시', '23-00시', '00시 이후'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(2, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '휴일 기상 시간을 알려주세요!',
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
                    '7-8시',
                    '8-9시',
                    '9-10시',
                    '10-11시',
                    '11시 이후',
                  ];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(3, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '휴일 취침 시간을 알려주세요!',
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
                  final textOptions = ['21-22시', '22-23시', '23-00시', '00시 이후'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(4, buttonIndex),
                  );
                }),
              ),
              Gaps.v12,
              Text(
                '일어날 때까지 알람 울리는 횟수를 알려주세요!',
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
                  final textOptions = ['1회', '2회', '3회'];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(5, buttonIndex),
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
