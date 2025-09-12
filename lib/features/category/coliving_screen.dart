import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/dining_habit_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 공용 공간 사용
class CoSpaceOption {
  final String label;
  const CoSpaceOption(this.label);
}

const keyDrink = [
  CoSpaceOption('활발'),
  CoSpaceOption('중간'),
  CoSpaceOption('거의 사용 안 함'),
];

/// 교류 선호도
class InteractionOption {
  final String label;
  const InteractionOption(this.label);
}

const keyInteractioin = [
  InteractionOption('친하게'),
  InteractionOption('적당히 거리두며'),
  InteractionOption('거의 없이'),
];

/// 정리정돈 성향
class CleanOption {
  final String label;
  const CleanOption(this.label);
}

const keyCleanOption = [
  CleanOption('항상 제자리에 둬요'),
  CleanOption('대체로 정돈된 편이예요'),
  CleanOption('어지르는 편이예요'),
];

/// 화장실 청결 민감도
class BathroomCleanOption {
  final String label;
  const BathroomCleanOption(this.label);
}

const keyBathroomClean = [
  BathroomCleanOption('둔감해요'),
  BathroomCleanOption('보통이에요'),
  BathroomCleanOption('예민해요'),
];

/// 반려동물 여부
class Pet {
  final String label;
  const Pet(this.label);
}

const keyPet = [
  Pet('없음'),
  Pet('강아지'),
  Pet('고양이'),
  Pet('물고기'),
  Pet('양서류'),
  Pet('파충류'),
  Pet('무척추동물(기타)'),
  Pet('조류'),
];

/// Mbti
class Mbti {
  final String label;
  const Mbti(this.label);
}

const keyMbti = [
  Mbti('모름'),
  Mbti('ENFJ'),
  Mbti('ENFP'),
  Mbti('ENTJ'),
  Mbti('ENTP'),
  Mbti('ESFJ'),
  Mbti('ESFP'),
  Mbti('ESTJ'),
  Mbti('ESTP'),
  Mbti('INFJ'),
  Mbti('INFP'),
  Mbti('INTJ'),
  Mbti('INTP'),
  Mbti('ISFJ'),
  Mbti('ISFP'),
  Mbti('ISTJ'),
  Mbti('ISTP'),
];

class ColivingScreen extends StatefulWidget {
  const ColivingScreen({super.key});

  @override
  State<ColivingScreen> createState() => _WorkPatternScreenState();
}

class _WorkPatternScreenState extends State<ColivingScreen> {
  final Set<String> _selectedDrinks = {};
  bool _isSmoking = false;
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
          '공용 공간 사용 선호도를 알려주세요!',
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
