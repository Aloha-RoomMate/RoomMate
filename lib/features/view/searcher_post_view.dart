import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearcherPostView extends StatefulWidget {
  final SearcherPost post;
  const SearcherPostView({super.key, required this.post});

  @override
  State<SearcherPostView> createState() => _SearcherPostViewState();
}

class _SearcherPostViewState extends State<SearcherPostView> {
  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 1800;
  static final _supabase = Supabase.instance.client;

  Future<List<String>> _signedUrls() async {
    final paths = widget.post.imageUrls ?? const <String>[];
    if (paths.isEmpty) return const <String>[];
    final urls = <String>[];
    for (final p in paths) {
      final u = await _supabase.storage
          .from(_bucket)
          .createSignedUrl(p, _urlTtl);
      urls.add(u);
    }
    return urls;
  }

  String _fmtDate(dynamic ts) {
    try {
      if (ts == null) return '-';
      final toDate = (ts as dynamic).toDate?.call();
      if (toDate is DateTime) {
        final y = toDate.year.toString();
        final m = toDate.month.toString().padLeft(2, '0');
        final d = toDate.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      }
    } catch (_) {}
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;

    final title = (p.title ?? '').isEmpty ? '제목 없음' : p.title!;
    final wantAreas = (p.wantArea ?? const <String>[]).join(', ');
    final wantRoom = (p.wantRoom ?? const <String>[]).join(', ');
    final wantPay = (p.wantPay ?? const <String>[]).join(', ');

    final deposit = p.deposit ?? 0;
    final minRent = p.minRent ?? 0;
    final maxRent = p.maxRent ?? 0;

    final moving = _fmtDate(p.movingDate);
    final contract = '${p.minContract ?? 0}~${p.maxContract ?? 0}개월';

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 보기', style: TextStyle(fontSize: Sizes.size18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              title,
              style: const TextStyle(
                fontSize: Sizes.size20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Gaps.v14(context),

            // 이미지 그리드
            FutureBuilder<List<String>>(
              future: _signedUrls(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final urls = snap.data ?? const <String>[];
                if (urls.isEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/house.jpg',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: urls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      urls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Image.asset('assets/house.jpg', fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
            Gaps.v16(context),

            // 정보 블록
            _InfoRow(
              icon: FontAwesomeIcons.locationDot,
              label: '희망 지역',
              value: wantAreas.isEmpty ? '-' : wantAreas,
            ),
            Gaps.v10(context),
            _InfoRow(
              icon: FontAwesomeIcons.houseChimney,
              label: '희망 구조',
              value: wantRoom.isEmpty ? '-' : wantRoom,
            ),
            Gaps.v10(context),
            _InfoRow(
              icon: FontAwesomeIcons.handHoldingDollar,
              label: '지불 구조',
              value: wantPay.isEmpty ? '-' : wantPay,
            ),
            Gaps.v10(context),
            _InfoRow(
              icon: FontAwesomeIcons.coins,
              label: '예산',
              value: '보증금 $deposit만 / 월세 $minRent~$maxRent만',
            ),
            Gaps.v10(context),
            _InfoRow(
              icon: FontAwesomeIcons.calendar,
              label: '입주 희망일',
              value: moving,
            ),
            Gaps.v10(context),
            _InfoRow(
              icon: FontAwesomeIcons.solidClock,
              label: '희망 계약',
              value: contract,
            ),
            Gaps.v16(context),

            const Text(
              '자기소개',
              style: TextStyle(
                fontSize: Sizes.size16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gaps.v6(context),
            Text(
              (p.introduction ?? '').isEmpty ? '소개가 없습니다.' : p.introduction!,
              style: const TextStyle(fontSize: Sizes.size14, height: 1.5),
            ),
            Gaps.v40(context),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: Sizes.size14),
        Gaps.h8(context),
        Text(
          '$label : ',
          style: const TextStyle(
            fontSize: Sizes.size14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: Sizes.size14),
          ),
        ),
      ],
    );
  }
}
