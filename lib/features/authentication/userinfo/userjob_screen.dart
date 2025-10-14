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
  final int index;
  const UserTypeOption(this.label, this.index);
}

const userTypeOptions = [
  UserTypeOption('Room-owner', 0),
  UserTypeOption('Searcher', 1),
];

class UserjobScreen extends StatefulWidget {
  const UserjobScreen({super.key});

  @override
  State<UserjobScreen> createState() => _UserjobScreenState();
}

class _UserjobScreenState extends State<UserjobScreen> {
  final Set<String> _selectedJobs = {};
  String? _selectedGender;
  int? _selectedIndex;
  final UserRepository _userRepository = UserRepository();
  bool _isSending = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

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

  void _onUserTypeTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _isNextEnabled() {
    return _selectedJobs.isNotEmpty &&
        _selectedGender != null &&
        _selectedIndex != null;
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

      final userType = _selectedIndex == 0 ? 'roomOwner' : 'searcher';

      await _userRepository.setUserTypeData(
        uid: user.uid,
        type: userType,
        jobKinds: _selectedJobs.join(', '),
        address: '', // Address is not collected in this screen
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장 성공'),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HobbyScreen(),
          ),
        );
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
                    '성별을 선택해주세요 !',
                    style: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 28),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gaps.v6(context),
                  Text(
                    "동성의 룸메이트만 찾으실수 있습니다.",
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
                      spacing: ResponsiveSizes.p(context, 40),
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
                    'RoomMate를 이용하려는\n이유는 무엇인가요 ?',
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
                    children: [
                      DemandButton(
                        text: userTypeOptions[0].label,
                        myonTap: () => _onUserTypeTap(userTypeOptions[0].index),
                        isSelected: _selectedIndex == userTypeOptions[0].index,
                      ),
                      Gaps.h56(context),
                      DemandButton(
                        text: userTypeOptions[1].label,
                        myonTap: () => _onUserTypeTap(userTypeOptions[1].index),
                        isSelected: _selectedIndex == userTypeOptions[1].index,
                      ),
                    ],
                  ),
                  Gaps.v24(context),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offsetTween = Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      );
                      return SlideTransition(
                        position: offsetTween.animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _user != null
                        ? _buildDescriptionCard(
                            context,
                            _selectedIndex,
                            _user!,
                          )
                        : const SizedBox(),
                  ),
                  Gaps.v28(context),
                  GestureDetector(
                    onTap: _onNextTap,
                    child: FormButton(
                      enabled: _isNextEnabled(),
                      widget: _isSending
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
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

  Widget _buildDescriptionCard(BuildContext context, int? index, User data) {
    if (index == null) {
      return SizedBox(
        height: ResponsiveSizes.height(context, (96 + 56 + 1) / 800),
      );
    }

    final bool isOwner = index == 0;
    final String title = isOwner ? "Room-owner" : "Co-searcher";

    final String ownerDesc =
        "${data.displayName ?? ''}님이 현재 방을 가지고 있고,\n"
        "월세를 같이 부담할 룸메이트를 찾고계시다면 \nRoom-owner입니다 !\n";
    final String searcherDesc =
        "${data.displayName ?? ''}님이 현재 방을 가지고 있지 않지만,\n"
        "월세를 같이 부담하며 누군가의 \n룸메이트가 되려한다면 Searcher입니다.\n";

    final String desc = isOwner ? ownerDesc : searcherDesc;

    return Container(
      key: ValueKey(title),
      padding: EdgeInsets.all(ResponsiveSizes.p(context, 16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, 18)),
        color: Colors.transparent,
        border: Border.all(color: Colors.black.withAlpha(15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveSizes.p(context, 44),
            height: ResponsiveSizes.p(context, 44),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withAlpha(15)),
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(
                ResponsiveSizes.p(context, 10),
              ),
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white),
          ),
          Gaps.h12(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gaps.v6(context),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: ResponsiveSizes.f(context, 12),
                    height: 1.6,
                    color: Colors.black.withAlpha(170),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
