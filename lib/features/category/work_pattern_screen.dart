import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/dining_habit_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 늦는 횟수
class LateOption {
  final String label;
  const LateOption(this.label);
}

const keyLate = [
  LateOption('0회'),
  LateOption('1-2회'),
  LateOption('2-3회'),
  LateOption('3-4회'),
  LateOption('4-5회'),
  LateOption('5회 이상'),
];

class DrinkOption {
  final String label;
  const DrinkOption(this.label);
}

const keyDrink = [
  DrinkOption('0회'),
  DrinkOption('1-2회'),
  DrinkOption('2-3회'),
  DrinkOption('3-4회'),
  DrinkOption('4-5회'),
  DrinkOption('5회 이상'),
];

class WorkPatternScreen extends StatefulWidget {
  const WorkPatternScreen({super.key});

  @override
  State<WorkPatternScreen> createState() => _WorkPatternScreenState();
}

class _WorkPatternScreenState extends State<WorkPatternScreen> {
  final Set<String> _selectedLates = {};
  final Set<String> _selectedDrinks = {};

  void _onLateOptionTap(String option) {
    if (_selectedLates.contains(option)) {
      _selectedLates.remove(option);
    } else {
      _selectedLates.add(option);
    }
    setState(() {});
  }

  void _onDrinkTap(String option) {
    if (_selectedDrinks.contains(option)) {
      _selectedDrinks.remove(option);
    } else {
      _selectedDrinks.add(option);
    }
    setState(() {});
  }

  bool _isNextEnable() {
    return (_selectedLates.isNotEmpty && _selectedDrinks.isNotEmpty);
  }

  Future<void> _onNextTap() async {
    if (!_isNextEnable()) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final wp = WorkPattern(
        lates: _selectedLates.toList(),
        drinks: _selectedDrinks.toList(),
      );
      await UserRepository().setWorkPattern(wp);

      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const DiningHabitScreen()));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'lates': _selectedLates.toList(),
      'drinks': _selectedDrinks.toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '늦은 귀가에 대해 알려주세요!',
          style: TextStyle(
            fontSize: Sizes.size20 + Sizes.size2,
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
                '늦은 귀가에 빈도에 대해 알려주세요!',
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
                  for (final late in keyLate)
                    CategoryButton(
                      text: late.label,
                      myonTap: () => _onLateOptionTap(late.label),
                      isSelected: _selectedLates.contains(late.label),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '주 음주 횟수를 알려주세요',
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
                  for (final drink in keyDrink)
                    CategoryButton(
                      text: drink.label,
                      myonTap: () => _onDrinkTap(drink.label),
                      isSelected: _selectedDrinks.contains(drink.label),
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
