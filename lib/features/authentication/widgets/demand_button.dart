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
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(Sizes.size12),
          border: Border.all(color: Colors.black.withAlpha(5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(100),
              blurRadius: 5,
              spreadRadius: 0.5,
              offset: Offset(5, 1),
            ),
          ],
        ),
        child: Text(
          widget.text,
          style: TextStyle(color: _isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
