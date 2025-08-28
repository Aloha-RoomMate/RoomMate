import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.text,
    required this.isSelected,
  });

  final String text;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Sizes.size6,
        horizontal: Sizes.size18,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(
          Sizes.size12,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
