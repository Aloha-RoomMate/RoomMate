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
  final Function(List<String>)? onSelectionChanged;

  /// ✅ 추가: 프리필(초기 선택 값)
  final List<String>? initialSelected;

  const HobbyWidgetStateful({
    super.key,
    required this.section,
    this.onSelectionChanged,
    this.initialSelected,
  });

  @override
  State<HobbyWidgetStateful> createState() => _HobbyWidgetState();
}

class _HobbyWidgetState extends State<HobbyWidgetStateful> {
  bool _expanded = false;

  // 현재 섹션에서 선택된 항목들 (중복 방지)
  final List<String> _selectedItems = <String>[];

  @override
  void initState() {
    super.initState();

    // ✅ 프리필: 목록에 존재하는 값만 적용
    if (widget.initialSelected != null) {
      _selectedItems
        ..clear()
        ..addAll(
          widget.initialSelected!.where(
            (e) => widget.section.items.contains(e),
          ),
        );
      // 부모로도 초기 선택 상태 전달
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectionChanged?.call(List<String>.from(_selectedItems));
      });
    }
  }

  void _onPressed(String item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item); // 토글 OFF
      } else {
        _selectedItems.add(item); // 토글 ON
      }
    });
    // 부모(HobbyScreen)로 선택 결과 전달
    widget.onSelectionChanged?.call(List<String>.from(_selectedItems));
  }

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

        // 프리뷰 아이템
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final item in previewItems)
              GestureDetector(
                behavior: HitTestBehavior.opaque, // 🔥 투명영역 탭도 허용
                onTap: () => _onPressed(item),
                child: ChipButton(
                  text: item,
                  isSelected: _selectedItems.contains(item),
                ),
              ),
          ],
        ),

        const SizedBox(height: Sizes.size10),

        // 더보기 펼쳤을 때 나머지 아이템
        if (_expanded)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final item in remainingItems)
                GestureDetector(
                  behavior: HitTestBehavior.opaque, // 🔥 탭 판정 안정화
                  onTap: () => _onPressed(item),
                  child: ChipButton(
                    text: item,
                    isSelected: _selectedItems.contains(item),
                  ),
                ),
            ],
          ),

        // 더보기/접기 토글 (네 로직 그대로)
        Row(
          children: [
            const Expanded(
              child: Divider(color: Colors.black26, thickness: 1, endIndent: 8),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.black,
                size: Sizes.size20,
              ),
              label: const Text(
                "더보기",
                style: TextStyle(color: Colors.black),
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
