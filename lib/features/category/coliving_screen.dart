import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

/// 공용 공간 사용
class CoSpaceOption {
  final String label;
  const CoSpaceOption(this.label);
}

const keyCoSpace = [
  CoSpaceOption('활발'),
  CoSpaceOption('중간'),
  CoSpaceOption('거의 사용 안 함'),
];

/// 교류 선호도
class InteractionOption {
  final String label;
  const InteractionOption(this.label);
}

const keyInteraction = [
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
  bool _isSmoking = false;
  bool _isSending = false;

  final Set<String> _selectedCoSpace = {};
  final Set<String> _selectedInteraction = {};
  final Set<String> _selectedCleaning = {};
  final Set<String> _selectedBathroom = {};
  final Set<String> _selectedPet = {};
  final Set<String> _selectedMbti = {};

  /// 선택 함수들 선언
  void _onCoSpaceTap(String option) {
    if (_selectedCoSpace.isNotEmpty) {
      _selectedCoSpace.clear();
    }
    _selectedCoSpace.add(option);
    setState(() {});
  }

  void _onInteractionTap(String option) {
    if (_selectedInteraction.isNotEmpty) {
      _selectedInteraction.clear();
    }
    _selectedInteraction.add(option);
    setState(() {});
  }

  void _onCleaningTap(String option) {
    if (_selectedCleaning.isNotEmpty) {
      _selectedCleaning.clear();
    }
    _selectedCleaning.add(option);
    setState(() {});
  }

  void _onBathroomTap(String option) {
    if (_selectedBathroom.isNotEmpty) {
      _selectedBathroom.clear();
    }
    _selectedBathroom.add(option);
    setState(() {});
  }

  void _onSmokingTap(bool newValue) {
    setState(() {
      _isSmoking = newValue;
    });
  }

  void _onPetTap(String option) {
    if (option == '없음') {
      _selectedPet
        ..clear()
        ..add(option);
    } else {
      _selectedPet
        ..remove('없음')
        ..add(option);
    }
    setState(() {});
  }

  void _onMbtiTap(String option) {
    if (option == '모름') {
      _selectedMbti
        ..clear()
        ..add(option);
    } else {
      _selectedMbti.add('모름');
      if (_selectedMbti.isNotEmpty) {
        _selectedMbti.clear();
      }
      _selectedMbti.add(option);
    }
    setState(() {});
  }

  bool _isNextEnable() {
    return (_selectedCoSpace.isNotEmpty &&
        _selectedInteraction.isNotEmpty &&
        _selectedCleaning.isNotEmpty &&
        _selectedBathroom.isNotEmpty &&
        _selectedPet.isNotEmpty &&
        _selectedMbti.isNotEmpty);
  }

  void _onNextTap() async {
    if (_isNextEnable()) {
      try {
        setState(() {
          _isSending = true;
        });
        final coliving = Coliving(
          coSpace: _selectedCoSpace.first, // 그냥 .toString 하면 "{'활발'}". 껍데기까지.
          interaction: _selectedInteraction.first,
          bathroom: _selectedBathroom.first,
          smoking: _isSmoking,
          pet: _selectedPet.toList(),
          mbti: _selectedMbti.first,
        );

        // 실제 데이터 넘기기
        // USRREPO 선언 바로 할 수 있음.
        await UserRepository().setColiving(coliving);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 성공'),
            ),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DiseaseScreen(),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 저장 중 에러 발생'),
          ),
        );
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
          '공동 생활 성향에 대해 알려주세요!',
          style: TextStyle(
            fontSize: Sizes.size16 + Sizes.size3,
          ),
        ),
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
              Gaps.v24,
              Text(
                '공용 공간 사용 선호도를 알려주세요!',
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
                  for (final option in keyCoSpace)
                    CategoryButton(
                      text: option.label,
                      myonTap: () => _onCoSpaceTap(option.label),
                      isSelected: _selectedCoSpace.contains(option.label),
                    ),
                ],
              ),
              Gaps.v24,
              Text(
                '룸메이트와의 선호 교류 타입을 알려주세요!',
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
                  for (final option in keyInteraction)
                    CategoryButton(
                      text: option.label,
                      myonTap: () => _onInteractionTap(option.label),
                      isSelected: _selectedInteraction.contains(option.label),
                    ),
                ],
              ),
              Gaps.v24,
              Text(
                '정리정돈 성향을 알려주세요!',
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
                  for (final option in keyCleanOption)
                    CategoryButton(
                      text: option.label,
                      myonTap: () => _onCleaningTap(option.label),
                      isSelected: _selectedCleaning.contains(option.label),
                    ),
                ],
              ),
              Gaps.v24,
              Text(
                '화장실 청결 민감도를 알려주세요!',
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
                  for (final option in keyBathroomClean)
                    CategoryButton(
                      text: option.label,
                      myonTap: () => _onBathroomTap(option.label),
                      isSelected: _selectedBathroom.contains(option.label),
                    ),
                ],
              ),
              Gaps.v24,
              Row(
                children: [
                  Text(
                    '흡연 여부를 알려주세요!',
                    style: TextStyle(
                      fontSize: Sizes.size16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gaps.h10,
                  CupertinoSwitch(
                    value: _isSmoking,
                    onChanged: _onSmokingTap,
                  ),
                  // Dart가 알아서 바뀐 newValue 넘겨줌.
                ],
              ),
              Gaps.v24,
              Text(
                '반려동물 여부를 알려주세요!',
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
                  for (final option in keyPet)
                    CategoryButton(
                      text: option.label,
                      myonTap: () => _onPetTap(option.label),
                      isSelected: _selectedPet.contains(option.label),
                    ),
                ],
              ),
              Gaps.v24,
              Text(
                'MBTI를 알려주세요!',
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
                  for (final option in keyMbti)
                    CategoryButton(
                      text: option.label,
                      myonTap: () => _onMbtiTap(option.label),
                      isSelected: _selectedMbti.contains(option.label),
                    ),
                ],
              ),
              Gaps.v24,
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
