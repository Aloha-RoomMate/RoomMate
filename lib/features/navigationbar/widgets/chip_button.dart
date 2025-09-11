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
        vertical: Sizes.size4,
        horizontal: Sizes.size14,
      ),
      decoration: BoxDecoration(
        border: BoxBorder.all(color: Colors.black38),

        color: isSelected
            ? Theme.of(context).primaryColor
            // : Colors.grey.shade200,
            : Colors.transparent,
        borderRadius: BorderRadius.circular(
          Sizes.size18,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Sizes.size12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
