import 'package:flutter/material.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/etc_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

// ✅ 모델 가져올 때 별칭으로
import 'package:roommate/class/app_user.dart' as model;

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

// ⛳️ 이건 UI 라벨용 클래스 (이름 그대로 둬도 됨)
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

  // (안 써도 되지만 남겨두고 싶다면 OK)
  Map<String, dynamic> _buildPayload() {
    return {
      'roomClean': _selectedRoomClean.toList(),
      'bathroomClean': _selectedBathroomCleanOption.toList(),
      'cleaningLevel': _selectedCleaningHabit.toList(),
    };
  }

  Future<void> _onNextTap() async {
    if (!_isNextEnable()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ✅ 여기! 모델 클래스는 model.CleaningHabit 로 명시
      final ch = model.CleaningHabit(
        roomClean: _selectedRoomClean.toList(),
        bathroomClean: _selectedBathroomCleanOption.toList(),
        cleaningLevel: _selectedCleaningHabit.toList(),
      );

      await UserRepository().setCleaningHabit(ch);

      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EtcScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '청소 습관을 선택해주세요!',
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
