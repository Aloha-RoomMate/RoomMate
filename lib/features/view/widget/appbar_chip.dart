import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class AppbarChip extends StatelessWidget {
  const AppbarChip({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Sizes.size1,
        horizontal: Sizes.size8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
        ),
        borderRadius: BorderRadius.circular(
          Sizes.size12,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
        ),
      ),
    );
  }
}
