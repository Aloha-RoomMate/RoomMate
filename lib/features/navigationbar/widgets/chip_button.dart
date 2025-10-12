import 'package:flutter/material.dart';
import 'package:roommate/constants/responsive_sizes.dart';

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
        vertical: ResponsiveSizes.p(context, 4),
        horizontal: ResponsiveSizes.p(context, 14),
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.black38,
        ),
        color: isSelected
            ? Theme.of(context).primaryColor
            // : Colors.grey.shade200,
            : Colors.transparent,
        borderRadius: BorderRadius.circular(
          ResponsiveSizes.p(context, 18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: ResponsiveSizes.f(context, 12),
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
