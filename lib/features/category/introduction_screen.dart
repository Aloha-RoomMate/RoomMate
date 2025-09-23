import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/userinfo/hobby_screen.dart';
import 'package:roommate/features/category/complete_screen.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final TextEditingController _controller = TextEditingController();
  static const _limit = 300;
  String _introduction = "";
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      setState(() {
        _introduction = _controller.text;
      });
    });
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'introduction': _introduction,
    };
  }

  /// 저장위치가 uid 아래가 아님 문제읻아
  Future<void> _onNextTap() async {
    if (_introduction.length < 50 || _introduction.length > 300) return;

    try {
      setState(() => _isSending = true);

      await UserRepository().setUserPass(
        introduction: Introduction(introduction: _introduction),
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CompleteScreen()),
      );
    } catch (e) {
      debugPrint('error: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _onScaffoldTap() {
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '간단한 소개글을 작성해주세요!',
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
                  '카테고리에서 선택하지 못한 특이사항 혹은 취미나 관심 진로에 대해 적어주시면 더 좋은 룸메이트를 찾는데 도움이 돼요!',
                ),
                Gaps.v6,
                Text(
                  '최소 50자 최대 300자예요!',

                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                Gaps.v12,
                TextField(
                  minLines: null,
                  maxLines: null,
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline, // 엔터 시 다음 줄
                  decoration: InputDecoration(
                    counterText:
                        '${(_controller.text.characters.length)} / $_limit',
                  ),
                ),
                Gaps.v20,
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled:
                        _introduction.length >= 50 &&
                        _introduction.length <= 300,
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
      ),
    );
  }
}
