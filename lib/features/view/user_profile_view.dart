import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';

import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/widgets/accordion_widget.dart';
import 'package:roommate/features/navigationbar/widgets/chip_button.dart';
import 'package:roommate/features/navigationbar/widgets/room_owner_post_container.dart';
import 'package:roommate/features/view/widget/appbar_chip.dart';

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

  bool _looksStudent(AppUser u) {
    final jk = u.userType?.jobKinds.toLowerCase() ?? "";
    return jk.contains("대학생") || jk.contains("학생") || jk.contains("student");
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
        final isPass = (user.userPass?.pass ?? false);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              "${user.displayName}의 프로필",
              style: const TextStyle(fontSize: Sizes.size24),
            ),
            actions: [
              if (isPass) const AppbarChip(text: 'PASS 인증', color: Colors.red),
              if (_looksStudent(user)) ...[
                Gaps.h4(context),
                const AppbarChip(text: '대학생 인증', color: Colors.green),
              ],
            ],
            actionsPadding: const EdgeInsets.only(right: Sizes.size8),
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
                        user.displayName,
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

                  // ───────────────── 하루 리듬 (마이페이지와 동일 필드만) ─────────────────
                  AccordionWidget(
                    title: " 하루 리듬",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeldRow(
                          label: "출근일 :",
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
                        // ✅ 주말/알람은 현재 모델에 없을 수 있으므로 제외 (마이페이지와 동일하게)
                      ],
                    ),
                  ),

                  // ───────────────── 공동 생활 성향 ─────────────────
                  AccordionWidget(
                    title: " 공동 생활 성향",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeldRow(
                          label: "공용공간 :",
                          chips: [
                            if ((colivingPreference?.coSpace ?? '').isNotEmpty)
                              ChipButton(
                                text: colivingPreference!.coSpace,
                                isSelected: true,
                              ),
                          ],
                        ),
                        LabeldRow(
                          label: "화장실 :",
                          chips: [
                            if ((colivingPreference?.bathroom ?? '').isNotEmpty)
                              ChipButton(
                                text: colivingPreference!.bathroom,
                                isSelected: true,
                              ),
                          ],
                        ),
                        LabeldRow(
                          label: "MBTI :",
                          chips: [
                            if ((colivingPreference?.mbti ?? '').isNotEmpty)
                              ChipButton(
                                text: colivingPreference!.mbti,
                                isSelected: true,
                              ),
                          ],
                        ),
                        LabeldRow(
                          label: "반려동물 :",
                          chips: (colivingPreference?.pet ?? const <String>[])
                              .map((e) => ChipButton(text: e, isSelected: true))
                              .toList(),
                        ),
                        LabeldRow(
                          label: "흡연 :",
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

                  // ───────────────── 유저 타입 ─────────────────
                  AccordionWidget(
                    title: " 유저 타입",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeldRow(
                          label: "유형 :",
                          chips: [
                            ChipButton(
                              text: (userTypeInfo?.type == "roomOwner")
                                  ? "RoomOwner"
                                  : "Searcher",
                              isSelected: true,
                            ),
                          ],
                        ),
                        if (userTypeInfo?.type == "roomOwner")
                          LabeldRow(
                            label: "주소 :",
                            chips: [
                              ChipButton(
                                text: (userTypeInfo?.address ?? '주소 없음')
                                    .split('(')
                                    .first
                                    .trim(),
                                isSelected: true,
                              ),
                            ],
                          )
                        else
                          LabeldRow(
                            label: "선호 지역 :",
                            chips:
                                (userTypeInfo?.searchAreas ?? const <String>[])
                                    .map(
                                      (a) =>
                                          ChipButton(text: a, isSelected: true),
                                    )
                                    .toList(),
                          ),
                      ],
                    ),
                  ),

                  // ───────────────── 취미 ─────────────────
                  AccordionWidget(
                    title: " 취미/관심",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeldRow(
                          label: "최애 음식 :",
                          chips: (userHobby?.foodLike ?? const <String>[])
                              .map((e) => ChipButton(text: e, isSelected: true))
                              .toList(),
                        ),
                        LabeldRow(
                          label: "관심사 :",
                          chips: (userHobby?.interestLike ?? const <String>[])
                              .map((e) => ChipButton(text: e, isSelected: true))
                              .toList(),
                        ),
                        LabeldRow(
                          label: "운동 :",
                          chips: (userHobby?.sportLike ?? const <String>[])
                              .map((e) => ChipButton(text: e, isSelected: true))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // ───────────────── 자기소개 ─────────────────
                  AccordionWidget(
                    title: " 자기소개",
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

/// 라벨 + 칩 (마이페이지와 동일 스타일)
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

  const _UserPostsSection({
    required this.title,
    required this.repo,
    required this.authorUid,
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
    setState(() => _isLoading = true);
    final result = await widget.repo.fetchUserPostsPaged(
      uid: widget.authorUid,
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
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final result = await widget.repo.fetchUserPostsPaged(
      uid: widget.authorUid,
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
        if (!_isLoading)
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.size12,
        vertical: Sizes.size12,
      ),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Gaps.v8(context),
          SizedBox(
            height: boxHeight,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _posts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _posts.length) {
                          return _isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        return RoomOwnerPostContainer(post: _posts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
