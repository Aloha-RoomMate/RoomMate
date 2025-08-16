import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/introduction_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';
import 'package:roommate/features/category/work_pattern_screen.dart';

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  bool _isHealthy = false;
  TextEditingController _textEditingController = TextEditingController();
  String _diseases = "";

  @override
  void initState() {
    super.initState();

    _textEditingController.addListener(() {
      setState(() {
        _diseases = _textEditingController.text;
      });
    });
  }

  void _onChipTap() {
    setState(() {
      _isHealthy = !_isHealthy;
    });
  }

  void _onScaffoldTap() {
    // 화면 누르면 키보드 내려가게 하기
    FocusScope.of(context).unfocus();
  }

  void _onNextTap() {
    if (_isHealthy || _diseases.isNotEmpty)
      Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder: (context) => IntroductionScreen(),
        ),
      );
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
                Gaps.v6,
                CategoryButton(
                  text: '없음',
                  myonTap: _onChipTap,
                  isSelected: _isHealthy,
                ),
                Gaps.v12,
                TextField(
                  readOnly: _isHealthy,
                  controller: _textEditingController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: "사소한 질병이라도 적어주세요! (예: 무좀, 비염 등)",
                    hintStyle: TextStyle(
                      fontSize: Sizes.size14,
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                Gaps.v12,
                GestureDetector(
                  onTap: _onNextTap,
                  child: FormButton(
                    enabled: _isHealthy == true || _diseases.isNotEmpty,
                    text: '완료',
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
