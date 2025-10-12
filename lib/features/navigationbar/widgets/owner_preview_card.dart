import 'package:flutter/material.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerPreviewCard extends StatelessWidget {
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

  String _genderText(AppUser? u) => '성별 정보 없음';
  String _smokingText(AppUser? u) {
    final s = u?.coliving?.smoking;
    if (s == null) return '흡연 정보 없음';
    return s ? '흡연' : '비흡연';
  }

  String _dongOnly(String? full) {
    final s = (full ?? '').trim();
    if (s.isEmpty) return '주소 정보 없음';
    final tokens = s.split(RegExp(r'\s+'));
    String pick(String suffix) =>
        tokens.firstWhere((e) => e.endsWith(suffix), orElse: () => '');
    final cand = [
      pick('동'),
      pick('읍'),
      pick('면'),
      pick('리'),
      pick('구'),
    ].firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (cand.isNotEmpty) return cand;
    if (tokens.length >= 2) return '${tokens[0]} ${tokens[1]}';
    return tokens.first;
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveSizes.p(context, 16);
    final pad = ResponsiveSizes.p(context, 14);

    final deposit = post.deposit ?? 0;
    final rent = post.rent ?? 0;
    final manage = post.manageFee ?? 0;
    final dong = _dongOnly(post.addressLabel);

    // 이미지 비율: 9:16(세로형) — 요청대로 “위로 길쭉”
    final photoH = ResponsiveSizes.p(context, 220);
    final photoW = photoH * 9 / 16;
    final photos = (post.imageUrls ?? const <String>[]);

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          // 바깥 영역 탭 -> 닫기 (옵션)
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // 2단계 스냅 가능한 하단 패널
          DraggableScrollableSheet(
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
                  child: Material(
                    color: Colors.white,
                    elevation: 10,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(radius),
                    clipBehavior: Clip.antiAlias,
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        // 핸들 + 닫기
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              pad,
                              pad * 0.7,
                              pad,
                              pad * 0.5,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: ResponsiveSizes.p(context, 36),
                                        height: ResponsiveSizes.p(context, 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(
                                            ResponsiveSizes.p(context, 2),
                                          ),
                                        ),
                                      ),
                                      Gaps.v8(context),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: onClose,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── 섹션 1: 제목 + 사진(가로로 나란히, 9:16)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: pad),
                            child: Text(
                              dong,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: ResponsiveSizes.f(context, 18),
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: Gaps.v10(context)),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: photoH,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              itemCount: (photos.isEmpty ? 1 : photos.length),
                              separatorBuilder: (_, __) => SizedBox(
                                width: ResponsiveSizes.p(context, 8),
                              ),
                              itemBuilder: (_, i) {
                                final path = photos.isEmpty ? null : photos[i];
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

                        // 구분선 (계단 느낌)
                        SliverToBoxAdapter(child: Gaps.v12(context)),
                        const SliverToBoxAdapter(
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        SliverToBoxAdapter(child: Gaps.v12(context)),

                        // ── 섹션 2: 정보 + 액션
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: pad),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate(
                              [
                                _InfoRow(
                                  icon: Icons.home_outlined,
                                  text: (post.addressLabel ?? '위치 비공개'),
                                ),
                                Gaps.v8(context),
                                _InfoRow(
                                  icon: Icons.payments_outlined,
                                  text: '보증금 $deposit 만원',
                                ),
                                Gaps.v8(context),
                                _InfoRow(
                                  icon: Icons.receipt_long_outlined,
                                  text: (manage > 0)
                                      ? '월세 $rent만 + 관리비 $manage만'
                                      : '월세 $rent만 (관리비 없음)',
                                ),
                                Gaps.v8(context),
                                _InfoRow(
                                  icon: Icons.person_outline,
                                  text:
                                      '${_genderText(author)} · ${_smokingText(author)}',
                                ),
                                if (loadingAuthor) ...[
                                  Gaps.v12(context),
                                  Center(
                                    child: SizedBox(
                                      width: ResponsiveSizes.p(context, 20),
                                      height: ResponsiveSizes.p(context, 20),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ],
                                Gaps.v16(context),
                                Text(
                                  '바로 대화해볼까요?',
                                  style: TextStyle(
                                    fontSize: ResponsiveSizes.f(context, 16),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Gaps.v8(context),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: onOpen,
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: ResponsiveSizes.p(
                                              context,
                                              12,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text('상세보기'),
                                      ),
                                    ),
                                    Gaps.h8(context),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: onChat ?? onOpen,
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Gaps.v12(context), // 바닥 여백
                              ],
                            ),
                          ),
                        ),
                      ],
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
