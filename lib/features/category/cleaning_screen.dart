import 'package:cloud_firestore/cloud_firestore.dart';
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
  RoomCleanOption('항상 제자리에 둬요'),
  RoomCleanOption('대체로 정돈된 편이예요'),
  RoomCleanOption('어지르는 편이예요'),
];

class BathroomCleanOption {
  final String label;
  const BathroomCleanOption(this.label);
}

const keyBathroomClean = [
  BathroomCleanOption('둔감해요'),
  BathroomCleanOption('보통이예요'),
  BathroomCleanOption('예민해요'),
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
  bool _isSending = false;

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

  Map<String, dynamic> _buildPayload() {
    return {
      'roomClean': _selectedRoomClean.toList(),
      'bathroomClean': _selectedBathroomCleanOption.toList(),
      'cleaningLevel': _selectedCleaningHabit.toList(),
    };
  }

  void _onNextTap() async {
    if (_isNextEnable()) {
      try {
        setState(() {
          _isSending = true;
        });
        final payload = _buildPayload();
        await FirebaseFirestore.instance
            .collection('cleaningHabit')
            .add(payload);
        print('data stored!');

        if (mounted) {
          Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder: (context) => EtcScreen(),
            ),
          );
        }
      } catch (e) {
        print('error occured!');
      } finally {
        if (mounted) {
          _isSending = false;
        }
      }
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
    );
  }
}
