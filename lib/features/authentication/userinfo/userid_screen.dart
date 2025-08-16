import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/userjob_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';

class UseridScreen extends StatefulWidget {
  const UseridScreen({super.key});

  @override
  State<UseridScreen> createState() => _UseridScreenState();
}

class _UseridScreenState extends State<UseridScreen> {
  final TextEditingController _usernameController = TextEditingController();

  String _username = "";
  String? _selectedGender;

  @override
  void initState() {
    super.initState();

    _usernameController.addListener(() {
      setState(() {
        _username = _usernameController.text;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _onNextTap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => UserjobScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _onScaffoldTap() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text('회원가입')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.size36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gaps.v40,
              Text(
                '닉네임을 입력해주세요',
                style: TextStyle(
                  fontSize: Sizes.size24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Gaps.v8,
              Text(
                '닉네임을 사용해주세요',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),
              Gaps.h20,
              TextField(
                controller: _usernameController,
                cursorColor: Theme.of(context).primaryColor,
                decoration: InputDecoration(
                  hintText: "닉네임",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
              ),
              Gaps.v16,
              Text(
                "성별을 골라주세요",
                style: TextStyle(
                  fontSize: Sizes.size24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGender = "male";
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedGender == "male"
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                          child: Icon(
                            Icons.male_rounded,
                            color: _selectedGender == "male"
                                ? Colors.white
                                : Colors.black,
                            size: 32,
                          ),
                        ),
                        Gaps.h10,
                        Text(
                          "남성",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 80),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGender = "female";
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedGender == "female"
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),

                          child: Icon(
                            Icons.female_rounded,
                            color: _selectedGender == "female"
                                ? Colors.white
                                : Colors.black,
                            size: 32,
                          ),
                        ),
                        Gaps.h10,
                        Text(
                          "여성",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 60),
              GestureDetector(
                onTap: _onNextTap,
                child: FormButton(
                  disabled: _username.isEmpty || _selectedGender == null,
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
