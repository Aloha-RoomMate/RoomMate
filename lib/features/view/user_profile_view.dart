import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';

import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/widgets/accordion_widget.dart';
import 'package:roommate/features/navigationbar/widgets/chip_button.dart';
import 'package:roommate/features/navigationbar/widgets/room_owner_post_container.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 상대방 프로필 화면
///  - 단건 get으로 사용자 프로필을 읽어옴 (Rules: get 허용)
///  - roomOwnerPosts는 공개 read 가능
class UserProfileView extends StatefulWidget {
  const UserProfileView({
    super.key,
    required this.targetUid,
  });

  final String targetUid;

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final _userRepo = UserRepository();
  final _postRepo = RoomOwnerPostRepository();

  Future<AppUser?>? _futureUser;

  @override
  void initState() {
    super.initState();
    _futureUser = _userRepo.fetchUserById(widget.targetUid);
  }

  /// 분(예: 510) → "08:30"
  String _fmtHm(int? minutes, {bool use12h = false}) {
    if (minutes == null) return "-";
    final h24 = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    if (!use12h) {
      return "${h24.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
    } else {
      final isAm = h24 < 12;
      final h12 = (h24 % 12 == 0) ? 12 : (h24 % 12);
      return "${isAm ? "오전" : "오후"} $h12:${m.toString().padLeft(2, '0')}";
    }
  }

