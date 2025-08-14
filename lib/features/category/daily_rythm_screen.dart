import 'package:flutter/cupertino.dart';
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
  List<List<bool>> _daySelected = [
    List.filled(7, false),
    List.filled(3, false),
  ];
  List<bool> timeSelected = [false, false, false, false];
  Duration _goOfficeTime = Duration();
  Duration _goHomeTime = Duration();

  final TextEditingController _weekWakeUpController = TextEditingController();
  final TextEditingController _weekSleepController = TextEditingController();
  final TextEditingController _weekendWakeUpController =
      TextEditingController();
  final TextEditingController _weekendSleepController = TextEditingController();

  void _onChipTap(int groupIndex, int buttonIndex) {
    setState(() {
      _daySelected[groupIndex][buttonIndex] =
          !_daySelected[groupIndex][buttonIndex];
    });
  }

  bool _checkNextButtonAvailable() {
    for (final groupState in _daySelected) {
      if (!groupState.contains(true) || timeSelected.contains(false)) {
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

  void _onScaffoldTap() {
    FocusScope.of(context).unfocus();
  }

  void _onTimePickerChanged(
    DateTime time,
    TextEditingController controller,
    int index,
  ) {
    final textTime =
        time.toString().split(' ')[1].split(':')[0] +
        ' : ' +
        time.toString().split(' ')[1].split(':')[1];
    // 얘가 있어야 텍스트 필드 업데이트
    controller.value = TextEditingValue(text: textTime);
    timeSelected[index] = true;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
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
                TextField(
                  onTap: () => _onTimeFieldTap(_weekWakeUpController, 0),
                  readOnly: true,
                  controller: _weekWakeUpController,
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  cursorColor: Theme.of(context).primaryColor,
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
                TextField(
                  onTap: () => _onTimeFieldTap(_weekSleepController, 1),
                  readOnly: true,
                  controller: _weekSleepController,
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  cursorColor: Theme.of(context).primaryColor,
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
                TextField(
                  onTap: () => _onTimeFieldTap(_weekendSleepController, 2),
                  readOnly: true,
                  controller: _weekendSleepController,
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  cursorColor: Theme.of(context).primaryColor,
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
                TextField(
                  onTap: () => _onTimeFieldTap(_weekendWakeUpController, 3),
                  readOnly: true,
                  controller: _weekendWakeUpController,
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  cursorColor: Theme.of(context).primaryColor,
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
                      myonTap: () => _onChipTap(1, buttonIndex),
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
      ),
    );
  }
}
