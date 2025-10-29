// lib/features/view/room_owner_post_view.dart
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/features/chat/chat_screen.dart';
import 'package:roommate/features/post/room_owner_post_screen.dart';
import 'package:roommate/features/view/user_profile_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:roommate/features/navigationbar/screens/mypage_screen.dart';

// ➕
import 'package:roommate/class/post_snippet.dart';
import 'package:roommate/class/room_owner_post_repository.dart';

class RoomOwnerPostView extends StatefulWidget {
  final RoomOwnerPost post;

  const RoomOwnerPostView({
    super.key,
    required this.post,
  });

  @override
  State<RoomOwnerPostView> createState() => _RoomOwnerPostViewState();
}

class _RoomOwnerPostViewState extends State<RoomOwnerPostView> {
  final _userRepo = UserRepository();
  final _chatRepo = ChatRepository();
  final _postRepo = RoomOwnerPostRepository();

  late Future<AppUser?> _authorFuture;

  // Supabase
  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 3600; // 1h
  final _supabase = Supabase.instance.client;

  final _pageCtrl = PageController(viewportFraction: 1.0);
  int _currentPage = 0;
  bool _startingChat = false;

  // 🔹 로컬 상태로 관리(즉시 뱃지/버튼 반영)
  String? _status;

  bool get _isOwner {
    final me = FirebaseAuth.instance.currentUser;
    return me != null && widget.post.authorId == me.uid;
  }

  @override
  void initState() {
    super.initState();
    _status = widget.post.status?.toLowerCase(); // ✅ 이걸로 교체
    _authorFuture = (widget.post.authorId?.isNotEmpty ?? false)
        ? _userRepo.fetchUserById(widget.post.authorId!)
        : Future.value(null);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ======= Helpers: Data =======
  Future<List<String>> _signedUrls(List<String> paths) async {
    if (paths.isEmpty) return [];
    final urls = await Future.wait(
      paths.map(
        (p) => _supabase.storage.from(_bucket).createSignedUrl(p, _urlTtl),
      ),
    );
    return urls.where((u) => u.isNotEmpty).toList();
  }

  // ======= Helpers: UI building =======
  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(fontSize: Sizes.size20, fontWeight: FontWeight.bold),
  );

