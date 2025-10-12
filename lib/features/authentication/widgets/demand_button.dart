import 'package:flutter/material.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class DemandButton extends StatelessWidget {
  const DemandButton({
    super.key,
    required this.text,
    required this.myonTap,
    required this.isSelected,
  });

  final String text;
  final Function myonTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => myonTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveSizes.p(context, 6),
          horizontal: ResponsiveSizes.p(context, 18),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, 18)),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.black38,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveSizes.f(context, 12),
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}