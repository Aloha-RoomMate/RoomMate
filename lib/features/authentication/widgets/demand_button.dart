import 'package:flutter/material.dart';
import 'package:roommate/constants/responsive_sizes.dart';

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
          vertical: ResponsiveSizes.p(context, 6),
          horizontal: ResponsiveSizes.p(context, 18),
        ),
        decoration: BoxDecoration(
          color: _isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, 18)),
          border: Border.all(
            color: _isSelected ? Colors.transparent : Colors.black38,
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: ResponsiveSizes.f(context, 12),
            color: _isSelected ? Colors.white : Colors.black,
            fontWeight: _isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
