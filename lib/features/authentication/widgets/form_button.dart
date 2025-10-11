import 'package:flutter/material.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class FormButton extends StatelessWidget {
  const FormButton({super.key, required this.disabled, required this.text});

  final bool disabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: AnimatedContainer(
        padding: EdgeInsets.symmetric(vertical: ResponsiveSizes.p(context, 16)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, 18)),
          color: disabled
              ? Colors.grey.shade300
              : Theme.of(context).primaryColor,
        ),
        duration: Duration(milliseconds: 300),
        child: AnimatedDefaultTextStyle(
          duration: Duration(milliseconds: 300),
          style: TextStyle(
            color: disabled ? Colors.grey[400] : Colors.white,
            fontSize: ResponsiveSizes.f(context, 20),
            fontWeight: FontWeight.w400,
          ),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
