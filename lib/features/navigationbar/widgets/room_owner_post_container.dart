import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomOwnerPostContainer extends StatefulWidget {
  final RoomOwnerPost post;
  final double imageAspect; // 가로/세로 비 (e.g., 0.9)
  const RoomOwnerPostContainer({
    super.key,
    required this.post,
    this.imageAspect = 0.93,
  });

  @override
  State<RoomOwnerPostContainer> createState() => _RoomOwnerPostContainerState();
}

class _RoomOwnerPostContainerState extends State<RoomOwnerPostContainer> {
  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 1800; // 30분
  static final _supabase = Supabase.instance.client;

  late final Future<List<String>> _urlsFuture;
  final PageController _pageCtrl = PageController();
  int _page = 0;

  final _numKo = NumberFormat.decimalPattern('ko');

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
      MaterialPageRoute(builder: (_) => RoomOwnerPostView(post: widget.post)),
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

  String _fmtMan(int? v) {
    if (v == null) return '-';
    return '${_numKo.format(v)}만';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  @override
  Widget build(BuildContext context) {
    final p8 = ResponsiveSizes.p(context, 8);
    final p10 = ResponsiveSizes.p(context, 10);
    final radius = ResponsiveSizes.p(context, 12);
    final iconSizeS = ResponsiveSizes.f(context, 12);
    final fsBody = ResponsiveSizes.f(context, 13);

    final post = widget.post;
    final addr = post.addressLabel ?? '위치 비공개';
    final rent = post.rent;
    final manage = post.manageFee;
    final deposit = post.deposit;
    final moveIn = _formatDate(post.movingDate?.toDate());

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
            // ====== 상단 이미지 스와이프 ======
            AspectRatio(
              aspectRatio: widget.imageAspect, // 0.9 (이미지 살짝 낮춤)
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
                      // 날짜 배지(선택)
                      if (moveIn.isNotEmpty)
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
                              moveIn,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fsBody * 0.9,
                              ),
                            ),
                          ),
                        ),
                      // 페이지 인디케이터
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

            // ====== 하단 텍스트 (4줄: 위치 + 월세 + 관리비 + 보증금) ======
            Padding(
              padding: EdgeInsets.fromLTRB(p10, p10, p10, p10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) 위치 (말줄임)
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.locationDot, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Expanded(
                        child: Text(
                          addr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: fsBody, height: 1.15),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: p8 * 0.75),

                  // 2) 월세
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.coins, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Expanded(
                        child: Text(
                          '월세 ${_fmtMan(rent)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: fsBody),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: p8 * 0.75),

                  // 3) 관리비
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.fileInvoiceDollar,
                        size: iconSizeS,
                      ),
                      SizedBox(width: p8 * 0.75),
                      Expanded(
                        child: Text(
                          '관리비 ${_fmtMan(manage)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: fsBody),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: p8 * 0.75),

                  // 4) 보증금
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.piggyBank, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Expanded(
                        child: Text(
                          '보증금 ${_fmtMan(deposit)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: fsBody),
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
