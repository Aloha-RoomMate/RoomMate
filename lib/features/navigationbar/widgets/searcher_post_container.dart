import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/user_repository.dart'; // UserRepository 임포트
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/features/view/searcher_post_view.dart';

class SearcherPostContainer extends StatefulWidget {
  final SearcherPost post; // 개별 post

  const SearcherPostContainer({
    super.key,
    required this.post,
  });

  @override
  State<SearcherPostContainer> createState() => _SearcherPostContainerState();
}

class _SearcherPostContainerState extends State<SearcherPostContainer> {
  AppUser? _author; // 작성자 저장할 변수
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAuthor();
  }

  Future<void> _fetchAuthor() async {
    if (widget.post.authorId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final repo = UserRepository();
    final user = await repo.fetchUserById(
      widget.post.authorId!,
    ); // post의 authorid로 접근해서 작성자 정보 가져오기
    if (mounted) {
      setState(() {
        _author = user;
        _isLoading = false;
      });
    }
  }

  void _onTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearcherPostView(post: widget.post)),
    );
  }

  String _fmtDate(dynamic dateValue) {
    DateTime? dt;
    if (dateValue is DateTime) {
      dt = dateValue;
    } else if (dateValue is Timestamp) {
      dt = dateValue.toDate();
    }

    if (dt != null) {
      final y = dt.year.toString();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y/$m/$d';
    }

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

    final p = widget.post;
    final title = (p.title ?? '').isEmpty ? '제목 없음' : p.title!;
    final wantAreas = (p.wantArea ?? const <String>[]).join(', ');
    final moving = _fmtDate(p.movingDate);

    final deposit = p.deposit ?? 0;
    final minRent = p.minRent ?? 0;
    final maxRent = p.maxRent ?? 0;
    final priceLine = '$deposit/$minRent~$maxRent';
    final createdAt = _fmtDate(p.createdAt);

    final authorBirthYear = _author?.birthYear;
    final authorSmoking = _author?.coliving?.smoking;

    String authorInfo = '정보 없음';
    if (_isLoading) {
      authorInfo = '로딩 중...';
    } else if (_author != null) {
      final birthYear = authorBirthYear ?? '미입력';
      final smoking = (authorSmoking == null)
          ? '미입력'
          : (authorSmoking ? '흡연' : '비흡연');
      authorInfo = '$birthYear년생 / $smoking';
    }

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
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(p10, p10, p10, p10),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.person, size: iconSizeS),
                      SizedBox(width: p8 * 0.75),
                      Text(
                        '입주 희망자',
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
                    authorInfo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: fsBody, height: lineH),
                  ),
                ],
              ),
            ),
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
                child: Text(
                  createdAt,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fsBody * 0.9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
