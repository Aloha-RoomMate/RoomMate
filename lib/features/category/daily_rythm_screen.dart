import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/selection_chip.dart';
import 'package:roommate/features/category/widgets/time_field.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class DailyRythmScreen extends StatefulWidget {
  const DailyRythmScreen({super.key});

  @override
  State<DailyRythmScreen> createState() => _DailyRythmScreenState();
}

class _DailyRythmScreenState extends State<DailyRythmScreen> {
  List<List<bool>> _chipOptionSelected = [
    List.filled(8, false),
    List.filled(3, false),
  ]; // 초이스칩 선택 현황

  List<bool> timeOptionSelected = [
    false,
    false,
    false,
    false,
    false,
    false,
  ]; // 시간 선택지 입력 현황

  final TextEditingController _weekAwakeController = TextEditingController();
  final TextEditingController _weekGoWorkController = TextEditingController();
  final TextEditingController _weekComeBackHomeController =
      TextEditingController();
  final TextEditingController _weekSleepController = TextEditingController();
  final TextEditingController _weekendAwakeController = TextEditingController();
  final TextEditingController _weekendSleepController = TextEditingController();
  bool _isJobLess = false;

  void _onChipTap(int groupIndex, int buttonIndex) {
    // '없음' 클릭 시
    if (groupIndex == 0 && buttonIndex == 7) {
      _isJobLess = !_isJobLess;
      if (_isJobLess) {
        for (int i = 0; i < 7; i++) {
          _chipOptionSelected[0][i] = false; // 모든 요일 클리어
        }
        _chipOptionSelected[0][7] = true;

        _weekAwakeController.clear();
        _weekGoWorkController.clear();
        _weekComeBackHomeController.clear();
        _weekSleepController.clear();
      } else {
        // 백수 아니면
        _chipOptionSelected[0][7] = false;
      }
    }
    // 요일 클릭 시
    else {
      if (_isJobLess && groupIndex == 0) {
        _isJobLess = !_isJobLess;
        _chipOptionSelected[0][7] = false;
      }
      _chipOptionSelected[groupIndex][buttonIndex] =
          !_chipOptionSelected[groupIndex][buttonIndex];
    }

    setState(() {});
    // 얘가 호출되면서 위젯을 모두 다시 그림.
    // 따라서 바뀐 bool 값으로 카테고리 버튼 색깔이 바뀜
  }

  bool _checkNextButtonAvailable() {
    for (final groupState in _chipOptionSelected) {
      if (!groupState.contains(true) ||
          (timeOptionSelected.contains(false) && _isJobLess == false)) {
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
    timeOptionSelected[index] = true;
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
                Gaps.v6,
                SelectionChip(
                  textOptions: ['월', '화', '수', '목', '금', '토', '일', '없음'],
                  onChipTap: _onChipTap,
                  checkList: _chipOptionSelected,
                  indexOfQuestion: 0,
                  question: "출근일, 등교일을 알려주세요!",
                ),
                Gaps.v12,
                TimeField(
                  question: "출근일 기상 시간을 알려주세요",
                  onTimeFieldTap: _onTimeFieldTap,
                  controller: _weekAwakeController,
                  indexOfQuestion: 0,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12,
                TimeField(
                  question: "출근 시간을 알려주세요",
                  onTimeFieldTap: _onTimeFieldTap,
                  controller: _weekGoWorkController,
                  indexOfQuestion: 1,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12,
                TimeField(
                  question: "퇴근 시간을 알려주세요",
                  onTimeFieldTap: _onTimeFieldTap,
                  controller: _weekComeBackHomeController,
                  indexOfQuestion: 2,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12,
                TimeField(
                  question: "출근일 취침 시간을 알려주세요",
                  onTimeFieldTap: _onTimeFieldTap,
                  controller: _weekSleepController,
                  indexOfQuestion: 3,
                  isJobLess: _isJobLess,
                ),
                Gaps.v12,
                TimeField(
                  question: "휴일 기상 시간을 알려주세요",
                  onTimeFieldTap: _onTimeFieldTap,
                  controller: _weekendAwakeController,
                  indexOfQuestion: 4,
                  isJobLess: false,
                ),
                Gaps.v12,
                TimeField(
                  question: "휴일 취침 시간을 알려주세요",
                  onTimeFieldTap: _onTimeFieldTap,
                  controller: _weekendSleepController,
                  indexOfQuestion: 5,
                  isJobLess: false,
                ),
                Gaps.v12,
                SelectionChip(
                  textOptions: ['1회', '2회', '3회 이상'],
                  onChipTap: _onChipTap,
                  checkList: _chipOptionSelected,
                  indexOfQuestion: 1,
                  question: "일어날 때까지 알람 듣는 횟수를 알려주세요!",
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