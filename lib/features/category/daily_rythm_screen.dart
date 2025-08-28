import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/time_field.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

/// 요일
class DayOption {
  final String label; // '월~일' or '없음'
  const DayOption(this.label); // 생성자
}

const keyDays = [
  DayOption('월'),
  DayOption('화'),
  DayOption('수'),
  DayOption('목'),
  DayOption('금'),
  DayOption('토'),
  DayOption('일'),
  DayOption('없음'),
];

/// 알람 횟수 (한국어 그대로)
class AlarmOption {
  final String label; // 1회, 2회, 3회 이상
  const AlarmOption(this.label);
}

const keyAlarms = [
  AlarmOption('1회'),
  AlarmOption('2회'),
  AlarmOption('3회'),
];

/// 시간 필드 식별자
enum TimeKey {
  weekAwake,
  weekGoWork,
  weekComeHome,
  weekSleep,
  weekendAwake,
  weekendSleep,
}

class DailyRythmScreen extends StatefulWidget {
  const DailyRythmScreen({super.key});

  @override
  State<DailyRythmScreen> createState() => _DailyRythmScreenState();
}

class _DailyRythmScreenState extends State<DailyRythmScreen> {
  final Set<String> _selectedDays = {}; // 월~일 , 없음
  final Set<String> _selectedAlarms = {}; // 1회~3회 이상
  bool get _isJobLess => _selectedDays.contains('없음');

  // 시간 필드
  final TextEditingController _weekAwakeCtrl = TextEditingController();
  final TextEditingController _weekGoWorkCtrl = TextEditingController();
  final TextEditingController _weekComeBackHomeCtrl = TextEditingController();
  final TextEditingController _weekSleepCtrl = TextEditingController();
  final TextEditingController _weekendAwakeCtrl = TextEditingController();
  final TextEditingController _weekendSleepCtrl = TextEditingController();

  /// 선택 여부를 리스트에 담는 함수.
  void _onDayChipTap(String day) {
    if (day == '없음') {
      if (_selectedDays.contains('없음')) {
        _selectedDays.remove('없음');
      } else {
        _selectedDays
          ..clear()
          ..add('없음');
        for (final controller in [
          _weekAwakeCtrl,
          _weekGoWorkCtrl,
          _weekComeBackHomeCtrl,
          _weekSleepCtrl,
        ]) {
          controller.clear();
        }
      }
    } else {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.remove('없음'); // 요일 선택 시 없음 해제
    }
    setState(() {});
    // 얘가 호출되면서 위젯을 모두 다시 그림.
    // 따라서 바뀐 bool 값으로 카테고리 버튼 색깔이 바뀜
  }

  void _onAlarmTap(String alarm) {
    if (_selectedAlarms.contains(alarm)) {
      _selectedAlarms.remove(alarm);
    } else {
      _selectedAlarms.add(alarm);
    }
    setState(() {});
  }

