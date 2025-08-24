import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';

class TimeField extends StatelessWidget {
  TimeField({
    super.key,
    required this.question,
    required this.onTimeFieldTap,
    required this.controller,
    required this.isJobLess,
  });

  final String question;
  final Function onTimeFieldTap;
  final TextEditingController controller;
  bool isJobLess;

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
        Gaps.v6,
        IgnorePointer(
          ignoring: isJobLess,
          child: TextField(
            readOnly: true,
            onTap: () => onTimeFieldTap,
            controller: controller,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
              suffixIcon: FaIcon(
                FontAwesomeIcons.clock,
                size: Sizes.size20,
                color: isJobLess ? Colors.grey.shade200 : Colors.grey.shade600,
              ),
            ),
            cursorColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
