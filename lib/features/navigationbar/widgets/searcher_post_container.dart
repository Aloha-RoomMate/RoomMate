import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/features/view/searcher_post_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearcherPostContainer extends StatefulWidget {
  final SearcherPost post;
  final double imageAspect; // 가로/세로 비 (width/height)
  const SearcherPostContainer({
    super.key,
    required this.post,
    this.imageAspect = 0.93, // ← 0.9에서 살짝 올려 높이 감소
  });

  @override
  State<SearcherPostContainer> createState() => _SearcherPostContainerState();
}

class _SearcherPostContainerState extends State<SearcherPostContainer> {
  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 1800;
  static final _supabase = Supabase.instance.client;

  late final Future<List<String>> _urlsFuture;
  final PageController _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _urlsFuture = _signedUrls(max: 3);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearcherPostView(post: widget.post)),
    );
  }

  Future<List<String>> _signedUrls({int max = 3}) async {
    final paths = widget.post.imageUrls ?? const <String>[];
    if (paths.isEmpty) return [];
    final take = paths.take(max).toList();
    final urls = await Future.wait(
      take.map(
        (p) => _supabase.storage.from(_bucket).createSignedUrl(p, _urlTtl),
      ),
    );
    return urls.where((u) => u.isNotEmpty).toList();
  }

  String _fmtDate(dynamic ts) {
    try {
      final dt = (ts as dynamic).toDate?.call();
      if (dt is DateTime) {
        final y = dt.year.toString();
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return '$y/$m/$d';
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final p8 = ResponsiveSizes.p(context, 8);
    final p10 = ResponsiveSizes.p(context, 10);
    final radius = ResponsiveSizes.p(context, 12);

    final fsTitle = ResponsiveSizes.f(context, 16);
    final fsBody = ResponsiveSizes.f(context, 13);
    final iconSizeS = ResponsiveSizes.f(context, 12);

    const lineH = 1.15; // ← 고정 라인높이로 라인박스 흔들림 방지
    final gap = p8 * 0.65; // ← 살짝 줄인 세로 간격

    final p = widget.post;
    final title = (p.title ?? '').isEmpty ? '제목 없음' : p.title!;
    final wantAreas = (p.wantArea ?? const <String>[]).join(', ');
    final moving = _fmtDate(p.movingDate);

    final deposit = p.deposit ?? 0;
    final minRent = p.minRent ?? 0;
    final maxRent = p.maxRent ?? 0;
    final priceLine = '보증금 $deposit만 · 월세 $minRent~$maxRent만';

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Color(0x14000000),
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 스와이프 (aspect 조정됨)
            AspectRatio(
              aspectRatio: widget.imageAspect, // ← 0.93
              child: FutureBuilder<List<String>>(
                future: _urlsFuture,
                builder: (context, snap) {
                  final urls = snap.data ?? const <String>[];
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (urls.isEmpty) {
                    return Image.asset('assets/house.jpg', fit: BoxFit.cover);
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageCtrl,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemCount: urls.length,
                        itemBuilder: (_, i) => Image.network(
                          urls[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/house.jpg',
                            fit: BoxFit.cover,
                          ),
                          loadingBuilder: (c, w, p) => p == null
                              ? w
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                        ),
                      ),
                      // 날짜
                      Positioned(
                        left: p8,
                        bottom: p8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: p10,
                            vertical: p8 * 0.6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            moving.isEmpty ? '' : moving,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fsBody * 0.9,
                              height: lineH,
                            ),
                          ),
                        ),
                      ),
                      // 인디케이터
                      if (urls.length > 1)
                        Positioned(
                          right: p8,
                          bottom: p8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: p10 * 0.7,
                              vertical: p8 * 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(urls.length, (i) {
                                final active = i == _page;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: p8 * 0.25,
                                  ),
                                  width: active ? p8 * 1.2 : p8 * 0.9,
                                  height: p8 * 0.9,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      active ? 0.95 : 0.6,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // 하단 텍스트 (정확히 3줄: 제목/가격/희망지역)
            Padding(
              padding: EdgeInsets.fromLTRB(p10, p10, p10, p10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) 제목 (1줄)
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fsTitle,
                      fontWeight: FontWeight.w700,
                      height: lineH,
                    ),
                  ),
                  SizedBox(height: gap),

                  // 2) 예산 (1줄)
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.coins, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Expanded(
                        child: Text(
                          priceLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: fsBody, height: lineH),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),

                  // 3) 희망 지역 (1줄)
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.locationDot, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Expanded(
                        child: Text(
                          wantAreas.isEmpty ? '희망 지역: -' : '희망 지역: $wantAreas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: fsBody, height: lineH),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
