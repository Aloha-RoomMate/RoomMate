import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class CategoryButton extends StatefulWidget {
  CategoryButton({
    super.key,
    required this.text,
    required this.myonTap,
  });

  final String text;
  final Function myonTap;

  @override
  State<CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton> {
  bool _isSelected = false;

  void _onChipTap() {
    _isSelected = !_isSelected;
    widget.myonTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onChipTap(),
      child: AnimatedContainer(
        duration: Duration(
          milliseconds: 300,
        ),
        padding: EdgeInsets.symmetric(
          vertical: Sizes.size6,
          horizontal: Sizes.size18,
        ),
        decoration: BoxDecoration(
          color: _isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(
            Sizes.size12,
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: _isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
