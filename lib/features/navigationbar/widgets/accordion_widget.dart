import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';

class AccordionWidget extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;

  const AccordionWidget({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  State<AccordionWidget> createState() => _AccordionWidgetState();
}

class _AccordionWidgetState extends State<AccordionWidget>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          child: Row(
            children: [
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(Icons.expand_more_rounded),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: Sizes.size18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Sizes.size4),
        ClipRect(
          child: SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: widget.content,
          ),
        ),
        SizedBox(
          height: Sizes.size4,
        ),
        Divider(
          height: 0,
          color: Theme.of(context).primaryColor.withAlpha(100),
        ),
      ],
    );
  }
}
