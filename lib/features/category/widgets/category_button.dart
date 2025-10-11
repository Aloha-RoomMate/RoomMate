import 'package:flutter/material.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class CategoryButton extends StatelessWidget {
  CategoryButton({
    super.key,
    required this.text,
    required this.myonTap, // 여기에 _screen.dart 파일의 _onChipTap이 콜백으로 등록
    required this.isSelected,
  });

  final String text;
  final Function myonTap;
  bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => myonTap(),
      child: AnimatedContainer(
        duration: Duration(
          milliseconds: 300,
        ),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveSizes.p(context, 4),
          horizontal: ResponsiveSizes.p(context, 14),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.black38,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveSizes.p(context, 18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
