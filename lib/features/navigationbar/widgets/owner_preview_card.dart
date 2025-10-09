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
    // 현재 AppUser 모델에 성별 필드가 없어 안전 처리
    // (추후 성별 필드가 생기면 여기서 꺼내서 반환)
    return '성별 정보 없음';
  }

  String _smokingText(AppUser? u) {
    // AppUser.coliving.smoking(bool) 사용
    final s = u?.coliving?.smoking;
    if (s == null) return '흡연 정보 없음';
    return s ? '흡연' : '비흡연';
  }

  @override
  Widget build(BuildContext context) {
    final deposit = post.deposit ?? 0;
    final rent = post.rent ?? 0;
    final manage = post.manageFee ?? 0;
    final totalMonth = rent + manage;

    // 주소 라벨
    final addrTop = (post.addressLabel ?? '').isNotEmpty
        ? '${post.addressLabel} 부근'
        : '주소 정보 없음';

    final gender = _genderText(author);
    final smoking = _smokingText(author);

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: Colors.white,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            shadowColor: Colors.black26,
            child: InkWell(
              onTap: onOpen, // 박스 탭 시 상세 이동
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.home, size: 28, color: Colors.black87),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1) 주소
                          Text(
                            addrTop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 2) 보증금/월세(관리비 포함)
                          Text(
                            '보증금 $deposit / 월세 $totalMonth (관리비 포함)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // 3) 성별 / 흡연
                          Text(
                            '$gender / $smoking',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (loadingAuthor)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.black45),
                      tooltip: '닫기',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
