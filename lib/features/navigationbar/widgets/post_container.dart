import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';

class PostContainer extends StatelessWidget {
  final RoomOwnerPost post;
  const PostContainer({super.key, required this.post});

  void _onContainerTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomOwnerPostView(post: post), // 상세 화면으로 이동(필요 시 수정)
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final title = (post.title ?? '').isEmpty ? '제목 없음' : post.title!;
    final addressLabel = (post.addressLabel ?? '위치 비공개'); // ↓ 2번에서 추가하는 필드
    final moveIn = _formatDate(post.movingDate?.toDate());
    final deposit = post.deposit ?? 0;
    final rent = post.rent ?? 0;
    final manage = post.manageFee ?? 0;

    final priceLine =
        '보증금 $deposit만 / 월세 $rent만'
        '${manage > 0 ? ' (+관리비 $manage만)' : ''}';

    final imageUrl = (post.imageUrls != null && post.imageUrls!.isNotEmpty)
        ? post.imageUrls!.first
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.size12,
        vertical: Sizes.size4,
      ),
      child: GestureDetector(
        onTap: () => _onContainerTap(context),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.98,
          height: 110,
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.size8,
            vertical: Sizes.size8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.size12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: imageUrl == null
                      ? Image.asset('assets/house.jpg', fit: BoxFit.cover)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/house.jpg',
                            fit: BoxFit.cover,
                          ),
                          loadingBuilder: (c, w, progress) => progress == null
                              ? w
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                        ),
                ),
              ),
              Gaps.h16,
              // 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: Sizes.size16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gaps.v6,
                    // 주소
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.locationDot,
                          size: Sizes.size12,
                        ),
                        Gaps.h6,
                        Expanded(
                          child: Text(
                            addressLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Gaps.v6,
                    // 가격/입주일
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.coins,
                          size: Sizes.size12,
                        ),
                        Gaps.h6,
                        Expanded(
                          child: Text(
                            priceLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Gaps.h8,
                        const FaIcon(
                          FontAwesomeIcons.calendar,
                          size: Sizes.size12,
                        ),
                        Gaps.h6,
                        Text(moveIn.isEmpty ? '-' : moveIn),
                      ],
                    ),
                  ],
                ),
              ),
              Gaps.h8,
              const FaIcon(FontAwesomeIcons.arrowRight, size: Sizes.size16),
            ],
          ),
        ),
      ),
    );
  }
}