  String _introText(AppUser u) {
    final any = u.introduction;
    if (any == null) return "";
    return any.toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _futureUser,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        if (waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("존재하지 않는 사용자입니다.")),
          );
        }

        final user = snapshot.data!;
        final userDailyRhythm = user.dailyRhythm;
        final colivingPreference = user.coliving;
        final userTypeInfo = user.userType;
        final userHobby = user.hobby;

        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            title: Text(
              "${user.displayName}의 프로필",
              style: const TextStyle(fontSize: Sizes.size24),
            ),
          ),

          body: Padding(
            padding: const EdgeInsets.only(
              top: Sizes.size8,
              right: Sizes.size24,
              left: Sizes.size24,
              bottom: Sizes.size24,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ───────────────── 프로필 헤더 ─────────────────
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            (user.photoURL != null && user.photoURL!.isNotEmpty)
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: (user.photoURL == null || user.photoURL!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.grey.shade600,
                              )
                            : null,
                      ),
                      Gaps.v8(context),
                      Text(
                        user.birthYear != null
                            ? '${user.displayName}-${user.birthYear}'
                            : '${user.displayName} (생년월일 정보 없음)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(userTypeInfo?.type ?? '-'),
                    ],
                  ),
                  Gaps.v12(context),
                  Divider(
                    height: 1,
                    color: Theme.of(context).primaryColor.withAlpha(100),
                  ),
                  Gaps.v12(context),

                  // ───────────────── 생활 패턴 ─────────────────
                  AccordionWidget(
                    title: "생활 패턴",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeldRow(
                          label: "출근일",
                          chips: [
                            for (final day
                                in (userDailyRhythm?.workDays ??
                                    const <String>[]))
                              ChipButton(text: day, isSelected: true),
                          ],
                        ),
                        LabeldRow(
                          label: "주중 시간",
                          chips: [
                            if (userDailyRhythm?.weekAwakeMins != null)
                              ChipButton(
                                text:
                                    "기상 ${_fmtHm(userDailyRhythm!.weekAwakeMins)}",
                                isSelected: true,
                              ),
                            if (userDailyRhythm?.weekSleepMins != null)
                              ChipButton(
                                text:
                                    "취침 ${_fmtHm(userDailyRhythm!.weekSleepMins)}",
                                isSelected: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ───────────────── 공동 생활 성향 ─────────────────
                  AccordionWidget(
                    title: "공동 생활 성향",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeldRow(
                          label: "공용 공간 선호",
                          chips: [
                            if ((colivingPreference?.coSpace ?? '').isNotEmpty)
                              ChipButton(
                                text: colivingPreference!.coSpace,
                                isSelected: true,
                              ),
                          ],
                        ),
                        LabeldRow(
                          label: "교류도",
                          chips: [
                            if ((colivingPreference?.interaction ?? '')
                                .isNotEmpty)
                              ChipButton(
                                text: colivingPreference!.interaction,
                                isSelected: true,
                              ),
                          ],
                        ),
                        LabeldRow(
                          label: "정리 정돈",
                          chips: [
                            if ((colivingPreference?.cleanOption ?? '')
                                .isNotEmpty)
                              ChipButton(
                                text: colivingPreference!.cleanOption,
                                isSelected: true,
                              ),
                          ],
                        ),
                        LabeldRow(
                          label: "화장실",
                          chips: [
                            if ((colivingPreference?.bathroom ?? '').isNotEmpty)
                              ChipButton(
                                text: colivingPreference!.bathroom,
                                isSelected: true,
                              ),
                          ],
                        ),
                        LabeldRow(
                          label: "MBTI",
                          chips: [
                            if ((colivingPreference?.mbti ?? '').isNotEmpty)
                              ChipButton(
                                text: colivingPreference!.mbti,
                                isSelected: true,
                              ),
                          ],
                        ),
                        LabeldRow(
                          label: "반려동물",
                          chips: (colivingPreference?.pet ?? const <String>[])
                              .map((e) => ChipButton(text: e, isSelected: true))
                              .toList(),
                        ),
                        LabeldRow(
                          label: "흡연",
                          chips: [
                            if (colivingPreference?.smoking != null)
                              ChipButton(
                                text: colivingPreference!.smoking
                                    ? "흡연"
                                    : "비흡연",
                                isSelected: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ───────────────── 취미/관심 ─────────────────
                  AccordionWidget(
                    title: "취미/관심",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeldRow(
                          label: "최애 음식",
                          chips: (userHobby?.foodLike ?? const <String>[])
                              .map((e) => ChipButton(text: e, isSelected: true))
                              .toList(),
                        ),
                        LabeldRow(
                          label: "관심사",
                          chips: (userHobby?.interestLike ?? const <String>[])
                              .map((e) => ChipButton(text: e, isSelected: true))
                              .toList(),
                        ),
                        LabeldRow(
                          label: "운동",
                          chips: (userHobby?.sportLike ?? const <String>[])
                              .map((e) => ChipButton(text: e, isSelected: true))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // ───────────────── 자기소개 ─────────────────
                  AccordionWidget(
                    title: "자기소개",
                    content: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Sizes.size12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _introText(user).isEmpty
                            ? "자기소개가 아직 없습니다."
                            : _introText(user),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),

                  Gaps.v12(context),

                  // ───────────────── 해당 유저의 게시글 (무한 스크롤) ─────────────────
                  _UserPostsSection(
                    title: "${user.displayName} 님의 게시글",
                    repo: _postRepo,
                    authorUid: widget.targetUid,
                    authorGender: user.gender,
                  ),

                  Gaps.v24(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 라벨 + 칩
class LabeldRow extends StatelessWidget {
  final String label;
  final List<Widget> chips;
  final double labelWidth;

  const LabeldRow({
    super.key,
    required this.label,
    required this.chips,
    this.labelWidth = 88,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips.isEmpty
                  ? [Text("-", style: Theme.of(context).textTheme.bodySmall)]
                  : chips,
            ),
          ),
        ],
      ),
    );
  }
}

/// 상대 유저 게시글 리스트(상자 내부 무한 스크롤)
class _UserPostsSection extends StatefulWidget {
  final String title;
  final RoomOwnerPostRepository repo;
  final String authorUid;
  final String? authorGender;

  const _UserPostsSection({
    required this.title,
    required this.repo,
    required this.authorUid,
    this.authorGender,
  });

  @override
  State<_UserPostsSection> createState() => _UserPostsSectionState();
}

class _UserPostsSectionState extends State<_UserPostsSection> {
  final _scrollController = ScrollController();
  final List<RoomOwnerPost> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  // 권한 거부 상태 플래그(크래시 방지)
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });
    try {
      final result = await widget.repo.fetchUserPostsPaged(
        uid: widget.authorUid,
        authorGender: widget.authorGender,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length == 20;
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied') {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
          _hasMore = false;
        });
      } else {
        debugPrint('loadInitial error: ${e.code} ${e.message}');
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_permissionDenied) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final result = await widget.repo.fetchUserPostsPaged(
        uid: widget.authorUid,
        authorGender: widget.authorGender,
        lastItem: _lastDocument,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _posts.addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length == 20;
        _isLoadingMore = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied') {
        setState(() {
          _permissionDenied = true;
          _isLoadingMore = false;
          _hasMore = false;
        });
      } else {
        debugPrint('loadMore error: ${e.code} ${e.message}');
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _refresh() async {
    _lastDocument = null;
    _hasMore = true;
    _posts.clear();
    await _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final boxColor = Theme.of(context).primaryColor.withAlpha(15);
    final h = MediaQuery.of(context).size.height;
    final boxHeight = (h * 0.60).clamp(360.0, 680.0);

    final header = Row(
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: Sizes.size18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (!_isLoading && !_permissionDenied)
          Text(
            "${_posts.length}${_hasMore ? '+' : ''}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _refresh,
          tooltip: '새로고침',
        ),
      ],
    );

    Widget noAccess() => Container(
      height: boxHeight,
      alignment: Alignment.center,
      child: const Text(
        '성별 제한으로 이 사용자의 게시글 목록을 볼 수 없어요.',
        style: TextStyle(color: Colors.black54),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.size12,
        vertical: Sizes.size12,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).primaryColor.withAlpha(100),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveSizes.p(context, 18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Gaps.v8(context),
          // ⬇️ replace the SizedBox(...) inside _UserPostsSectionState.build()
          SizedBox(
            height: boxHeight,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _permissionDenied
                ? noAccess()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: GridView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: _posts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _posts.length) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        return _MiniOwnerPostTile(post: _posts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ⬇️ add this new tile widget (place it under _UserPostsSectionState)
class _MiniOwnerPostTile extends StatelessWidget {
  const _MiniOwnerPostTile({required this.post});
  final RoomOwnerPost post;

  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 1800; // 30분
  static final _supa = Supabase.instance.client;

  Future<String?> _firstSignedUrl() async {
    final paths = post.imageUrls ?? const <String>[];
    if (paths.isEmpty) return null;
    try {
      final url = await _supa.storage
          .from(_bucket)
          .createSignedUrl(paths.first, _urlTtl);
      return url.isEmpty ? null : url;
    } catch (_) {
      return null;
    }
  }

  String _addrShort() {
    final a = (post.roadAddress ?? '').trim();
    if (a.isEmpty) return '위치 비공개';
    return a.split('(').first.trim();
  }

  String _price1() {
    final d = post.deposit ?? 0;
    return '보증금 $d';
  }

  String _price2() {
    final r = post.rent ?? 0;
    final m = post.manageFee ?? 0;
    return m > 0 ? '월세 $r + 관 $m' : '월세 $r';
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomOwnerPostView(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double radius = 12;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Column(
          children: [
            Expanded(
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
                      width: double.infinity,
                    );
                  }
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/house.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    loadingBuilder: (c, w, p) => p == null
                        ? w
                        : const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(radius),
                ),
              ),
              child: const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _addrShort(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _price1(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF424242),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _price2(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF616161),
                      fontSize: 12,
                    ),
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
