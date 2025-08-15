import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/dining_habit_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

class WorkPatternScreen extends StatefulWidget {
  const WorkPatternScreen({super.key});

  @override
  State<WorkPatternScreen> createState() => _WorkPatternScreenState();
}

class _WorkPatternScreenState extends State<WorkPatternScreen> {
  final List<List<bool>> _selectionStates = [
    List.filled(6, false),
    List.filled(6, false),
  ];
  List<bool> timeSelected = [false, false];

  final TextEditingController _goToWorkController = TextEditingController();
  final TextEditingController _backHomeController = TextEditingController();

  void _onChipTap(int groupIndex, int buttonIndex) {
    setState(() {
      _selectionStates[groupIndex][buttonIndex] =
          !_selectionStates[groupIndex][buttonIndex];
    });
  }

  bool _checkNextButtonAvailable() {
    final groupsOk = _selectionStates.every((g) => g.contains(true));
    final timesOk = timeSelected.every((t) => t); // 출근/귀가 둘 다 선택되어야
    return groupsOk && timesOk;
  }

  // ▼ 추가: 오전/오후(또는 24시간제)로 표시하는 포맷 함수
  String _formatTime(DateTime time) {
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final hour = time.hour;
    final minute = time.minute;

    if (use24h) {
      final hh = hour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh : $mm'; // 예: 14 : 05
    } else {
      final isAm = hour < 12;
      final period = isAm ? '오전' : '오후'; // AM/PM 한국어 표기
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final hh = hour12.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$period $hh : $mm'; // 예: 오후 02 : 05
    }
  }

  void _onTimePickerChanged(
    DateTime time,
    TextEditingController controller,
    int index,
  ) {
    // ▼ 변경: 문자열 자르기 대신 포맷 함수 사용 + setState로 즉시 반영
    final textTime = _formatTime(time);
    setState(() {
      controller.text = textTime;
      timeSelected[index] = true;
    });
  }

  void _onTimeFieldTap(TextEditingController controller, int index) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          onDateTimeChanged: (DateTime time) =>
              _onTimePickerChanged(time, controller, index),
        );
      },
    );
  }

  void _onNextTap() {
    if (_checkNextButtonAvailable()) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const DiningHabitScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '출퇴근 패턴을 선택해주세요!',
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
              Gaps.v12,
              Text(
                '출근 시간대를 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v6,
              TextField(
                onTap: () => _onTimeFieldTap(_goToWorkController, 0),
                readOnly: true,
                controller: _goToWorkController,
                decoration: InputDecoration(
                  hintText: "오전 08 : 00",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  suffixIcon: Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                cursorColor: Theme.of(context).primaryColor,
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
              TextField(
                onTap: () => _onTimeFieldTap(_backHomeController, 1),
                readOnly: true,
                controller: _backHomeController,
                decoration: InputDecoration(
                  hintText: "오후 09 : 00",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  suffixIcon: Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                cursorColor: Theme.of(context).primaryColor,
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
                children: List.generate(6, (buttonIndex) {
                  final textOptions = [
                    '0회',
                    '1-2회',
                    '2-3회',
                    '3-4회',
                    '4-5회',
                    '5회 이상',
                  ];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(1, buttonIndex),
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
                children: List.generate(6, (buttonIndex) {
                  final textOptions = [
                    '0회',
                    '1-2회',
                    '2-3회',
                    '3-4회',
                    '4-5회',
                    '5회 이상',
                  ];
                  return CategoryButton(
                    text: textOptions[buttonIndex],
                    myonTap: () => _onChipTap(0, buttonIndex),
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
