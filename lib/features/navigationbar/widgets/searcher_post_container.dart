import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/features/view/searcher_post_view.dart';

class SearcherPostContainer extends StatelessWidget {
  final SearcherPost post;
  const SearcherPostContainer({
    super.key,
    required this.post,
  });

  void _onTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearcherPostView(post: post)),
    );
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
    final p1 = ResponsiveSizes.p(context, 1);
    final p8 = ResponsiveSizes.p(context, 8);
    final p10 = ResponsiveSizes.p(context, 10);
    final radius = ResponsiveSizes.p(context, 12);

    final fsTitle = ResponsiveSizes.f(context, 16);
    final fsBody = ResponsiveSizes.f(context, 13);
    final iconSizeS = ResponsiveSizes.f(context, 12);

    const lineH = 1.15;
    final gap = p8 * 0.80;

    final p = post;
    final title = (p.title ?? '').isEmpty ? '제목 없음' : p.title!;
    final wantAreas = (p.wantArea ?? const <String>[]).join(', ');
    final moving = _fmtDate(p.movingDate);

    final deposit = p.deposit ?? 0;
    final minRent = p.minRent ?? 0;
    final maxRent = p.maxRent ?? 0;
    final priceLine = '$deposit/$minRent~$maxRent';

    return GestureDetector(
      onTap: () => _onTap(context),
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
            Padding(
              padding: EdgeInsets.fromLTRB(p10, p10, p10, p1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.coins, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Text(
                        '희망 보증금/월세',
                        style: TextStyle(
                          fontSize: fsBody * 1.1,
                          fontWeight: FontWeight.w600,
                          height: lineH,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: fsBody, height: lineH),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.locationDot, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Text(
                        '희망지역',
                        style: TextStyle(
                          fontSize: fsBody * 1.1,
                          fontWeight: FontWeight.w600,
                          height: lineH,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wantAreas.isEmpty ? '-' : wantAreas,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: fsBody, height: lineH),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.calendar, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Text(
                        '입주희망일',
                        style: TextStyle(
                          fontSize: fsBody * 1.1,
                          fontWeight: FontWeight.w600,
                          height: lineH,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    moving.isEmpty ? '-' : moving,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: fsBody, height: lineH),
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
