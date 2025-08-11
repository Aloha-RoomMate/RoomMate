import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';

class LoginEmailScreen extends StatefulWidget {
  const LoginEmailScreen({super.key});

  @override
  State<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Map<String, String> formData = {};

  void _onSubmitTap() {
    if (_formKey.currentState != null) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        // 여기는 로그인 이후에 넘어가는 페이지 이니 나중에 홈화면 생기면 들어갈 자리
        // Navigator.push(
        // context,
        // MaterialPageRoute(builder: (context) => const DailyRythmScreen()),
        // );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("로그인")),
      body: Padding(
        padding: EdgeInsets.only(
          left: Sizes.size24,
          right: Sizes.size24,
          bottom: Sizes.size24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Gaps.v28,
              TextFormField(
                decoration: InputDecoration(hintText: "이메일"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isEmpty) {
                    return "이메일을 입력해주세요";
                  }
                  return null;
                  // return "옳은 형식이 아닙니다.";
                },
                onSaved: (newValue) {
                  if (newValue != null) {
                    formData['이메일'] = newValue;
                  }
                },
              ),
              Gaps.v16,
              TextFormField(
                decoration: InputDecoration(hintText: "비밀번호"),
                obscureText: true,
                validator: (value) {
                  if (value != null && value.isEmpty) {
                    return "비밀번호를 입력해주세요";
                  }
                  return null;
                  // return "비밀번호가 일치하지 않습니다.";
                },
                onSaved: (newValue) {
                  if (newValue != null) {
                    formData['비밀번호'] = newValue;
                  }
                },
              ),
              Gaps.v28,
              GestureDetector(
                onTap: _onSubmitTap,
                child: FormButton(disabled: false, text: "로그인"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
