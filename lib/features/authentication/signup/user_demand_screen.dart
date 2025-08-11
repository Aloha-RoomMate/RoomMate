import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/signup/email_screen.dart';
import 'package:roommate/features/authentication/widgets/demand_button.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';

class UserDemandScreen extends StatefulWidget {
  const UserDemandScreen({super.key});

  @override
  State<UserDemandScreen> createState() => _UserDemandScreenState();
}

class _UserDemandScreenState extends State<UserDemandScreen> {
  Key _leftKey = UniqueKey();
  Key _rightKey = UniqueKey();
  int? _selectedIndex;

  void _onNextTap() {
    if (_selectedIndex != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const EmailScreen()));
    }
  }

  void _onTapLeft() {
    setState(() {
      if (_selectedIndex == 0) {
        _selectedIndex = null;
        _leftKey = UniqueKey();
      } else {
        _selectedIndex = 0;
        _rightKey = UniqueKey();
      }
    });
  }

  void _onTapRight() {
    setState(() {
      if (_selectedIndex == 1) {
        _selectedIndex = null;
        _rightKey = UniqueKey();
      } else {
        _selectedIndex = 1;
        _leftKey = UniqueKey();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isNextEnabled = _selectedIndex != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.size16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("포지션선택"),
              const SizedBox(height: Sizes.size12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DemandButton(
                    key: _leftKey,
                    text: "Room-owner",
                    myonTap: _onTapLeft,
                  ),
                  const SizedBox(width: Sizes.size56),
                  DemandButton(
                    key: _rightKey,
                    text: "Co-searcher",
                    myonTap: _onTapRight,
                  ),
                ],
              ),
              const SizedBox(height: Sizes.size20),
              GestureDetector(
                onTap: isNextEnabled ? _onNextTap : null,
                child: FormButton(disabled: !isNextEnabled, text: "다음"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
