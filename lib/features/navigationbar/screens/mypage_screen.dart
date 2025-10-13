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
import 'package:roommate/features/authentication/login/login_screen.dart';
import 'package:roommate/features/authentication/userinfo/hobby_screen.dart';
import 'package:roommate/features/authentication/userinfo/userjob_screen.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/navigationbar/widgets/accordion_widget.dart';
import 'package:roommate/features/navigationbar/widgets/chip_button.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/features/category/coliving_screen.dart';
import 'package:roommate/features/category/disease_screen.dart';
import 'package:roommate/features/category/introduction_screen.dart';

// ⬇️ 상세 보기로 진입하기 위해 추가
import 'package:roommate/features/view/room_owner_post_view.dart';
// ⬇️ 썸네일 서명 URL 생성
import 'package:supabase_flutter/supabase_flutter.dart';

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
      useRootNavigator: true, // ✅ 루트 네비게이터에 붙여서 플랫폼뷰 충돌 감소
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveSizes.p(context, 25)),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveSizes.p(context, 16),
              ResponsiveSizes.p(context, 16),
              ResponsiveSizes.p(context, 16),
              ResponsiveSizes.p(context, 20),
            ),
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
                Gaps.v3(context),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _getPhotoLibraryImage();
                  },
                  child: const Text('라이브러리에서 불러오기'),
                ),
                Gaps.v3(context),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _getBasicProfile();
                  },
                  child: const Text('기본 프로필로 설정'),
                ),
                Divider(
                  height: ResponsiveSizes.p(context, 24),
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

        // ✅ 더 읽기 좋은 변수명
        final userDailyRhythm = me.dailyRhythm ?? me.dailyRhythm;
        final colivingPreference = me.coliving ?? me.coliving;
        final userTypeInfo = me.userType ?? me.userType;
        final userHobby = me.hobby ?? me.hobby;

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent, // ← 틴트 제거
            foregroundColor: Colors.black, // ← 아이콘/텍스트 대비
            toolbarHeight: ResponsiveSizes.p(context, 40),
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
            parentContext: context, // ✅ 부모(Scaffold) 컨텍스트 전달
          ),

          body: Padding(
            padding: EdgeInsets.all(ResponsiveSizes.p(context, 12)),
            child: StreamBuilder<bool>(
              stream: _repo.watchUserPassStatus(),
              builder: (context, lockSnap) {
                final isLocked = !(lockSnap.data ?? false);

                return Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Gaps.v12(context),
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: ResponsiveSizes.p(context, 60),
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                                child: _profileImage == null
                                    ? Icon(
                                        Icons.person,
                                        size: ResponsiveSizes.p(context, 48),
                                        color: Colors.grey.shade600,
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: FloatingActionButton.small(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  heroTag: 'editAvatar',
                                  onPressed: _showBottomSheet,
                                  child: const Icon(Icons.photo_camera),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Gaps.v2(context),
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
                                    labelWidth: 140,
                                    label: "공용공간 사용 선호도",
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
                                    labelWidth: 140,
                                    label: "화장실 청결 민감도",
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
                                    label: "MBTI",
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
                                    label: "반려동물",
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
                                    label: "흡연",
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
                                    label: "유저타입",
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
                                    label: "최애 음식",
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
                                    label: "요즘 관심사",
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
                                    label: "운동",
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

                            Gaps.v16(context),

                            // ✅ 내가 쓴 글: 3열 그리드 (무한 스크롤 유지)
                            _MyPostsSection(
                              title: "내가 쓴 글",
                              repo: _postRepo,
                              currentUid: me.uid,
                            ),

                            Gaps.v24(context),
                          ],
                        ),
                      ],
                    ),

                    // 🔒 락 오버레이
                    if (isLocked)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.85),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: ResponsiveSizes.p(context, 56),
                                color: Colors.black54,
                              ),
                              SizedBox(height: ResponsiveSizes.p(context, 12)),
                              Text(
                                '추가 정보를 입력하면 사용 가능해요',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: ResponsiveSizes.p(context, 12)),
                              FilledButton(
                                onPressed: _onNextTap,
                                child: const Text('정보 입력하기'),
                              ),
                            ],
                          ),
                        ),
                      ),
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
  final BuildContext parentContext; // ✅ 상위(Scaffold) 컨텍스트

  const _MyPageEndDrawer({
    required this.displayName,
    required this.email,
    required this.onOpenProfileSheet,
    required this.onSignOut,
    required this.parentContext, // ✅ 주입
  });

  void _openEditPicker(BuildContext parentContext) {
    final pad = ResponsiveSizes.p(parentContext, 16);

    showModalBottomSheet<void>(
      context: parentContext,
      useRootNavigator: true, // ✅ 루트 네비게이터
      useSafeArea: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveSizes.p(parentContext, 20)),
        ),
      ),
      builder: (sheetCtx) {
        // ✅ 매개변수 이름을 screenFactory로 변경
        Widget tile({
          required IconData icon,
          required String title,
          String? subtitle,
          required Widget Function() screenFactory,
        }) {
          return ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 1) 먼저 시트 닫기
              Navigator.pop(sheetCtx);

              // 2) 다음 프레임에서 안전하게 push (루트 네비게이터)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(parentContext, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => screenFactory()),
                );
              });
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pad,
              pad,
              pad,
              pad + ResponsiveSizes.p(parentContext, 6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile(
                  icon: Icons.badge_rounded,
                  title: '직업/학교',
                  screenFactory: () => const UserjobScreen(),
                ),
                tile(
                  icon: Icons.sports_esports_rounded,
                  title: '취미',
                  screenFactory: () => const HobbyScreen(),
                ),
                tile(
                  icon: Icons.people_alt_rounded,
                  title: '공동 생활 성향',
                  screenFactory: () => const ColivingScreen(),
                ),
                tile(
                  icon: Icons.schedule_rounded,
                  title: '생활 패턴',
                  screenFactory: () => const DailyRhythmScreen(),
                ),
                tile(
                  icon: Icons.healing_rounded,
                  title: '질병/알레르기',
                  screenFactory: () => const DiseaseScreen(),
                ),
                tile(
                  icon: Icons.short_text_rounded,
                  title: '자기소개',
                  screenFactory: () => const IntroductionScreen(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                // ✅ 다음 프레임에 부모컨텍스트로 시트 오픈
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onOpenProfileSheet();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('내 정보 수정'),
              onTap: () {
                Navigator.pop(context); // 드로어 먼저 닫고
                // ✅ 다음 프레임에 부모(Scaffold) 컨텍스트로 바텀시트 오픈
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _openEditPicker(parentContext);
                });
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
      padding: EdgeInsets.only(bottom: ResponsiveSizes.p(context, 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: ResponsiveSizes.p(context, labelWidth),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Gaps.h8(context),
          Expanded(
            child: Wrap(
              spacing: ResponsiveSizes.p(context, 6),
              runSpacing: ResponsiveSizes.p(context, 6),
              children: chips,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- 내가 쓴 글 (3열 그리드 + 무한 스크롤) --------------------

class _MyPostsSection extends StatefulWidget {
  final String title;
  final RoomOwnerPostRepository repo;
  final String currentUid;

  const _MyPostsSection({
    super.key,
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
    final radius = ResponsiveSizes.p(context, 18);
    final h = MediaQuery.of(context).size.height;
    final boxHeight = (h * 0.60).clamp(
      ResponsiveSizes.p(context, 360),
      ResponsiveSizes.p(context, 720),
    );

    final header = Row(
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: ResponsiveSizes.f(context, 18),
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

    final grid = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RepaintBoundary(
            // ✅ 스크롤 중 불필요한 리페인트 줄이기
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // ← 3열
                mainAxisSpacing: ResponsiveSizes.p(context, 8),
                crossAxisSpacing: ResponsiveSizes.p(context, 8),
                childAspectRatio: 0.78, // 이미지를 크게, 아래 텍스트 살짝
              ),
              itemCount: _posts.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _posts.length) {
                  // 로딩 셀
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return _MiniPostTile(post: _posts[index]);
              },
            ),
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSizes.p(context, 12),
        vertical: ResponsiveSizes.p(context, 12),
      ),
      decoration: BoxDecoration(
        border: BoxBorder.all(
          color: Theme.of(context).primaryColor.withAlpha(100),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      // ✅ 자식(그리드) 클리핑으로 잔상/넘침 방지
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Gaps.v8(context),
          SizedBox(height: boxHeight, child: grid),
        ],
      ),
    );
  }
}

/// 3열 그리드용 미니 타일 (썸네일 + 간단 정보)
class _MiniPostTile extends StatelessWidget {
  _MiniPostTile({required this.post});

  final RoomOwnerPost post;

  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 1800; // 30분
  final _supa = Supabase.instance.client;

  Future<String?> _firstSignedUrl() async {
    final paths = post.imageUrls ?? const <String>[];
    if (paths.isEmpty) return null;
    try {
      final url = await _supa.storage
          .from(_bucket)
          .createSignedUrl(paths.first, _urlTtl);
      if (url.isEmpty) return null;
      return url;
    } catch (_) {
      return null;
    }
  }

  String _price1() {
    final d = post.deposit ?? 0;
    return '보증금 $d만';
  }

  String _price2() {
    final r = post.rent ?? 0;
    final m = post.manageFee ?? 0;
    return m > 0 ? '월세 $r만 + 관 $m만' : '월세 $r만';
  }

  String _addrShort() {
    final a = (post.addressLabel ?? '').trim();
    if (a.isEmpty) return '위치 비공개';
    return a.split('(').first.trim();
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomOwnerPostView(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveSizes.p(context, 12);

    return Card(
      elevation: 0, // ✅ Material 그림자(스크롤 잔상 방지에 유리)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias, // ✅ 라운드 영역 밖으로 그림 그리지 않음
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Column(
          children: [
            // 썸네일(위쪽 라운드)
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

            // ⬇️ 텍스트 영역만 흰색 + 아래 라운드
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, // ✅ 사진 아래 영역만 흰색
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(radius),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveSizes.p(context, 8),
                  ResponsiveSizes.p(context, 8),
                  ResponsiveSizes.p(context, 8),
                  ResponsiveSizes.p(context, 10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 주소 (최대 1줄)
                    Text(
                      _addrShort(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 4)),
                    Text(
                      _price1(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 2)),
                    Text(
                      _price2(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
