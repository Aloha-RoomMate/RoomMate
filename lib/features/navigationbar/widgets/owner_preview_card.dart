// owner_preview_card.dart
import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';

class OwnerPreviewCard extends StatelessWidget {
  final RoomOwnerPost post;
  final AppUser? author;
  final bool loadingAuthor;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const OwnerPreviewCard({
    super.key,
    required this.post,
    required this.author,
    required this.loadingAuthor,
    required this.onOpen,
    required this.onClose,
  });

  String _genderText(AppUser? u) {
    // 현재 AppUser에 성별 필드 없음 → 안전 처리
    return '성별 정보 없음';
  }

  String _smokingText(AppUser? u) {
    final s = u?.coliving?.smoking;
    if (s == null) return '흡연 정보 없음';
    return s ? '흡연' : '비흡연';
  }

  // ✅ "xx길 xx" 또는 "xx로 xx" 등으로 축약
  String _roadShort(String? full) {
    final s = (full ?? '').trim();
    if (s.isEmpty) return '주소 정보 없음';

    final tokens = s.split(RegExp(r'\s+'));
    final isRoad = RegExp(r'(로|길|대로|가)$'); // 도로명 토큰
    final isNumber = RegExp(r'^\d+(-\d+)?$'); // 12 or 12-3

    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (isRoad.hasMatch(t)) {
        // 다음 토큰 중 숫자 찾기
        if (i + 1 < tokens.length && isNumber.hasMatch(tokens[i + 1])) {
          return '$t ${tokens[i + 1]}';
        }
        for (int j = i + 1; j < tokens.length; j++) {
          if (isNumber.hasMatch(tokens[j])) return '$t ${tokens[j]}';
        }
        return t; // 숫자 못 찾으면 도로명만
      }
    }

    // 도로명 못 찾으면 동 기준 혹은 앞의 2토큰
    final dongIdx = tokens.indexWhere((e) => e.endsWith('동'));
    if (dongIdx != -1) return tokens[dongIdx];
    if (tokens.length >= 2) return '${tokens[0]} ${tokens[1]}';
    return tokens.first;
  }

  String _dongOnly(String? full) {
    final s = (full ?? '').trim();
    if (s.isEmpty) return '주소 정보 없음';

    final tokens = s.split(RegExp(r'\s+'));

    // 항상 String을 반환(없으면 '')
    String pick(String suffix) =>
        tokens.firstWhere((e) => e.endsWith(suffix), orElse: () => '');

    // 우선순위: 동 > 읍 > 면 > 리 > 구
    final d = pick('동');
    final eup = pick('읍');
    final myeon = pick('면');
    final ri = pick('리');
    final gu = pick('구');

    final cand = [d, eup, myeon, ri, gu].firstWhere(
      (e) => e.isNotEmpty,
      orElse: () => '',
    );

    if (cand.isNotEmpty) return cand;
    if (tokens.length >= 2) return '${tokens[0]} ${tokens[1]}';
    return tokens.first;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardW = size.width * 0.90; // 너비 90%
    final cardH = size.height * 0.40; // 높이 40% (요구사항대로)

    final deposit = post.deposit ?? 0;
    final rent = post.rent ?? 0;
    final manage = post.manageFee ?? 0;
    final totalMonth = rent + manage;

    final dong = _dongOnly(post.addressLabel);
    final addrTop = '$dong 부근';

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: const ValueKey('owner_preview_card'),
            direction: DismissDirection.down, // 아래로 스와이프 닫기
            onDismissed: (_) => onClose(),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: cardW,
                height: cardH,
                child: Material(
                  color: Colors.white,
                  elevation: 10,
                  borderRadius: BorderRadius.circular(16),
                  shadowColor: Colors.black26,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // 상단 핸들 + 닫기
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black45,
                              ),
                              tooltip: '닫기',
                            ),
                          ],
                        ),
                      ),

                      // 내용
                      Expanded(
                        child: InkWell(
                          onTap: onOpen, // 전체 탭 → 상세로
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1) 주소 (축약)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place,
                                      size: 18,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        addrTop,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // 2) 금액 (관리비 포함)
                                Text(
                                  '보증금 $deposit / 월세 $totalMonth (관리비 포함)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // 3) 성별 / 흡연
                                Text(
                                  '${_genderText(author)} / ${_smokingText(author)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Colors.black12),

                                // 작성자 로딩 스피너
                                Expanded(
                                  child: Center(
                                    child: loadingAuthor
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    '자세히 보기',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
