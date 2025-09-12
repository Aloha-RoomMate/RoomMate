import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class DemandButton extends StatefulWidget {
  const DemandButton({super.key, required this.text, required this.myonTap});

  final String text;
  final Function myonTap;

  @override
  State<DemandButton> createState() => _DemandButtonState();
}

class _DemandButtonState extends State<DemandButton> {
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
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          vertical: Sizes.size6,
          horizontal: Sizes.size18,
        ),
        decoration: BoxDecoration(
          color: _isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Sizes.size18),
          border: Border.all(
            color: _isSelected ? Colors.transparent : Colors.black38,
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: Sizes.size12,
            color: _isSelected ? Colors.white : Colors.black,
            fontWeight: _isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
