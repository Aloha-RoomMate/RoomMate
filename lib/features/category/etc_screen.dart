import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

class SmokeOption {
  final String label;
  const SmokeOption(this.label);
}

const keySmoke = [
  SmokeOption('비흡연'),
  SmokeOption('궐련형'),
  SmokeOption('액상 전자담배'),
  SmokeOption('연초'),
];

class InsideSmokeOption {
  final String label;
  const InsideSmokeOption(this.label);
}

const keyInsideSmoke = [
  InsideSmokeOption('절대 안 돼요'),
  InsideSmokeOption('전자담배 가능'),
  InsideSmokeOption('궐련형 가능'),
  InsideSmokeOption('상관 없어요'),
];

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

class EtcScreen extends StatefulWidget {
  const EtcScreen({super.key});

  @override
  State<EtcScreen> createState() => _EtcScreenState();
}

class _EtcScreenState extends State<EtcScreen> {
  final Set<String> _selectedSmoke = {};
  final Set<String> _selectedInsideSmoke = {};
  final Set<String> _selectedPet = {};
  bool _isSending = false;

  void _onSmokeChipTap(String option) {
    if (_selectedSmoke.contains(option)) {
      _selectedSmoke.remove(option);
    } else {
      _selectedSmoke.add(option);
    }
    setState(() {});
  }

  void _onInsideSmokeChipTap(String option) {
    if (_selectedInsideSmoke.contains(option)) {
      _selectedInsideSmoke.remove(option);
    } else {
      _selectedInsideSmoke.add(option);
    }
    setState(() {});
  }

  void _onPetChipTap(String option) {
    if (_selectedPet.contains(option)) {
      _selectedPet.remove(option);
    } else {
      _selectedPet.add(option);
    }
    setState(() {});
  }

  bool _isNextEnable() {
    return _selectedSmoke.isNotEmpty &&
        _selectedInsideSmoke.isNotEmpty &&
        _selectedPet.isNotEmpty;
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'smoking': _selectedSmoke.toList(),
      'insideSmoking': _selectedInsideSmoke.toList(),
      'pet': _selectedPet.toList(),
    };
  }

  void _onNextTap() async {
    if (_isNextEnable()) {
      try {
        setState(() {
          _isSending = true;
        });
        final payload = _buildPayload();
        await FirebaseFirestore.instance.collection('etcLife').add(payload);
        print('data stored!');

        if (mounted) {
          Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder: (context) => DiseaseScreen(),
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
          '기타 생활 습관을 선택해주세요!',
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
                '흡연 여부를 알려주세요',
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
                  for (final smoke in keySmoke)
                    CategoryButton(
                      text: smoke.label,
                      myonTap: () => _onSmokeChipTap(smoke.label),
                      isSelected: _selectedSmoke.contains(smoke.label),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '실내 흡연 허용 정도를 알려주세요',
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
                  for (final smoke in keyInsideSmoke)
                    CategoryButton(
                      text: smoke.label,
                      myonTap: () => _onInsideSmokeChipTap(smoke.label),
                      isSelected: _selectedInsideSmoke.contains(
                        smoke.label,
                      ),
                    ),
                ],
              ),
              Gaps.v12,
              Text(
                '키우는 반려동물을 알려주세요',
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
                  for (final pet in keyPet)
                    CategoryButton(
                      text: pet.label,
                      myonTap: () => _onPetChipTap(pet.label),
                      isSelected: _selectedPet.contains(pet.label),
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
