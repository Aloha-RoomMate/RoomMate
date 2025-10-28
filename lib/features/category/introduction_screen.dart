// lib/features/category/introduction_screen.dart
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/category/complete_screen.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key, this.returnAfterSave = false});
  final bool returnAfterSave;

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
    _prefill();
  }

  Future<void> _prefill() async {
    final me = await UserRepository().fetchMe();
    final intro = me?.introduction;
    if (intro != null && intro.trim().isNotEmpty) {
      _controller.text = intro;
      if (mounted) setState(() {});
    }
  }

  Future<void> _save() async {
    final introduction = Introduction(introduction: _controller.text);
    await UserRepository().setIntroduction(introduction);
  }

  void _onNextTap() async {
    final len = _introduction.length;
    if (len < 50 || len > 300) return;

    try {
      setState(() => _isSending = true);
      await _save();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 성공')),
      );

      if (widget.returnAfterSave) {
        // ✅ 마이페이지에서 "수정" 모드로 들어온 경우: 저장 후 마이페이지로 복귀(pop(true))
        Navigator.of(context).pop(true);
      } else {
        // ✅ 온보딩 플로우: Complete 화면으로 교체(pushReplacement)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CompleteScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터 저장 중 에러 발생')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _onScaffoldTap() => FocusScope.of(context).unfocus();

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
            style: TextStyle(fontSize: ResponsiveSizes.f(context, 20)),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.only(
            left: ResponsiveSizes.p(context, 24),
            right: ResponsiveSizes.p(context, 24),
            bottom: ResponsiveSizes.p(context, 24),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '카테고리에서 선택하지 못한 특이사항 혹은 취미나 관심 진로에 대해 적어주시면 더 좋은 룸메이트를 찾는데 도움이 돼요!',
                ),
                Gaps.v6(context),
                Text(
                  '최소 50자 최대 300자예요!',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Gaps.v12(context),
                TextField(
                  minLines: null,
                  maxLines: null,
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    counterText:
                        '${(_controller.text.characters.length)} / $_limit',
                  ),
                ),
                Gaps.v20(context),
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled:
                        _introduction.length >= 50 &&
                        _introduction.length <= 300 &&
                        !_isSending,
                    widget: _isSending
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.returnAfterSave ? '저장' : '다음',
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
