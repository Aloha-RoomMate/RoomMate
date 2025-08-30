import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/introduction_screen.dart';
import 'package:roommate/features/category/widgets/category_button.dart';
import 'package:roommate/features/category/widgets/form_button.dart';

class DiseaseScreen extends StatefulWidget {
  const DiseaseScreen({super.key});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen> {
  TextEditingController _textEditingController = TextEditingController();
  bool _isHealthy = false;
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

  Map<String, dynamic> _buildPayload() {
    if (_isHealthy) {
      return {
        'isHealthy': true,
      };
    } else {
      return {
        'diseases': _diseases,
      };
    }
  }

  void _onNextTap() async {
    if (_isHealthy || _diseases.isNotEmpty) {
      try {
        final payload = _buildPayload();
        await FirebaseFirestore.instance.collection('disease').add(payload);
        print('data stored!');

        if (mounted) {
          Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder: (context) => IntroductionScreen(),
            ),
          );
        }
      } catch (e) {
        print('error occured!');
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
                  myonTap: _onHealthyChipTap,
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
                    text: '다음',
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
