import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/userjob_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';

class UsernicknameScreen extends StatefulWidget {
  const UsernicknameScreen({super.key});

  @override
  State<UsernicknameScreen> createState() => _UsernicknameScreenState();
}

class _UsernicknameScreenState extends State<UsernicknameScreen> {
  final TextEditingController _usernameController = TextEditingController();

  String _username = "";

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
    if (_username.isEmpty) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UserjobScreen()));
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
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade500),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade500),
                  ),
                ),
              ),
              Gaps.v16,
              GestureDetector(
                onTap: _onNextTap,
                child: FormButton(disabled: _username.isEmpty, text: "Next"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
