import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class FormButton extends StatelessWidget {
  const FormButton({super.key, required this.enabled, required this.widget});

  final bool enabled;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: AnimatedContainer(
        padding: EdgeInsets.symmetric(vertical: Sizes.size16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
          child: widget, // 로딩 동그라미 수정할라고 바꿈
        ),
      ),
    );
  }
}
