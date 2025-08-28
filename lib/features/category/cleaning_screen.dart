import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/etc_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

class RoomCleanOption {
  final String label;
  const RoomCleanOption(this.label);
}

const keyRoomClean = [
  RoomCleanOption('잘 하지 않아요'),
  RoomCleanOption('더러워지면 해요'),
  RoomCleanOption('주 1-2회 정리해요'),
];

class BathroomCleanOption {
  final String label;
  const BathroomCleanOption(this.label);
}

const keyBathroomClean = [
  BathroomCleanOption('주 1회 교대로 청소해요'),
  BathroomCleanOption('더러워지면 청소해요'),
  BathroomCleanOption('사용 후 그때그때 청소해요'),
];

class CleaningHabit {
  final String label;
  const CleaningHabit(this.label);
}

const keyCleaningHabit = [
  CleaningHabit('항상 제자리에 둬요'),
  CleaningHabit('일정 기준에 맞게 깔끔하게 유지해요'),
  CleaningHabit('필요할 때만 해요'),
];

class CleaningScreen extends StatefulWidget {
  const CleaningScreen({super.key});

  @override
  State<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends State<CleaningScreen> {
  final Set<String> _selectedRoomClean = {};
  final Set<String> _selectedBathroomCleanOption = {};
  final Set<String> _selectedCleaningHabit = {};

  void _onSleepSoundChipTap(String option) {
    if (_selectedRoomClean.contains(option)) {
      _selectedRoomClean.remove(option);
    } else {
      _selectedRoomClean.add(option);
    }
    setState(() {});
  }

  void _onBathroomCleanOptionChipTap(String option) {
    if (_selectedBathroomCleanOption.contains(option)) {
      _selectedBathroomCleanOption.remove(option);
    } else {
      _selectedBathroomCleanOption.add(option);
    }
    setState(() {});
  }

  void _onCleaningHabitChipTap(String option) {
    if (_selectedCleaningHabit.contains(option)) {
      _selectedCleaningHabit.remove(option);
    } else {
      _selectedCleaningHabit.add(option);
    }
    setState(() {});
  }

  bool _isNextEnable() {
    return _selectedRoomClean.isNotEmpty &&
        _selectedBathroomCleanOption.isNotEmpty &&
        _selectedCleaningHabit.isNotEmpty;
  }

  void _onNextTap() {
    if (_isNextEnable()) {
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
          '청소 습관을 선택해주세요!',
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
                '방 청소 성향을 알려주세요',
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
                  for (final room in keyRoomClean)
                    CategoryButton(
                      text: room.label,
                      myonTap: () => _onSleepSoundChipTap(room.label),
                      isSelected: _selectedRoomClean.contains(room.label),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '선호하는 화장실 청소 형태를 알려주세요',
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
                  for (final bathroom in keyBathroomClean)
                    CategoryButton(
                      text: bathroom.label,
                      myonTap: () =>
                          _onBathroomCleanOptionChipTap(bathroom.label),
                      isSelected: _selectedBathroomCleanOption.contains(
                        bathroom.label,
                      ),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '정리정돈 성향을 알려주세요',
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
                  for (final habit in keyCleaningHabit)
                    CategoryButton(
                      text: habit.label,
                      myonTap: () => _onCleaningHabitChipTap(habit.label),
                      isSelected: _selectedCleaningHabit.contains(habit.label),
                    ),
                ],
              ),
              Gaps.v12,
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
    );
  }
}
