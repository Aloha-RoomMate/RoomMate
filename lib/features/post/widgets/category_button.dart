import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

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
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          vertical: Sizes.size6,
          horizontal: Sizes.size18,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(Sizes.size12),
        ),
        child: Text(
          text,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
