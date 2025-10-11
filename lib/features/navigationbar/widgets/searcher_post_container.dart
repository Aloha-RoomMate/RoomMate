import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/view/searcher_post_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearcherPostContainer extends StatelessWidget {
  final SearcherPost post;
  const SearcherPostContainer({super.key, required this.post});

  // ✅ 버킷명/TTL은 룸오너 카드와 동일하게 맞춤
  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 1800; // 30분
  static final _supabase = Supabase.instance.client;

  void _onContainerTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearcherPostView(post: post),
      ),
    );
  }

  String _formatDateFromTimestamp(dynamic ts) {
    try {
      if (ts == null) return '';
      final toDate = (ts as dynamic).toDate?.call();
      if (toDate is DateTime) {
        final y = toDate.year.toString();
        final m = toDate.month.toString().padLeft(2, '0');
        final d = toDate.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      }
    } catch (_) {}
    return '';
  }

  Future<String?> _firstSignedUrl() async {
    final paths = post.imageUrls ?? [];
    if (paths.isEmpty) return null;
    final path = paths.first;
    return await _supabase.storage.from(_bucket).createSignedUrl(path, _urlTtl);
  }

  @override
  Widget build(BuildContext context) {
    final title = (post.title ?? '').isEmpty ? '제목 없음' : post.title!;
    final wantAreas = (post.wantArea ?? const <String>[]).join(', ');
    final moving = _formatDateFromTimestamp(post.movingDate);

    final deposit = post.deposit ?? 0;
    final minRent = post.minRent ?? 0;
    final maxRent = post.maxRent ?? 0;

    final priceLine = '보증금 $deposit만 / 월세 $minRent~$maxRent만';

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
              // === 썸네일 (룸오너 카드와 동일 톤) ===
              ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.size12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: FutureBuilder<String?>(
                    future: _firstSignedUrl(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      final url = snap.data;
                      if (url == null || url.isEmpty) {
                        return Image.asset(
                          'assets/house.jpg',
                          fit: BoxFit.cover,
                        );
                      }
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Image.asset('assets/house.jpg', fit: BoxFit.cover),
                        loadingBuilder: (c, w, p) => p == null
                            ? w
                            : const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
              Gaps.h16(context),

              // === 본문 ===
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
                    Gaps.v6(context),

                    // 희망 지역
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.locationDot,
                          size: Sizes.size12,
                        ),
                        Gaps.h6(context),
                        Expanded(
                          child: Text(
                            wantAreas.isEmpty
                                ? '희망 지역: -'
                                : '희망 지역: $wantAreas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Gaps.v6(context),

                    // 예산/입주일
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.coins,
                          size: Sizes.size12,
                        ),
                        Gaps.h6(context),
                        Expanded(
                          child: Text(
                            priceLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Gaps.h8(context),
                        const FaIcon(
                          FontAwesomeIcons.calendar,
                          size: Sizes.size12,
                        ),
                        Gaps.h6(context),
                        Text(moving.isEmpty ? '-' : moving),
                      ],
                    ),
                  ],
                ),
              ),

              Gaps.h8(context),
              const FaIcon(FontAwesomeIcons.arrowRight, size: Sizes.size16),
            ],
          ),
        ),
      ),
    );
  }
}
