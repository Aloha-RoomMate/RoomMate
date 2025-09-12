import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/time_field.dart';
import 'package:roommate/features/category/coliving_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

/// 시간 필드 식별자
enum TimeKey {
  weekAwake,
  weekSleep,
}

class DailyRhythmScreen extends StatefulWidget {
  const DailyRhythmScreen({super.key});

  @override
  State<DailyRhythmScreen> createState() => _DailyRhythmScreenState();
}

class _DailyRhythmScreenState extends State<DailyRhythmScreen> {
  final Set<String> _selectedDays = {}; // 월~일 , 없음
  final UserRepository _userRepository = UserRepository();
  bool get _isJobLess => _selectedDays.contains('없음');
  bool _isSending = false;

  // 시간 필드
  final TextEditingController _weekAwakeCtrl = TextEditingController();
  final TextEditingController _weekSleepCtrl = TextEditingController();

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

  /// 시간 int로 바꿔주면 나중에 편함.
  int? toMinutes(String textTime) {
    if (textTime.isEmpty) return null;
    final p = textTime.replaceAll(' ', '').split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  void _onNextTap() async {
    if (_isNextEnable()) {
      try {
        setState(() {
          _isSending = true;
        });
        final rhythm = DailyRhythm(
          workDays: _selectedDays.toList(),
          isJobLess: _isJobLess,
          weekAwakeMins: _isJobLess ? null : toMinutes(_weekAwakeCtrl.text),
          weekSleepMins: _isJobLess ? null : toMinutes(_weekSleepCtrl.text),
        );

        // 실제 데이터 넘기는 부분
        await _userRepository.setDailyRhythm(rhythm);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 성공'),
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ColivingScreen(),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 저장 중 에러 발생'),
          ),
        );
        // context 쓸거면 mounted 확인
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
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
    return (!_isJobLess &&
        _isTimeSelected(_weekAwakeCtrl) &&
        _isTimeSelected(_weekSleepCtrl));
  }

  bool _isNextEnable() {
    final daysCheck = _selectedDays.isNotEmpty;
    final timesCheck = _timesCheck();

    return (daysCheck || _isJobLess) && timesCheck;
  }

  @override
  void dispose() {
    _weekAwakeCtrl.dispose();
    _weekSleepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '생활 리듬을 선택해주세요!',
            style: TextStyle(
              fontSize: Sizes.size20 + Sizes.size2,
            ),
          ),
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
                  question: "출근일 취침 시간을 알려주세요",
                  onTimeFieldTap: () =>
                      _onTimeFieldTap(_weekSleepCtrl, TimeKey.weekSleep),
                  controller: _weekSleepCtrl,
                  isJobLess: _isJobLess,
                ),
                Gaps.v24,
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled: _isNextEnable(),
                    widget: _isSending
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '다음',
                            textAlign: TextAlign.center,
                          ),
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
