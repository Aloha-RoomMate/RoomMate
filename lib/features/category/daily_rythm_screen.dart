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
  // [0] 출근 요일(월~일, 없음) = 8개 / [1] 알람 횟수 = 4개
  final List<List<bool>> _daySelected = [
    List.filled(8, false),
    List.filled(4, false),
  ];
  // [0]=주중 기상, [1]=주중 취침, [2]=주말 기상, [3]=주말 취침
  List<bool> timeSelected = [false, false, false, false];

  final TextEditingController _weekWakeUpController = TextEditingController();
  final TextEditingController _weekSleepController = TextEditingController();
  final TextEditingController _weekendWakeUpController =
      TextEditingController();
  final TextEditingController _weekendSleepController = TextEditingController();

  bool get _noWorkday => _daySelected[0][7]; // '없음'
  bool get _anyWeekday => _daySelected[0].sublist(0, 7).contains(true);

  void _onChipTap(int groupIndex, int buttonIndex) {
    setState(() {
      _daySelected[groupIndex][buttonIndex] =
          !_daySelected[groupIndex][buttonIndex];

      if (groupIndex == 0) {
        if (buttonIndex == 7 && _daySelected[0][7]) {
          // '없음' 선택: 다른 요일 해제 + 주중 시간 초기화
          for (int i = 0; i < 7; i++) {
            _daySelected[0][i] = false;
          }
          _weekWakeUpController.clear();
          _weekSleepController.clear();
          timeSelected[0] = false;
          timeSelected[1] = false;
        } else if (buttonIndex != 7 && _daySelected[0][buttonIndex]) {
          // 요일 하나라도 선택하면 '없음' 해제
          _daySelected[0][7] = false;
        }
      }
    });
  }

  bool _checkNextButtonAvailable() {
    final group0Ok = _anyWeekday || _noWorkday; // 출근 요일 조건
    final group1Ok = _daySelected[1].contains(true); // 알람 선택 조건

    final weekdayTimesOk = _anyWeekday
        ? (timeSelected[0] && timeSelected[1]) // 주중 요일 선택 시에만 요구
        : true; // '없음'이면 면제
    final weekendTimesOk = timeSelected[2] && timeSelected[3]; // 주말 시간 2칸은 필수

    return group0Ok && group1Ok && weekdayTimesOk && weekendTimesOk;
  }

  void _onNextTap() {
    if (_checkNextButtonAvailable()) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => WorkPatternScreen()));
    }
  }

  void _onScaffoldTap() => FocusScope.of(context).unfocus();

  String _formatTime(DateTime time) {
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final hour = time.hour;
    final minute = time.minute;

    if (use24h) {
      final hh = hour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh : $mm';
    } else {
      final isAm = hour < 12;
      final period = isAm ? '오전' : '오후';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      final hh = hour12.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$period $hh : $mm';
    }
  }

  void _onTimePickerChanged(
    DateTime time,
    TextEditingController controller,
    int index,
  ) {
    final textTime = _formatTime(time);
    setState(() {
      controller.text = textTime;
      timeSelected[index] = true; // 버튼 활성화 재계산을 위해 setState 안에서 처리
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

  @override
  Widget build(BuildContext context) {
    final disabledColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '하루 리듬을 선택해주세요!',
            style: TextStyle(fontSize: Sizes.size24),
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
                // 출근 요일
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
                  children: List.generate(8, (buttonIndex) {
                    final textOptions = [
                      '월',
                      '화',
                      '수',
                      '목',
                      '금',
                      '토',
                      '일',
                      '없음',
                    ];
                    return CategoryButton(
                      text: textOptions[buttonIndex],
                      myonTap: () => _onChipTap(0, buttonIndex),
                    );
                  }),
                ),

                // 출근일 기상
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
                  onTap: _noWorkday
                      ? null
                      : () => _onTimeFieldTap(_weekWakeUpController, 0),
                  readOnly: true,
                  enabled: !_noWorkday,
                  controller: _weekWakeUpController,
                  decoration: InputDecoration(
                    hintText: "오전 07 : 00",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    suffixIcon: Icon(
                      Icons.access_time_rounded,
                      size: Sizes.size18,
                      color: _noWorkday
                          ? disabledColor
                          : Theme.of(context).primaryColor,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                  ),
                  cursorColor: Theme.of(context).primaryColor,
                ),

                // 출근일 취침
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
                  onTap: _noWorkday
                      ? null
                      : () => _onTimeFieldTap(_weekSleepController, 1),
                  readOnly: true,
                  enabled: !_noWorkday,
                  controller: _weekSleepController,
                  decoration: InputDecoration(
                    hintText: "오후 12 : 00",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    suffixIcon: Icon(
                      Icons.access_time_rounded,
                      size: Sizes.size18,
                      color: _noWorkday
                          ? disabledColor
                          : Theme.of(context).primaryColor,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                  ),
                  cursorColor: Theme.of(context).primaryColor,
                ),

                // 휴일 기상
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
                    hintText: "오전 09 : 00",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    suffixIcon: Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                  ),
                  cursorColor: Theme.of(context).primaryColor,
                ),

                // 휴일 취침
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
                    hintText: "오후 12 : 00",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    suffixIcon: Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                  ),
                  cursorColor: Theme.of(context).primaryColor,
                ),

                // 알람 횟수
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
                  children: List.generate(4, (buttonIndex) {
                    final textOptions = ['0회', '1회', '2회', '3회'];
                    return CategoryButton(
                      text: textOptions[buttonIndex],
                      myonTap: () => _onChipTap(1, buttonIndex),
                    );
                  }),
                ),

                // 다음 버튼
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
