import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final FaIcon icon;

  const AuthButton({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: Container(
        padding: EdgeInsets.all(ResponsiveSizes.p(context, 16)),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.transparent,
            width: ResponsiveSizes.p(context, 1),
          ),

          gradient: LinearGradient(
            colors: [
              Colors.yellow,
              Theme.of(context).primaryColor,
              Colors.teal,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, 20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: ResponsiveSizes.p(context, 8),
              offset: Offset(
                ResponsiveSizes.p(context, 2),
                ResponsiveSizes.p(context, 8),
              ),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: icon),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveSizes.f(context, 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
