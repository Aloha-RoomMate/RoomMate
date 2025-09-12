import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/widgets/chip_button.dart';

// 데이터 모델
class HobbyWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final int previewCount;

  const HobbyWidget({
    required this.icon,
    required this.title,
    required this.items,
    this.previewCount = 10, // 기본값 10개
  });
}

// 실제 위젯
class HobbyWidgetStateful extends StatefulWidget {
  final HobbyWidget section;

  const HobbyWidgetStateful({super.key, required this.section});

  @override
  State<HobbyWidgetStateful> createState() => _HobbyWidgetState();
}

class _HobbyWidgetState extends State<HobbyWidgetStateful> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final previewItems = widget.section.items.take(widget.section.previewCount);
    final remainingItems = widget.section.items.skip(
      widget.section.previewCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.section.icon, size: Sizes.size40),
            const SizedBox(width: 8),
            Text(
              widget.section.title,
              style: const TextStyle(
                fontSize: Sizes.size16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final item in previewItems)
              ChipButton(text: item, isSelected: false),
          ],
        ),
        SizedBox(
          height: Sizes.size10,
        ),
        if (_expanded)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final item in remainingItems)
                ChipButton(text: item, isSelected: false),
            ],
          ),

        Row(
          children: [
            const Expanded(
              child: Divider(color: Colors.black26, thickness: 1, endIndent: 8),
            ),
            TextButton.icon(
              // _expanded에 따라 상태 달라지게 음음
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                color: Colors.black,
                size: Sizes.size20,
              ),
              label: Text(
                _expanded ? "접기" : "더보기",
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const Expanded(
              child: Divider(color: Colors.black26, thickness: 1, indent: 8),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
