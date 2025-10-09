// 샤라웃 투 https://github.com/youngsoonoh/youtube_profile/tree/example1 오용순
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';

import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/navigationbar/widgets/accordion_widget.dart';
import 'package:roommate/features/navigationbar/widgets/chip_button.dart';
import 'package:roommate/features/navigationbar/widgets/room_owner_post_container.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key, required this.isBlocked});
  final bool isBlocked;

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _repo = UserRepository();
  final _postRepo = RoomOwnerPostRepository();

  File? _profileImage;

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

  void _onNextTap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DailyRhythmScreen()),
    );
  }

  Future<AppUser?> _getMyData() async => _repo.fetchMe();

  // -------------------- 이미지 처리 --------------------
  Future<void> _getPhotoLibraryImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _profileImage = File(picked.path));
  }

  Future<void> _getCameraImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _profileImage = File(picked.path));
  }

  Future<void> _getBasicProfile() async {
    if (!mounted) return;
    setState(() => _profileImage = null);
  }

  Future<void> _showBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _getCameraImage();
                  },
                  child: const Text('사진 찍기'),
                ),
                const SizedBox(height: Sizes.size3),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _getPhotoLibraryImage();
                  },
                  child: const Text('라이브러리에서 불러오기'),
                ),
                const SizedBox(height: Sizes.size3),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _getBasicProfile();
                  },
                  child: const Text('기본 프로필로 설정'),
                ),
                const Divider(
                  height: 24,
                  thickness: 0,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------- 계정 --------------------
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _getMyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("데이터가 없습니다.")));
        }
        final me = snapshot.data!;

        // ✅ 더 읽기 좋은 변수명으로 변경 (userPass → 상위 필드 폴백)
        final userDailyRhythm = me.dailyRhythm ?? me.dailyRhythm;
        final colivingPreference = me.coliving ?? me.coliving;
        final userTypeInfo = me.userType ?? me.userType;
        final userHobby = me.hobby ?? me.hobby;

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            toolbarHeight: Sizes.size40,
            title: const Text('마이페이지'),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),

          endDrawer: _MyPageEndDrawer(
            displayName: me.displayName,
            email: me.email ?? '',
            onOpenProfileSheet: _showBottomSheet,
            onSignOut: _signOut,
          ),

          body: Padding(
            padding: const EdgeInsets.all(Sizes.size12),
            child: StreamBuilder<bool>(
              stream: _repo.watchUserPassStatus(),
              builder: (context, lockSnap) {
                final isLocked = !(lockSnap.data ?? false);

                return Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                                child: _profileImage == null
                                    ? Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Colors.grey.shade600,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 100,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      me.displayName,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(userTypeInfo?.type ?? '-'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Divider(
                          height: 1,
                          color: Theme.of(context).primaryColor.withAlpha(100),
                        ),

                        // 본문
                        Column(
                          children: [
                            // 생활 패턴
                            AccordionWidget(
                              title: " 내 생활패턴",
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
                                      if (userDailyRhythm?.weekAwakeMins !=
                                          null)
                                        ChipButton(
                                          text:
                                              "기상 ${_fmtHm(userDailyRhythm!.weekAwakeMins)}",
                                          isSelected: true,
                                        ),
                                      if (userDailyRhythm?.weekSleepMins !=
                                          null)
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

                            // 공동 생활 성향
                            AccordionWidget(
                              title: " 내 공동 생활 성향",
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LabeldRow(
                                    label: "공용공간 사용 선호도 :",
                                    chips: [
                                      if ((colivingPreference?.coSpace ?? '')
                                          .isNotEmpty)
                                        ChipButton(
                                          text: colivingPreference!.coSpace,
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                  LabeldRow(
                                    label: "화장실 청결 민감도 : ",
                                    chips: [
                                      if ((colivingPreference?.bathroom ?? '')
                                          .isNotEmpty)
                                        ChipButton(
                                          text: colivingPreference!.bathroom,
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                  LabeldRow(
                                    label: "MBTI : ",
                                    chips: [
                                      if ((colivingPreference?.mbti ?? '')
                                          .isNotEmpty)
                                        ChipButton(
                                          text: colivingPreference!.mbti,
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                  LabeldRow(
                                    label: "반려동물 : ",
                                    chips:
                                        (colivingPreference?.pet ??
                                                const <String>[])
                                            .map(
                                              (pet) => ChipButton(
                                                text: pet,
                                                isSelected: true,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  LabeldRow(
                                    label: "흡연 : ",
                                    chips: [
                                      if (colivingPreference?.smoking != null)
                                        ChipButton(
                                          text: colivingPreference!.smoking
                                              ? '흡연'
                                              : '비흡연',
                                          isSelected: true,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 유저 타입
                            AccordionWidget(
                              title: " 내 유저타입",
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LabeldRow(
                                    label: "유저타입 :",
                                    chips: [
                                      ChipButton(
                                        text:
                                            (userTypeInfo?.type == "roomOwner")
                                            ? "RoomOwner"
                                            : "Searcher",
                                        isSelected: true,
                                      ),
                                    ],
                                  ),
                                  if (userTypeInfo?.type == "roomOwner")
                                    LabeldRow(
                                      label: "주소",
                                      chips: [
                                        ChipButton(
                                          text:
                                              (userTypeInfo?.address ?? '주소 없음')
                                                  .split('(')
                                                  .first
                                                  .trim(),
                                          isSelected: true,
                                        ),
                                      ],
                                    )
                                  else
                                    LabeldRow(
                                      label: "선호 지역 : ",
                                      chips:
                                          (userTypeInfo?.searchAreas ??
                                                  const <String>[])
                                              .map(
                                                (areaName) => ChipButton(
                                                  text: areaName,
                                                  isSelected: true,
                                                ),
                                              )
                                              .toList(),
                                    ),
                                ],
                              ),
                            ),

                            // 취미
                            AccordionWidget(
                              title: " 내 취미",
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LabeldRow(
                                    label: "최애 음식 :",
                                    chips:
                                        (userHobby?.foodLike ??
                                                const <String>[])
                                            .map(
                                              (food) => ChipButton(
                                                text: food,
                                                isSelected: true,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  LabeldRow(
                                    label: "요즘 관심사 :",
                                    chips:
                                        (userHobby?.interestLike ??
                                                const <String>[])
                                            .map(
                                              (interest) => ChipButton(
                                                text: interest,
                                                isSelected: true,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  LabeldRow(
                                    label: "운동 :",
                                    chips:
                                        (userHobby?.sportLike ??
                                                const <String>[])
                                            .map(
                                              (sport) => ChipButton(
                                                text: sport,
                                                isSelected: true,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              ),
                            ),

                            Gaps.v16,

                            // ✅ 내가 만든 쿠키~ : 상자 내부에서 전체 스크롤(페이지네이션)
                            _MyPostsSection(
                              title: "내가 만든 쿠키~",
                              repo: _postRepo,
                              currentUid: me.uid, // ← 안전
                            ),

                            Gaps.v24,
                          ],
                        ),
                      ],
                    ),

                    // 🔒 락 오버레이
                    if (isLocked) ...[
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.white],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _onNextTap,
                                child: const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Icon(
                                    Icons.lock_open_rounded,
                                    color: Colors.black54,
                                    size: 48,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "추가적인 유저 정보를 입력하면\n 사용하실수 있습니다.\n자물쇠를 줄러주세요.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// -------------------- Drawer --------------------

class _MyPageEndDrawer extends StatelessWidget {
  final String displayName;
  final String email;
  final VoidCallback onOpenProfileSheet;
  final VoidCallback onSignOut;

  const _MyPageEndDrawer({
    required this.displayName,
    required this.email,
    required this.onOpenProfileSheet,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                child: Text((displayName.isNotEmpty ? displayName[0] : '?')),
              ),
              accountName: Text(displayName),
              accountEmail: Text(email),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('프로필 사진 변경'),
              onTap: () {
                Navigator.pop(context);
                onOpenProfileSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('내 정보 수정'),
              onTap: () {
                Navigator.pop(context);
                // TODO
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('설정'),
              onTap: () {
                Navigator.pop(context);
                // TODO
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {
                Navigator.pop(context);
                onSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- 라벨 + 칩 --------------------

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
          Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: chips)),
        ],
      ),
    );
  }
}

// -------------------- 내가 만든 쿠키~ (상자 내부 무한 스크롤) --------------------

class _MyPostsSection extends StatefulWidget {
  final String title;
  final RoomOwnerPostRepository repo;
  final String currentUid;

  const _MyPostsSection({
    required this.title,
    required this.repo,
    required this.currentUid,
  });

  @override
  State<_MyPostsSection> createState() => _MyPostsSectionState();
}

class _MyPostsSectionState extends State<_MyPostsSection> {
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
      uid: widget.currentUid,
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
      uid: widget.currentUid,
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
    final boxColor = Theme.of(context).primaryColor.withValues(alpha: 0.06);
    final h = MediaQuery.of(context).size.height;
    final boxHeight = (h * 0.60).clamp(360.0, 680.0); // 화면에 어울리는 높이

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
          Gaps.v8,
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
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
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
