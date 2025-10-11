import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/features/category/introduction_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  TextEditingController _textEditingController = TextEditingController();
  bool _isHealthy = false;
  String _diseases = "";
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      setState(() {
        _diseases = _textEditingController.text;
      });
    });
  }

  void _onScaffoldTap() {
    FocusScope.of(context).unfocus();
  }

  void _onHealthyChipTap() {
    _isHealthy = !_isHealthy;
    if (_isHealthy) {
      _textEditingController.clear();
    }
    setState(() {});
  }

  void _onNextTap() async {
    if (_isHealthy || _diseases.isNotEmpty) {
      try {
        setState(() {
          _isSending = true;
        });
        final disease = DiseaseInfo(
          isHealthy: _isHealthy,
          diseases: _isHealthy ? '' : _textEditingController.text,
        );

        await UserRepository().setDisease(disease);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 성공'),
            ),
          );
          setState(() {
            _isSending = false;
          });
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => IntroductionScreen(),
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
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '질병 여부를 알려주세요!',
            style: TextStyle(
              fontSize: ResponsiveSizes.f(context, 24),
            ),
          ),
          centerTitle: true,
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
                Gaps.v6(context),
                CategoryButton(
                  text: '없음',
                  myonTap: _onHealthyChipTap,
                  isSelected: _isHealthy,
                ),
                Gaps.v12(context),
                TextField(
                  readOnly: _isHealthy,
                  controller: _textEditingController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: "사소한 질병이라도 적어주세요! (예: 무좀, 비염 등)",
                    hintStyle: TextStyle(
                      fontSize: ResponsiveSizes.f(context, 14),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                Gaps.v12(context),
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled: _isHealthy == true || _diseases.isNotEmpty,
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
