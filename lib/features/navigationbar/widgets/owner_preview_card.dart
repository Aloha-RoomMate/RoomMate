import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerPreviewCard extends StatefulWidget {
  final RoomOwnerPost post;
  final AppUser? author;
  final bool loadingAuthor;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback? onChat;

  const OwnerPreviewCard({
    super.key,
    required this.post,
    required this.author,
    required this.loadingAuthor,
    required this.onOpen,
    required this.onClose,
    this.onChat,
  });

  @override
  State<OwnerPreviewCard> createState() => _OwnerPreviewCardState();
}

class _OwnerPreviewCardState extends State<OwnerPreviewCard>
    with SingleTickerProviderStateMixin {
  final _dragCtrl = DraggableScrollableController();
  double _dragDeltaY = 0;

  // 닫힘 애니메이션(페이드 + 아래로 살짝 슬라이드)
  late final AnimationController _dismissCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _opacity = Tween(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(
      parent: _dismissCtrl,
      curve: Curves.easeOutCubic,
    ),
  );
  late final Animation<Offset> _slide =
      Tween(begin: Offset.zero, end: const Offset(0, 0.12)).animate(
        CurvedAnimation(parent: _dismissCtrl, curve: Curves.easeOut),
      );

  // ───────────────── helpers ─────────────────
  SliverToBoxAdapter _sliverGap(BuildContext context, double units) =>
      SliverToBoxAdapter(
        child: SizedBox(height: ResponsiveSizes.p(context, units)),
      );

  String _smokingText(AppUser? u) {
    final s = u?.coliving?.smoking;
    if (s == null) return '흡연 정보 없음';
    return s ? '흡연' : '비흡연';
  }

  Future<void> _dismissSmoothly() async {
    // 시트를 최소 스냅 사이즈로 부드럽게 내린 다음 페이드 아웃
    try {
      await _dragCtrl.animateTo(
        0.36,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    } catch (_) {}
    await _dismissCtrl.forward();
    if (mounted) widget.onClose();
    // onClose 후에는 대체로 위젯이 dispose되지만, 혹시 몰라 리셋
    _dismissCtrl.reset();
  }

  void _onHandleDragUpdate(DragUpdateDetails d) {
    _dragDeltaY += d.delta.dy;

    // 드래그 중에 살짝 투명/슬라이드 느낌 (최대 60% 정도만 미리 적용)
    final down = _dragDeltaY.clamp(0.0, 120.0);
    final progress = (down / 120.0) * 0.6; // 0.0 ~ 0.6
    _dismissCtrl.value = progress;
  }

  // ── 추가: 드래그 핸들 스타트/캔슬 핸들러
  void _onHandleDragDown(DragDownDetails d) {
    // 드래그 시작 즉시 우리가 제스처를 잡아 "꾹 눌러야" 하는 느낌 제거
    _dragDeltaY = 0;
    _dismissCtrl.stop();
  }

  void _onHandleDragCancel() {
    // 취소되면 원래 상태로
    _dismissCtrl.reverse();
  }

  // ── 기존 _onHandleDragEnd 내부 임계치만 살짝 완화
  void _onHandleDragEnd(DragEndDetails d) async {
    final v = d.primaryVelocity ?? 0;
    const deltaThreshold = 14.0; // 기존 24 → 14로 낮춤
    const flingDown = 600.0;
    const flingUp = -200.0;

    if (v > flingDown || _dragDeltaY > deltaThreshold) {
      await _dismissSmoothly();
    } else if (v < flingUp || _dragDeltaY < -deltaThreshold) {
      try {
        await _dragCtrl.animateTo(
          0.86,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } catch (_) {}
      _dismissCtrl.reverse();
    } else {
      try {
        final target = (_dragDeltaY >= 0) ? 0.36 : 0.86;
        await _dragCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
        );
      } catch (_) {}
      _dismissCtrl.reverse();
    }
    _dragDeltaY = 0;
  }

  @override
  void dispose() {
    _dismissCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveSizes.p(context, 16);
    final pad = ResponsiveSizes.p(context, 14);

    final deposit = widget.post.deposit ?? 0;
    final rent = widget.post.rent ?? 0;
    final manage = widget.post.manageFee ?? 0;

    final dong = widget.post.getAddressLabel;
    final photos = (widget.post.imageUrls ?? const <String>[]);

    // 세로형(9:16)
    final photoH = ResponsiveSizes.p(context, 220);
    final photoW = photoH * 9 / 16;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          // 바깥 영역 탭 → "부드럽게 닫기"
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismissSmoothly,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          DraggableScrollableSheet(
            controller: _dragCtrl,
            initialChildSize: 0.42,
            minChildSize: 0.36,
            maxChildSize: 0.86,
            snap: true,
            snapSizes: const [0.36, 0.86],
            builder: (context, scrollController) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveSizes.p(context, 10),
                    left: ResponsiveSizes.p(context, 10),
                    right: ResponsiveSizes.p(context, 10),
                  ),
                  child: SlideTransition(
                    position: _slide,
                    child: FadeTransition(
                      opacity: _opacity,
                      child: Material(
                        color: Colors.white,
                        elevation: 10,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(radius),
                        clipBehavior: Clip.antiAlias,
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            // ── 핸들 (X 아이콘 제거, 핸들 중앙 정렬)
                            // ── 핸들(확대 + dragDown/cancel 추가, X 아이콘 없음)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  pad,
                                  pad * 0.7,
                                  pad,
                                  pad * 0.5,
                                ),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onVerticalDragDown: _onHandleDragDown,
                                  onVerticalDragUpdate: _onHandleDragUpdate,
                                  onVerticalDragEnd: _onHandleDragEnd,
                                  onVerticalDragCancel: _onHandleDragCancel,
                                  child: SizedBox(
                                    height: ResponsiveSizes.p(
                                      context,
                                      56,
                                    ), // 터치 타깃 넉넉히
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: ResponsiveSizes.p(
                                            context,
                                            56,
                                          ), // grip 너비 확대 (기존 36)
                                          height: ResponsiveSizes.p(
                                            context,
                                            6,
                                          ), // grip 높이 확대 (기존 4)
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: BorderRadius.circular(
                                              ResponsiveSizes.p(context, 3),
                                            ),
                                          ),
                                        ),
                                        Gaps.v8(context),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ── 1) 제목
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: pad),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.post.title?.trim().isNotEmpty ==
                                              true
                                          ? widget.post.title!.trim()
                                          : dong,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: ResponsiveSizes.f(
                                          context,
                                          18,
                                        ),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (widget.post.title?.trim().isNotEmpty ==
                                        true) ...[
                                      Gaps.v4(context),
                                      Text(
                                        dong,
                                        style: TextStyle(
                                          fontSize: ResponsiveSizes.f(
                                            context,
                                            13,
                                          ),
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            _sliverGap(context, 12),
                            const SliverToBoxAdapter(
                              child: Divider(height: 1, color: Colors.black12),
                            ),
                            _sliverGap(context, 12),

                            // ── 2) 정보(위치/보증금/월세/흡연 등)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate(
                                  [
                                    _InfoRow(
                                      icon: Icons.place_outlined,
                                      text: dong,
                                    ),
                                    Gaps.v8(context),
                                    _InfoRow(
                                      icon: Icons.payments_outlined,
                                      text: '보증금 $deposit',
                                    ),
                                    Gaps.v8(context),
                                    _InfoRow(
                                      icon: Icons.receipt_long_outlined,
                                      text: (manage > 0)
                                          ? '월세 $rent · 관리비 $manage'
                                          : '월세 $rent (관리비 없음)',
                                    ),
                                    Gaps.v8(context),
                                    _InfoRow(
                                      icon: Icons.smoking_rooms_rounded,
                                      text: _smokingText(widget.author),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            _sliverGap(context, 12),
                            const SliverToBoxAdapter(
                              child: Divider(height: 1, color: Colors.black12),
                            ),
                            _sliverGap(context, 12),

                            // ── 3) 사진(세로 갤러리)
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: photoH,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: pad,
                                  ),
                                  itemCount: (photos.isEmpty
                                      ? 1
                                      : photos.length),
                                  separatorBuilder: (_, __) => SizedBox(
                                    width: ResponsiveSizes.p(context, 8),
                                  ),
                                  itemBuilder: (_, i) {
                                    final path = photos.isEmpty
                                        ? null
                                        : photos[i];
                                    return SizedBox(
                                      width: photoW,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AspectRatio(
                                          aspectRatio: 9 / 16,
                                          child: path == null
                                              ? Image.asset(
                                                  'assets/house.jpg',
                                                  fit: BoxFit.cover,
                                                )
                                              : _SupabaseOrNetImage(path: path),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            _sliverGap(context, 16),

                            // ── 4) CTA: 바로 대화해볼까요?
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate(
                                  [
                                    Text(
                                      '바로 대화해볼까요?',
                                      style: TextStyle(
                                        fontSize: ResponsiveSizes.f(
                                          context,
                                          16,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Gaps.v8(context),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: widget.onOpen,
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                vertical: ResponsiveSizes.p(
                                                  context,
                                                  12,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      20,
                                                    ),
                                              ),
                                            ),
                                            child: const Text('상세보기'),
                                          ),
                                        ),
                                        Gaps.h8(context),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                widget.onChat ?? widget.onOpen,
                                            icon: const Icon(
                                              Icons.chat_bubble_outline,
                                            ),
                                            label: const Text('채팅하기'),
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                vertical: ResponsiveSizes.p(
                                                  context,
                                                  12,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      20,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Gaps.v12(context),
                                  ],
                                ),
                              ),
                            ),

                            // 작성자 로딩 스피너(필요 시)
                            if (widget.loadingAuthor)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: ResponsiveSizes.p(context, 8),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: ResponsiveSizes.p(context, 20),
                                      height: ResponsiveSizes.p(context, 20),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: ResponsiveSizes.p(context, 18), color: Colors.black87),
        Gaps.h8(context),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

/// Supabase 스토리지 경로면 서명 URL을 만들어서 보여주고,
/// 절대 URL(http…)이면 그대로 보여준다.
class _SupabaseOrNetImage extends StatelessWidget {
  const _SupabaseOrNetImage({required this.path});

  final String path;
  static const _bucket = 'RoomMate-image';
  static const _ttlSec = 1800;

  bool get _isAbsolute => path.startsWith('http');

  Future<String> _signed() async {
    final cli = Supabase.instance.client;
    final url = await cli.storage.from(_bucket).createSignedUrl(path, _ttlSec);
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (_isAbsolute) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/house.jpg', fit: BoxFit.cover),
      );
    }
    return FutureBuilder<String>(
      future: _signed(),
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final url = s.data;
        if (url == null || url.isEmpty) {
          return Image.asset('assets/house.jpg', fit: BoxFit.cover);
        }
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Image.asset('assets/house.jpg', fit: BoxFit.cover);
          },
        );
      },
    );
  }
}