  Widget _infoRow(
    IconData icon,
    String title,
    String value, {
    bool valueRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.size8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: Sizes.size20, color: Colors.grey.shade600),
          Gaps.h16(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: Sizes.size16)),
                Gaps.v6(context),
                Align(
                  alignment: valueRight
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    value,
                    textAlign: valueRight ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: Sizes.size16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    if (!(_status == 'closed' || _status == 'matched'))
      return const SizedBox.shrink();
    final closed = _status == 'closed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: closed ? Colors.red.shade50 : Colors.green.shade50,
        border: Border.all(
          color: closed ? Colors.white : Colors.green.shade200,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        closed ? '마감됨' : '매칭완료',
        style: TextStyle(
          color: closed ? Colors.red.shade800 : Colors.green.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _titleAndBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Sizes.size20,
        Sizes.size16,
        Sizes.size20,
        Sizes.size8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              widget.post.title ?? '제목 없음',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Gaps.h8(context),
          _statusBadge(),
        ],
      ),
    );
  }

  Widget _imageHeader(List<String> imagePaths, String heroPrefix) {
    if (imagePaths.isEmpty) {
      // 기본 이미지(블러+원본)
      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Image.asset('assets/house.jpg', fit: BoxFit.cover),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset(
                'assets/house.jpg',
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      );
    }

    return FutureBuilder<List<String>>(
      future: _signedUrls(imagePaths),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final urls = snap.data!;
        if (urls.isEmpty) {
          return Image.asset('assets/house.jpg', fit: BoxFit.cover);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: urls.length,
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Image.network(
                      urls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Image.asset('assets/house.jpg', fit: BoxFit.cover),
                    ),
                  ),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: GestureDetector(
                        onTap: () => _openGallery(
                          urls: urls,
                          initialIndex: i,
                          heroPrefix: heroPrefix,
                        ),
                        child: Hero(
                          tag: '$heroPrefix$i',
                          child: Image.network(
                            urls[i],
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/house.jpg',
                              fit: BoxFit.contain,
                            ),
                            loadingBuilder: (c, w, p) => p == null
                                ? w
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 인디케이터
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  urls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        _currentPage == i ? 0.95 : 0.6,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ownerTile(Future<AppUser?> future) {
    return FutureBuilder<AppUser?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final author = snap.data;
        if (author == null) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person_off)),
            title: Text('작성자 정보 없음'),
          );
        }
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: author.photoURL != null
                ? NetworkImage(author.photoURL!)
                : null,
            child: author.photoURL == null ? const Icon(Icons.person) : null,
          ),
          title: Text(
            author.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('프로필 보기'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final uid = widget.post.authorId;
            if (uid == null || uid.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('작성자 UID를 찾을 수 없어요.')),
              );
              return;
            }

            final meUid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == meUid) {
              // ✅ 내 글이면 마이페이지로 바로 push
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MypageScreen(isBlocked: false),
                ),
              );
            } else {
              // ✅ 남의 글이면 상대 프로필로
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfileView(targetUid: uid),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _mapOrPlaceholder(double? lat, double? lng) {
    final hasAddr = (lat != null && lng != null);
    if (!hasAddr) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          '지도에 표시할 위치 정보가 없습니다.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Sizes.size10),
        child: GoogleMap(
          webGestureHandling: WebGestureHandling.greedy,
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: MarkerId('post_${widget.post.postId ?? 'unknown'}'),
              position: LatLng(lat, lng),
            ),
          },
          myLocationButtonEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
        ),
      ),
    );
  }

  // ======= Actions =======
  Future<void> _startChat() async {
    if (_startingChat) return;
    final me = FirebaseAuth.instance.currentUser;
    final partnerUid = widget.post.authorId ?? '';

    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }
    if (partnerUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작성자 정보를 확인할 수 없어요.')),
      );
      return;
    }
    if (partnerUid == me.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내가 올린 글입니다.')),
      );
      return;
    }

    setState(() => _startingChat = true);
    try {
      final partner = await _userRepo.fetchUserById(partnerUid);
      final partnerName = partner?.displayName ?? '상대방';

      // ✅ 결정적 roomId (문서 생성 X)
      final chatRoomId = ChatRepository.makeRoomId(me.uid, partnerUid);

      // ✅ 게시글 카드 1회 자동 공유(없으면 생성 + 메시지 기록)
      final firstImagePath =
          (widget.post.imageUrls ?? const <String>[]).isNotEmpty
          ? widget.post.imageUrls!.first
          : null;

      final snippet = PostSnippet(
        postId: widget.post.postId ?? '',
        title: widget.post.title ?? '',
        nearLabel: widget.post.getAddressLabel,
        deposit: widget.post.deposit,
        rent: widget.post.rent,
        manageFee: widget.post.manageFee,
        imagePath: firstImagePath, // Supabase 경로 그대로
      );

      await _chatRepo.sharePostOnce(chatRoomId, snippet);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoomId,
            partnerUid: partnerUid,
            partnerName: partnerName,
            // 이미 1회 공유했으므로 자동공유 비활성화
            postSnippet: snippet,
            autoSharePostOnFirstSend: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅 시작 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  void _goEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomOwnerPostScreen(postToEdit: widget.post),
      ),
    );
  }

  Future<void> _handleClose() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('마감하기'),
        content: const Text('이 게시글을 마감하여 피드/검색에서 숨길까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('마감'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _postRepo.closePost(widget.post.postId!);
      if (!mounted) return;
      setState(() => _status = 'closed');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글을 마감했어요.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('마감 실패: $e')));
    }
  }

  Future<void> _handleReopen() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('다시 열기'),
        content: const Text('이 게시글을 다시 열어 피드/검색에 노출할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('다시 열기'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _postRepo.updatePost(widget.post.postId!, {
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _status = 'open');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글을 다시 열었어요.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('다시 열기 실패: $e')));
    }
  }

  Future<void> _handleDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('완전 삭제'),
        content: const Text('정말 삭제하시겠어요? 삭제 후 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _postRepo.deletePost(widget.post.postId!);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글을 삭제했어요.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  void _openGallery({
    required List<String> urls,
    required int initialIndex,
    required String heroPrefix,
  }) {
    if (urls.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => FullscreenImageGallery(
          urls: urls,
          initialIndex: initialIndex,
          heroPrefix: heroPrefix,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ======= Build =======
  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern();
    final imagePaths = (widget.post.imageUrls ?? [])
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final lat = widget.post.coordinate?.latitude;
    final lng = widget.post.coordinate?.longitude;
    final nearLabel = widget.post.getAddressLabel;
    final heroPrefix = 'post_${widget.post.postId ?? 'unknown'}_img_';

    final isClosedOrMatched =
        _status == 'closed' || _status == 'matched' || _status == 'completed';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 헤더 이미지 + 상단 메뉴
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.black,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _imageHeader(imagePaths, heroPrefix),
            ),
            actions: [
              if (_isOwner)
                PopupMenuButton<String>(
                  color: Colors.white, // ✅ 메뉴 배경 흰색
                  itemBuilder: (c) => const [
                    PopupMenuItem(value: 'edit', child: Text('수정하기')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('완전 삭제'),
                    ),
                  ],
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        _goEdit();
                        break;
                      case 'delete':
                        _handleDelete();
                        break;
                    }
                  },
                ),
            ],
          ),

          // 제목 + 상태 뱃지
          SliverToBoxAdapter(child: _titleAndBadge()),

          // 본문
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자
                  _ownerTile(_authorFuture),
                  const Divider(height: Sizes.size40),

                  _sectionTitle("방 정보"),
                  Gaps.v16(context),
                  _infoRow(
                    Icons.location_on_outlined,
                    "위치",
                    nearLabel,
                    valueRight: true,
                  ),
                  _infoRow(
                    Icons.attach_money_outlined,
                    "금액",
                    () {
                      final d = numberFormat.format(widget.post.deposit ?? 0);
                      final r = numberFormat.format(widget.post.rent ?? 0);
                      final m = numberFormat.format(widget.post.manageFee ?? 0);
                      final parts = <String>["보증금 $d만", "월세 $r만"];
                      if ((widget.post.manageFee ?? 0) > 0)
                        parts.add("관리비 $m만");
                      return parts.join(" · ");
                    }(),
                    valueRight: true,
                  ),
                  _infoRow(
                    Icons.stairs_outlined,
                    "층수",
                    "${widget.post.corFloor ?? '-'}층 / ${widget.post.wholeFloor ?? '-'}층",
                    valueRight: true,
                  ),
                  _infoRow(
                    Icons.square_foot_outlined,
                    "전용 면적",
                    "${widget.post.area ?? '-'}평",
                    valueRight: true,
                  ),
                  _infoRow(
                    Icons.bathtub_outlined,
                    "화장실 개수",
                    "${widget.post.toilet ?? '-'}개",
                    valueRight: true,
                  ),

                  const Divider(height: Sizes.size40),
                  _sectionTitle("계약 정보"),
                  Gaps.v16(context),
                  _infoRow(
                    Icons.event_available_outlined,
                    "입주 가능일",
                    widget.post.movingDate != null
                        ? DateFormat(
                            'yyyy년 MM월 dd일',
                          ).format(widget.post.movingDate!.toDate())
                        : "정보 없음",
                    valueRight: true,
                  ),
                  _infoRow(
                    Icons.article_outlined,
                    "계약 기간",
                    "${widget.post.minContract ?? '-'}개월 ~ ${widget.post.maxContract ?? '-'}개월",
                    valueRight: true,
                  ),

                  const Divider(height: Sizes.size40),
                  _sectionTitle("소개글"),
                  Gaps.v16(context),
                  Text(
                    widget.post.introduction ?? '작성된 소개글이 없습니다.',
                    style: const TextStyle(fontSize: Sizes.size16, height: 1.5),
                  ),
                  Gaps.v20(context),
                ],
              ),
            ),
          ),

          // 지도
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.size20,
                0,
                Sizes.size20,
                Sizes.size20,
              ),
              child: _mapOrPlaceholder(lat, lng),
            ),
          ),
        ],
      ),

      // 하단 버튼 (divider 제거, 오너인 경우에도 한 줄짜리 긴 버튼만)
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Sizes.size6,
            horizontal: Sizes.size20,
          ),
          child: _isOwner
              ? ElevatedButton(
                  onPressed: isClosedOrMatched ? _handleReopen : _handleClose,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: Sizes.size8),
                    backgroundColor: isClosedOrMatched
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade100,
                    foregroundColor: isClosedOrMatched
                        ? Colors.white
                        : Colors.black87,
                  ),
                  child: Text(
                    isClosedOrMatched ? '다시 열기' : '마감하기',
                    style: const TextStyle(
                      fontSize: Sizes.size18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _startingChat ? null : _startChat,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: Sizes.size8),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _startingChat ? '연결 중...' : '채팅으로 연락하기',
                    style: const TextStyle(
                      fontSize: Sizes.size18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ========= FullscreenImageGallery =========

class FullscreenImageGallery extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String heroPrefix;

  const FullscreenImageGallery({
    super.key,
    required this.urls,
    required this.initialIndex,
    required this.heroPrefix,
  });

  @override
  State<FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<FullscreenImageGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.urls.length,
            itemBuilder: (context, i) {
              final url = widget.urls[i];
              return Center(
                child: Hero(
                  tag: '${widget.heroPrefix}$i',
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 64,
                      ),
                      loadingBuilder: (c, w, p) =>
                          p == null ? w : const CircularProgressIndicator(),
                    ),
                  ),
                ),
              );
            },
          ),

          // 상단 그라데이션
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.25],
                  ),
                ),
              ),
            ),
          ),

          // 닫기 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Sizes.size10,
                  right: Sizes.size10,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.9),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _close,
                    icon: const Icon(Icons.close_rounded),
                    color: primary,
                    tooltip: '닫기',
                  ),
                ),
              ),
            ),
          ),

          // 하단 인덱스
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_index + 1} / ${widget.urls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
