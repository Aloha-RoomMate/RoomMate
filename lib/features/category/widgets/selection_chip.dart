import 'package:flutter/material.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/widgets/category_button.dart';

class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.textOptions,
    required this.onChipTap,
    required this.checkList,
    required this.indexOfQuestion,
    required this.question,
  });

  final List<String> textOptions;
  final int indexOfQuestion;
  final Function onChipTap; // 여기에 _screen.dart의 _onChipTap등록
  final List<List<bool>> checkList; // 여기에 _screen.dart의 리스트 등록
  final String question;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: Sizes.size16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gaps.v6(context),
        Wrap(
          spacing: Sizes.size10,
          runSpacing: Sizes.size10,
          children: List.generate(checkList[indexOfQuestion].length, (
            buttonIndex,
          ) {
            return CategoryButton(
              text: textOptions[buttonIndex],
              myonTap: () => onChipTap(indexOfQuestion, buttonIndex),
              isSelected: checkList[indexOfQuestion][buttonIndex],
            );
          }),
        ),
      ],
    );
  }
}
