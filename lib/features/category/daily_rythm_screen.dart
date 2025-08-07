import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/category_button.dart';

class DailyRythmScreen extends StatefulWidget {
  const DailyRythmScreen({super.key});

  @override
  State<DailyRythmScreen> createState() => _DailyRythmScreenState();
}

class _DailyRythmScreenState extends State<DailyRythmScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '하루 리듬을 선택해주세요!',
          style: TextStyle(
            fontSize: Sizes.size24,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.size40,
          horizontal: Sizes.size24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '출근일을 알려주세요!',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v10,
              Wrap(
                spacing: Sizes.size10,
                runSpacing: Sizes.size10,
                children: [
                  CategoryButton(text: '월'),
                  CategoryButton(text: '화'),
                  CategoryButton(text: '수'),
                  CategoryButton(text: '목'),
                  CategoryButton(text: '금'),
                  CategoryButton(text: '토'),
                  CategoryButton(text: '일'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
