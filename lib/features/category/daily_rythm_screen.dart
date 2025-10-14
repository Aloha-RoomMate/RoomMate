// features/category/daily_rythm_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/time_field.dart';
import 'package:roommate/features/category/coliving_screen.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class DayOption {
  final String label;
  const DayOption(this.label);
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

enum TimeKey { weekAwake, weekSleep }

class DailyRhythmScreen extends StatefulWidget {
  const DailyRhythmScreen({super.key, this.returnAfterSave = false});
  final bool returnAfterSave;

  @override
  State<DailyRhythmScreen> createState() => _DailyRhythmScreenState();
}

class _DailyRhythmScreenState extends State<DailyRhythmScreen> {
  final Set<String> _selectedDays = {};
  final UserRepository _userRepository = UserRepository();
  bool get _isJobLess => _selectedDays.contains('없음');
  bool _isSending = false;

  final TextEditingController _weekAwakeCtrl = TextEditingController();
  final TextEditingController _weekSleepCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final me = await _userRepository.fetchMe();
    final dr = me?.dailyRhythm;
    if (dr != null) {
      _selectedDays
        ..clear()
        ..addAll(dr.workDays);
      if (dr.isJobLess) {
        _selectedDays
          ..clear()
          ..add('없음');
        _weekAwakeCtrl.clear();
        _weekSleepCtrl.clear();
      } else {
        if (dr.weekAwakeMins != null) {
          _weekAwakeCtrl.text = _formatToHMMinutes(dr.weekAwakeMins!);
        }
        if (dr.weekSleepMins != null) {
          _weekSleepCtrl.text = _formatToHMMinutes(dr.weekSleepMins!);
        }
      }
      if (mounted) setState(() {});
    }
  }

  String _formatToHMMinutes(int mins) {
    final h = (mins ~/ 60) % 24;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')} : ${m.toString().padLeft(2, '0')}';
  }

  void _onDayChipTap(String day) {
    if (day == '없음') {
      if (_selectedDays.contains('없음')) {
        _selectedDays.remove('없음');
      } else {
        _selectedDays
          ..clear()
          ..add('없음');
        for (final controller in [_weekAwakeCtrl, _weekSleepCtrl]) {
          controller.clear();
        }
      }
    } else {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.remove('없음');
    }
    setState(() {});
  }

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

        await _userRepository.setDailyRhythm(rhythm);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 성공')),
        );

        setState(() {
          _isSending = false;
        });

        if (widget.returnAfterSave) {
          Navigator.of(context).pop(true); // ✅ 수정 모드
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ColivingScreen()),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터 저장 중 에러 발생')),
        );
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

  Future<void> _onTimeFieldTap(
    TextEditingController controller,
    TimeKey key,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          onDateTimeChanged: (date) {
            final weekKeys = {TimeKey.weekAwake, TimeKey.weekSleep};
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
    return (_isJobLess) || (daysCheck && timesCheck);
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
            style: TextStyle(fontSize: ResponsiveSizes.f(context, 22)),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(
            left: ResponsiveSizes.p(context, 24),
            right: ResponsiveSizes.p(context, 24),
            bottom: ResponsiveSizes.p(context, 24),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '출근 요일을 알려주세요!',
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gaps.v6(context),
                Wrap(
                  spacing: ResponsiveSizes.p(context, 8),
                  runSpacing: ResponsiveSizes.p(context, 8),
                  children: [
                    for (final days in keyDays)
                      CategoryButton(
                        text: days.label,
                        isSelected: _selectedDays.contains(days.label),
                        myonTap: () => _onDayChipTap(days.label),
                      ),
                  ],
                ),
                Gaps.v12(context),
                TimeField(
                  question: "출근일 기상 시간을 알려주세요",
                  onTimeFieldTap: () =>
                      _onTimeFieldTap(_weekAwakeCtrl, TimeKey.weekAwake),
                  controller: _weekAwakeCtrl,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12(context),
                TimeField(
                  question: "출근일 취침 시간을 알려주세요",
                  onTimeFieldTap: () =>
                      _onTimeFieldTap(_weekSleepCtrl, TimeKey.weekSleep),
                  controller: _weekSleepCtrl,
                  isJobLess: _isJobLess,
                ),
                Gaps.v24(context),
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled: _isNextEnable(),
                    widget: _isSending
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.returnAfterSave ? '저장' : '다음',
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
