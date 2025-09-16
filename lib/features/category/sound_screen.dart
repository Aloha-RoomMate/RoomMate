import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/cleaning_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

class SleepSoundOption {
  final String label;
  const SleepSoundOption(this.label);
}

const keySleepSound = [
  SleepSoundOption('둔감해요'),
  SleepSoundOption('보통이예요'),
  SleepSoundOption('예민한 편이예요'),
];

class SleepHabit {
  final String label;
  const SleepHabit(this.label);
}

const keySleepHabit = [
  SleepHabit('잠버릇이 없어요'),
  SleepHabit('자주 코를 골아요'),
  SleepHabit('피곤하면 코를 골아요'),
  SleepHabit('자주 이를 갈아요'),
  SleepHabit('피곤하면 이를 골아요'),
];

class SoundModeOption {
  final String label;
  const SoundModeOption(this.label);
}

const keySoundMode = [
  SoundModeOption('항상 소리'),
  SoundModeOption('항상 진동'),
  SoundModeOption('항상 무음'),
  SoundModeOption('잘 때 진동'),
  SoundModeOption('잘 때 무음'),
];

class EarPhoneOption {
  final String label;
  const EarPhoneOption(this.label);
}

const keyEarPhone = [
  EarPhoneOption('항상'),
  EarPhoneOption('밤에만'),
  EarPhoneOption('신경 안 써요'),
];

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  final Set<String> _selectedSleepSound = {};
  final Set<String> _selectedSleepHabit = {};
  final Set<String> _selectedSoundMode = {};
  final Set<String> _selectedEarPhone = {};
  bool _isSending = false;

  void _onSleepSoundChipTap(String option) {
    if (_selectedSleepSound.contains(option)) {
      _selectedSleepSound.remove(option);
    } else {
      _selectedSleepSound.add(option);
    }
    setState(() {});
  }

  void _onSleepHabitChipTap(String option) {
    if (_selectedSleepHabit.contains(option)) {
      _selectedSleepHabit.remove(option);
    } else {
      _selectedSleepHabit.add(option);
    }
    setState(() {});
  }

  void _onSoundModeChipTap(String option) {
    if (_selectedSoundMode.contains(option)) {
      _selectedSoundMode.remove(option);
    } else {
      _selectedSoundMode.add(option);
    }
    setState(() {});
  }

  void _onEarPhoneChipTap(String option) {
    if (_selectedEarPhone.contains(option)) {
      _selectedEarPhone.remove(option);
    } else {
      _selectedEarPhone.add(option);
    }
    setState(() {});
  }

  bool _isNextEnable() {
    return _selectedSleepSound.isNotEmpty &&
        _selectedSleepHabit.isNotEmpty &&
        _selectedEarPhone.isNotEmpty &&
        _selectedSoundMode.isNotEmpty;
  }

  void _onNextTap() async {
    if (_isNextEnable()) {
      try {
        setState(() {
          _isSending = true;
        });
        final payload = _buildPayload();
        await FirebaseFirestore.instance
            .collection('soundSensitivity')
            .add(payload);
        print('data stored!');

        if (mounted) {
          Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder: (context) => CleaningScreen(),
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

  Map<String, dynamic> _buildPayload() {
    return {
      'sleepSound': _selectedSleepSound.toList(),
      'sleepHabit': _selectedSleepHabit.toList(),
      'soundMode': _selectedSoundMode.toList(),
      'earPhone': _selectedEarPhone.toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '소리 민감도를 선택해주세요!',
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
                '잠귀 민감도를 알려주세요',
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
                  for (final sound in keySleepSound)
                    CategoryButton(
                      text: sound.label,
                      myonTap: () => _onSleepSoundChipTap(sound.label),
                      isSelected: _selectedSleepSound.contains(sound.label),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '잠버릇을 알려주세요!',
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
                  for (final habit in keySleepHabit)
                    CategoryButton(
                      text: habit.label,
                      myonTap: () => _onSleepHabitChipTap(habit.label),
                      isSelected: _selectedSleepHabit.contains(habit.label),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '선호하는 소리/진동/무음 모드를 알려주세요',
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
                  for (final soundMode in keySoundMode)
                    CategoryButton(
                      text: soundMode.label,
                      myonTap: () => _onSoundModeChipTap(soundMode.label),
                      isSelected: _selectedSoundMode.contains(soundMode.label),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '선호하는 이어폰 사용 형태를 알려주세요',
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
                  for (final earPhone in keyEarPhone)
                    CategoryButton(
                      text: earPhone.label,
                      myonTap: () => _onEarPhoneChipTap(earPhone.label),
                      isSelected: _selectedEarPhone.contains(earPhone.label),
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