  void _onNextTap() {
    if (_isNextEnable()) {
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

  String _formatToHM(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')} : ${date.minute.toString().padLeft(2, '0')}';
  }

  void _onTimeFieldTap(
    TextEditingController controller,
    TimeKey key,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          onDateTimeChanged: (date) {
            final weekKeys = {
              TimeKey.weekAwake,
              TimeKey.weekGoWork,
              TimeKey.weekComeHome,
              TimeKey.weekSleep,
            };
            // 현재 키가 주중 키중 하나인가?
            final bool isWeekTime = weekKeys.contains(key);
            if (_isJobLess && isWeekTime) return;

            setState(() {
              controller.text = _formatToHM(date);
            });
          },
        );
      },
    );
  }

  bool _isTimeSelected(TextEditingController controller) =>
      controller.text.trim().isNotEmpty;

  bool _timesCheck() {
    if (_isJobLess) {
      return (_isTimeSelected(_weekendAwakeCtrl) &&
          _isTimeSelected(_weekendSleepCtrl));
    } else {
      return (_isTimeSelected(_weekAwakeCtrl) &&
          _isTimeSelected(_weekGoWorkCtrl) &&
          _isTimeSelected(_weekComeBackHomeCtrl) &&
          _isTimeSelected(_weekSleepCtrl) &&
          _isTimeSelected(_weekendAwakeCtrl) &&
          _isTimeSelected(_weekendSleepCtrl));
    }
  }

  bool _isNextEnable() {
    final daysCheck = _selectedDays.isNotEmpty;
    final alarmsCheck = _selectedAlarms.isNotEmpty;

    final timesCheck = _timesCheck();

    return daysCheck && alarmsCheck && timesCheck;
  }

  // Firestore 저장/전송용 페이로드 (한국어 값 그대로)
  Map<String, dynamic> _buildPayload() {
    int? _toMinutes(String textTime) {
      if (textTime.isEmpty) return null;
      final p = textTime.replaceAll(' ', '').split(':');
      if (p.length != 2) return null;
      final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
      if (h == null || m == null) return null;
      return h * 60 + m;
    }

    return {
      'days': _selectedDays.toList(), // 예: ['월','수'] 또는 ['없음']
      'alarms': _selectedAlarms.toList(), // 예: ['2회']
      'isJobLess': _isJobLess,
      'weekAwakeMins': _toMinutes(_weekAwakeCtrl.text),
      'weekGoWorkMins': _toMinutes(_weekGoWorkCtrl.text),
      'weekBackHomeMins': _toMinutes(_weekComeBackHomeCtrl.text),
      'weekSleepMins': _toMinutes(_weekSleepCtrl.text),
      'weekendAwakeMins': _toMinutes(_weekendAwakeCtrl.text),
      'weekendSleepMins': _toMinutes(_weekendSleepCtrl.text),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _weekAwakeCtrl.dispose();
    _weekGoWorkCtrl.dispose();
    _weekComeBackHomeCtrl.dispose();
    _weekSleepCtrl.dispose();
    _weekendAwakeCtrl.dispose();
    _weekendSleepCtrl.dispose();
    super.dispose();
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
                  '출근 요일을 알려주세요!',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gaps.v6,
                Wrap(
                  spacing: Sizes.size8,
                  runSpacing: Sizes.size8,
                  children: [
                    for (final days in keyDays)
                      CategoryButton(
                        text: days.label,
                        isSelected: _selectedDays.contains(days.label),
                        myonTap: () => _onDayChipTap(days.label),
                      ),
                  ],
                ),
                Gaps.v12,
                TimeField(
                  question: "출근일 기상 시간을 알려주세요",
                  onTimeFieldTap: () =>
                      _onTimeFieldTap(_weekAwakeCtrl, TimeKey.weekAwake),
                  controller: _weekAwakeCtrl,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12,
                TimeField(
                  question: "출근 시간을 알려주세요",
                  onTimeFieldTap: () => _onTimeFieldTap(
                    _weekGoWorkCtrl,
                    TimeKey.weekGoWork,
                  ),
                  controller: _weekGoWorkCtrl,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12,
                TimeField(
                  question: "퇴근 시간을 알려주세요",
                  onTimeFieldTap: () => _onTimeFieldTap(
                    _weekComeBackHomeCtrl,
                    TimeKey.weekComeHome,
                  ),
                  controller: _weekComeBackHomeCtrl,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12,
                TimeField(
                  question: "출근일 취침 시간을 알려주세요",
                  onTimeFieldTap: () =>
                      _onTimeFieldTap(_weekSleepCtrl, TimeKey.weekSleep),
                  controller: _weekSleepCtrl,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12,
                TimeField(
                  question: "휴일 기상 시간을 알려주세요",
                  onTimeFieldTap: () => _onTimeFieldTap(
                    _weekendAwakeCtrl,
                    TimeKey.weekendSleep,
                  ),
                  controller: _weekendAwakeCtrl,
                  isJobLess: false,
                ),
                Gaps.v12,
                TimeField(
                  question: "휴일 취침 시간을 알려주세요",
                  onTimeFieldTap: () => _onTimeFieldTap(
                    _weekendSleepCtrl,
                    TimeKey.weekendSleep,
                  ),
                  controller: _weekendSleepCtrl,
                  isJobLess: false,
                ),
                Gaps.v12,
                Text(
                  '기상 전 알람 듣는 횟수를 알려주세요!',
                  style: TextStyle(
                    fontSize: Sizes.size16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gaps.v6,
                Wrap(
                  spacing: Sizes.size8,
                  runSpacing: Sizes.size8,
                  children: [
                    for (final alarms in keyAlarms)
                      CategoryButton(
                        text: alarms.label,
                        myonTap: () => _onAlarmTap(alarms.label),
                        isSelected: _selectedAlarms.contains(alarms.label),
                      ),
                  ],
                ),
                Gaps.v24,
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled: _isNextEnable(),
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
