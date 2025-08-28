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
  CookOption('전혀 안 해요'),
  CookOption('1-2회'),
  CookOption('2-3회'),
  CookOption('3-4회'),
  CookOption('4-5회'),
  CookOption('5회 이상'),
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

const keyDishes = [DishOption('같이 써요'), DishOption('개인 식기를 선호해요')];

class DeliveryOption {
  final String label;
  const DeliveryOption(this.label);
}

const keyDelivery = [
  DeliveryOption('전혀 안 시켜요'),
  DeliveryOption('1-2회'),
  DeliveryOption('2-3회'),
  DeliveryOption('3-4회'),
  DeliveryOption('4-5회'),
  DeliveryOption('5회 이상'),
];

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

  void _onCookChipTap(String option) {
    if (_selectedCook.contains(option)) {
      _selectedCook.remove(option);
    } else {
      _selectedCook.add(option);
    }
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

  void _onDeliveryChipTap(String option) {
    if (_selectedDelivery.contains(option)) {
      _selectedDelivery.remove(option);
    } else {
      _selectedDelivery.add(option);
    }
    setState(() {});
  }

  bool _isNextEnable() {
    return _selectedCook.isNotEmpty &&
        _selectedSmell.isNotEmpty &&
        _selectedDelivery.isNotEmpty &&
        _selectedDishes.isNotEmpty;
  }

  void _onNextTap() {
    if (_isNextEnable()) {
      Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder: (context) => SoundScreen(),
        ),
      );
    }
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
                '냄새 빈도를 알려주세요!',
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
                '공용 식기 선호도를 알려주세요',
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
              Text(
                '주 배달 횟수를 선택하세요',
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
                  for (final delivery in keyDelivery)
                    CategoryButton(
                      text: delivery.label,
                      myonTap: () => _onDeliveryChipTap(delivery.label),
                      isSelected: _selectedDelivery.contains(delivery.label),
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
