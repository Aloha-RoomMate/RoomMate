import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class ViewButton extends StatelessWidget {
  const ViewButton({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: Sizes.size6,
        horizontal: Sizes.size18,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(
          Sizes.size12,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black,
        ),
      ),
    );
  }
}
