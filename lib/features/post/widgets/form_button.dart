import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class FormButton extends StatelessWidget {
  const FormButton({super.key, required this.enabled, required this.text});

  final bool enabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: AnimatedContainer(
        padding: EdgeInsets.symmetric(vertical: Sizes.size16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: enabled
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
        ),
        duration: Duration(milliseconds: 300),
        child: AnimatedDefaultTextStyle(
          duration: Duration(milliseconds: 300),
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey[400],
            fontSize: Sizes.size20,
            fontWeight: FontWeight.w400,
          ),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
