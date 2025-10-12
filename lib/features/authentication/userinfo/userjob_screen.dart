import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/authentication/userinfo/hobby_screen.dart';
import 'package:roommate/features/authentication/userinfo/searcher_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/authentication/widgets/demand_button.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class JobOption {
  final String label;
  const JobOption(this.label);
}

const jobOptions = [
  JobOption('회사'),
  JobOption('재택'),
  JobOption('프리랜서'),
  JobOption('대학생'),
];

class GenderOption {
  final String label;
  const GenderOption(this.label);
}

const genderOptions = [
  GenderOption('남성'),
  GenderOption('여성'),
];

class UserTypeOption {
  final String label;
  const UserTypeOption(this.label);
}

const userTypeOptions = [
  UserTypeOption('Room-owner'),
  UserTypeOption('Searcher'),
];

class UserjobScreen extends StatefulWidget {
  const UserjobScreen({super.key});

  @override
  State<UserjobScreen> createState() => _UserjobScreenState();
}

class _UserjobScreenState extends State<UserjobScreen> {
  final Set<String> _selectedJobs = {};
  String? _selectedGender;
  String? _selectedUserType;
  final UserRepository _userRepository = UserRepository();
  bool _isSending = false;

  void _onJobTap(String job) {
    setState(() {
      if (_selectedJobs.contains(job)) {
        _selectedJobs.remove(job);
      } else {
        _selectedJobs.add(job);
      }
    });
  }

  void _onGenderTap(String gender) {
    setState(() {
      _selectedGender = gender;
    });
  }

  void _onUserTypeTap(String userType) {
    setState(() {
      _selectedUserType = userType;
    });
  }

  bool _isNextEnabled() {
    return _selectedJobs.isNotEmpty &&
        _selectedGender != null &&
        _selectedUserType != null;
  }

  Future<void> _onNextTap() async {
    if (!_isNextEnabled() || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      await _userRepository.updateProfile(
        gender: _selectedGender,
      );

      await _userRepository.setUserTypeData(
        uid: user.uid,
        type: _selectedUserType!,
        jobKinds: _selectedJobs.join(', '),
        address: '', // Address is not collected in this screen
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장 성공'),
          ),
        );
        if (_selectedUserType == 'Room-owner') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HobbyScreen(),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SearcherScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('데이터 저장 중 에러 발생'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSizes.p(context, 20),
              vertical: ResponsiveSizes.p(context, 10),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 하시고 계신 일에\n대해 알려주세요 !',
                    style: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 28),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gaps.v6(context),
                  Text(
                    "나중에 더 찰떡궁합 룸메이트를 찾는데 사용되어요.",
                    style: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 14),
                      color: Colors.black87,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Gaps.v16(context),
                  const Divider(height: 1, color: Colors.black12),
                  Gaps.v16(context),
                  Center(
                    child: Wrap(
                      spacing: ResponsiveSizes.p(context, 10),
                      runSpacing: ResponsiveSizes.p(context, 10),
                      children: jobOptions.map((job) {
                        return CategoryButton(
                          text: job.label,
                          myonTap: () => _onJobTap(job.label),
                          isSelected: _selectedJobs.contains(job.label),
                        );
                      }).toList(),
                    ),
                  ),
                  Gaps.v80(context),
                  Text(
                    '성별을 선택해주세요!',
                    style: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 28),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gaps.v16(context),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSizes.p(context, 12),
                    ),
                    child: Wrap(
                      spacing: ResponsiveSizes.p(context, 10),
                      runSpacing: ResponsiveSizes.p(context, 10),
                      children: genderOptions.map((gender) {
                        return CategoryButton(
                          text: gender.label,
                          myonTap: () => _onGenderTap(gender.label),
                          isSelected: _selectedGender == gender.label,
                        );
                      }).toList(),
                    ),
                  ),
                  Gaps.v80(context),
                  Text(
                    '현재 RoomMate를 \n이용하는 이유는 무엇인가요 ?',
                    style: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 28),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gaps.v6(context),
                  Text(
                    "나중에도 변경가능해요!",
                    style: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 14),
                      color: Colors.black87,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Gaps.v16(context),
                  const Divider(height: 1, color: Colors.black12),
                  Gaps.v16(context),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: userTypeOptions.map((userType) {
                      return DemandButton(
                        text: userType.label,
                        myonTap: () => _onUserTypeTap(userType.label),
                        isSelected: _selectedUserType == userType.label,
                      );
                    }).toList(),
                  ),
                  Gaps.v28(context),
                  GestureDetector(
                    onTap: _onNextTap,
                    child: FormButton(
                      enabled: _isNextEnabled(),
                      widget: _isSending
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              '다음',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
