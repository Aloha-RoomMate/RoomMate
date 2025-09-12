import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/dining_habit_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final Set<String> _selectedDrinks = {};
  bool _isSending = false;

  void _onDrinkTap(String option) {
    if (_selectedDrinks.contains(option)) {
      _selectedDrinks.remove(option);
    } else if (_selectedDrinks.isNotEmpty) {
      _selectedDrinks.clear();
    }
    _selectedDrinks.add(option);
    setState(() {});
  }

  bool _isNextEnable() {
    return (_selectedDrinks.isNotEmpty);
  }

  void _onNextTap() async {
    if (_isNextEnable()) {
      try {
        setState(() {
          _isSending = true;
        });
        final payload = _buildPayload();
        await FirebaseFirestore.instance.collection('latePattern').add(payload);
        print('>> 데이터 저장 성공');

        if (mounted) {
          Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder: (context) => DiningHabitScreen(),
            ),
          );
        }
      } catch (e) {
        print('데이터 저장 중 에러 발생');
      } finally {
        if (mounted) {
          _isSending = false;
        }
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
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
