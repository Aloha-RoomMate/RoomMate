import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/sound_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

class CookOption {
  final String label;
  const CookOption(this.label);
}

const keyCook = [
  CookOption('자주'),
  CookOption('보통'),
  CookOption('거의 안 해요'),
];

class SmellOption {
  final String label;
  const SmellOption(this.label);
}

const keySmell = [
  SmellOption('둔감해요'),
  SmellOption('보통이예요'),
  SmellOption('예민한 편이예요'),
];

class DishOption {
  final String label;
  const DishOption(this.label);
}

const keyDishes = [DishOption('공용 식기'), DishOption('개인 식기')];

class DeliveryOption {
  final String label;
  const DeliveryOption(this.label);
}

class DiningHabitScreen extends StatefulWidget {
  const DiningHabitScreen({super.key});

  @override
  State<DiningHabitScreen> createState() => _DiningHabitScreenState();
}

class _DiningHabitScreenState extends State<DiningHabitScreen> {
  final Set<String> _selectedCook = {};
  final Set<String> _selectedSmell = {};
  final Set<String> _selectedDishes = {};
  final Set<String> _selectedDelivery = {};
  bool _isSending = false;

  void _onCookChipTap(String option) {
    if (_selectedCook.contains(option)) {
      _selectedCook.remove(option);
    } else if (_selectedCook.isNotEmpty) {
      _selectedCook.clear();
    }
    _selectedCook.add(option);
    setState(() {});
  }

  void _onSmellChipTap(String option) {
    if (_selectedSmell.contains(option)) {
      _selectedSmell.remove(option);
    } else {
      _selectedSmell.add(option);
    }
    setState(() {});
  }

  void _onDishesChipTap(String option) {
    if (_selectedDishes.contains(option)) {
      _selectedDishes.remove(option);
    } else {
      _selectedDishes.add(option);
    }
    setState(() {});
  }

  bool _isNextEnable() {
    return _selectedCook.isNotEmpty &&
        _selectedSmell.isNotEmpty &&
        _selectedDelivery.isNotEmpty &&
        _selectedDishes.isNotEmpty;
  }

  void _onNextTap() async {
    if (_isNextEnable()) {
      try {
        setState(() {
          _isSending = true;
        });
        final payload = _buildPayload();
        await FirebaseFirestore.instance
            .collection('diningPattern')
            .add(payload);
        print('data stored!');

        if (mounted) {
          Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder: (context) => SoundScreen(),
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
      'weeklyCooking': _selectedCook.toList(),
      'smellSense': _selectedSmell.toList(),
      'dishShare': _selectedDishes.toList(),
      'delivery': _selectedDelivery.toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '식사 습관을 선택해주세요!',
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
                '주 요리 빈도를 선택하세요',
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
                  for (final cook in keyCook)
                    CategoryButton(
                      text: cook.label,
                      myonTap: () => _onCookChipTap(cook.label),
                      isSelected: _selectedCook.contains(cook.label),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '냄새 민감도를 알려주세요!',
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
                  for (final smell in keySmell)
                    CategoryButton(
                      text: smell.label,
                      myonTap: () => _onSmellChipTap(smell.label),
                      isSelected: _selectedSmell.contains(smell.label),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '식기 선호도를 알려주세요',
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
                  for (final dish in keyDishes)
                    CategoryButton(
                      text: dish.label,
                      myonTap: () => _onDishesChipTap(dish.label),
                      isSelected: _selectedDishes.contains(dish.label),
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
