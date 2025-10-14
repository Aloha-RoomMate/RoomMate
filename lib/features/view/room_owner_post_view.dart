// features/view/room_owner_post_view.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/features/chat/chat_screen.dart';
import 'package:roommate/features/post/room_owner_post_screen.dart';
import 'package:roommate/features/view/user_profile_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final UserRepository _userRepository = UserRepository();
  final ChatRepository _chatRepo = ChatRepository();
  late Future<AppUser?> _authorFuture;
  bool _startingChat = false;

  // Supabase (Private 버킷 → 서명 URL 필요)
  static const String _bucket = 'RoomMate-image';
  static const int _urlTtl = 3600; // 1시간
  final _supabase = Supabase.instance.client;

  // 이미지 슬라이더
  final PageController _pageCtrl = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  bool get _isOwner {
    final me = FirebaseAuth.instance.currentUser;
    return me != null && widget.post.authorId == me.uid;
  }

  @override
  void initState() {
    super.initState();
    if (widget.post.authorId != null && widget.post.authorId!.isNotEmpty) {
      _authorFuture = _userRepository.fetchUserById(widget.post.authorId!);
    } else {
      _authorFuture = Future.value(null);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<List<String>> _signedUrls(List<String> paths) async {
    if (paths.isEmpty) return [];
    final res = await _supabase.storage
        .from(_bucket)
        .createSignedUrls(paths, _urlTtl);
    return res.map((e) => e.signedUrl).toList();
  }

  /// 제목 아래로 값이 감싸지며 내려가는 스택형 정보 행
  Widget _buildInfoRow(
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

  // ───────────── “부근” 보정 로직 (풀주소 노출 방지) ─────────────
  String _dongOnly(String? full) {
    final s = (full ?? '').trim();
    if (s.isEmpty) return '';

    // 끝의 '부근' 표기 제거 후 처리
    final cleaned = s.replaceAll(RegExp(r'\s*부근$'), '');
    final tokens = cleaned.split(RegExp(r'\s+'));

    String pick(String suffix) =>
        tokens.firstWhere((e) => e.endsWith(suffix), orElse: () => '');

    // 우선순위: 동 > 읍 > 면 > 리 > 가 > 구
    final d = pick('동');
    final eup = pick('읍');
    final myeon = pick('면');
    final ri = pick('리');
    final ga = pick('가');
    final gu = pick('구');

    final cand = [d, eup, myeon, ri, ga, gu].firstWhere(
      (e) => e.isNotEmpty,
      orElse: () => '',
    );

    if (cand.isNotEmpty) return cand;

    // 역명(강남역 등)
    final st = RegExp(r'([가-힣A-Za-z0-9]+역)\b').firstMatch(cleaned)?.group(1);
    if (st != null && st.isNotEmpty) return st;

    // 도로명(…로/…대로/…길)
    final road = RegExp(
      r'([가-힣A-Za-z0-9]+(?:로|대로|길))',
    ).firstMatch(cleaned)?.group(1);
    if (road != null && road.isNotEmpty) return road;

    // 그 외: 첫 토큰
    return tokens.first;
  }

  String _labelWithNear(String? labelOrText) {
    final base = (labelOrText ?? '').trim();
    if (base.isEmpty) return '부근';
    if (RegExp(r'부근$').hasMatch(base)) return base; // 이미 '부근'이면 그대로
    final pick = _dongOnly(base);
    if (pick.isEmpty) return '부근';
    return '$pick 부근';
  }
  // ─────────────────────────────────────────────────────

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
      final partner = await _userRepository.fetchUserById(partnerUid);
      final partnerName = partner?.displayName ?? '상대방';
      final chatRoomId = await _chatRepo.createChatRoom(me.uid, partnerUid);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoomId,
            partnerUid: partnerUid,
            partnerName: partnerName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅 시작에 실패했어요: $e')),
      );
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  void _goEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomOwnerPostScreen(
          postToEdit: widget.post,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern();

    final hasAddr = widget.post.coordinate != null;
    final double? lat = widget.post.coordinate?.latitude;
    final double? lng = widget.post.coordinate?.longitude;

    // Firestore의 imageUrls(= Storage 경로 배열)
    final List<String> imagePaths = (widget.post.imageUrls ?? [])
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.toString())
        .toList();

    // “철산동 부근” 등으로 보정된 표시용 라벨
    final nearLabel = _labelWithNear(widget.post.addressLabel);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 상단 이미지 슬라이더 (제목 오버레이 제거)
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.black,
            elevation: 0,
            // RoomOwnerPostView 의 SliverAppBar.flexibleSpace 교체
            flexibleSpace: FlexibleSpaceBar(
              background: imagePaths.isEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // 배경: 기본 이미지를 cover + blur로 꽉 채우기
                        ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 16,
                            sigmaY: 16,
                          ),
                          child: Image.asset(
                            'assets/house.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        // 상단 그라데이션(선택)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.center,
                                  colors: [Colors.black12, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 전경: 원본을 contain으로 중앙에
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
                    )
                  : FutureBuilder<List<String>>(
                      future: _signedUrls(imagePaths),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final urls = snap.data!;
                        if (urls.isEmpty) {
                          return Image.asset(
                            'assets/house.jpg',
                            fit: BoxFit.cover,
                          );
                        }
                        // 한 페이지만 그릴 때마다 배경+전경을 같이 쌓아서 동기화
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              controller: _pageCtrl,
                              onPageChanged: (i) =>
                                  setState(() => _currentPage = i),
                              itemCount: urls.length,
                              itemBuilder: (_, i) => Stack(
                                fit: StackFit.expand,
                                children: [
                                  // 배경: 같은 이미지를 cover + blur 로 꽉 채우기
                                  ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(
                                      sigmaX: 16,
                                      sigmaY: 16,
                                    ),
                                    child: Image.network(
                                      urls[i],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/house.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // 상단 그라데이션(선택)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.center,
                                            colors: [
                                              Colors.black12,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 전경: 원본을 contain으로 중앙에 (안 잘림)
                                  Center(
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Image.network(
                                        urls[i],
                                        filterQuality: FilterQuality.high,
                                        errorBuilder: (_, __, ___) =>
                                            Image.asset(
                                              'assets/house.jpg',
                                              fit: BoxFit.contain,
                                            ),
                                        loadingBuilder: (c, w, p) => p == null
                                            ? w
                                            : const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 기존 하단 도트 인디케이터 유지
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
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
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
                    ),
            ),
          ),

          // 이미지 아래 헤더(제목만)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.size20,
                Sizes.size16,
                Sizes.size20,
                Sizes.size8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title ?? '제목 없음',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // 본문
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자
                  FutureBuilder<AppUser?>(
                    future: _authorFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person_off)),
                          title: Text('작성자 정보 없음'),
                        );
                      }
                      final author = snapshot.data!;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: author.photoURL != null
                              ? NetworkImage(author.photoURL!)
                              : null,
                          child: author.photoURL == null
                              ? const Icon(Icons.person)
                              : null,
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
                              const SnackBar(
                                content: Text('작성자 UID를 찾을 수 없어요.'),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserProfileView(targetUid: uid),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: Sizes.size40),

                  const Text(
                    "방 정보",
                    style: TextStyle(
                      fontSize: Sizes.size20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gaps.v16(context),

                  // 위치: 반드시 “… 부근”으로 표기
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    "위치",
                    nearLabel,
                  ),

                  // 금액: 한 줄에 정리 (관리비가 0이면 생략)
                  _buildInfoRow(
                    Icons.attach_money_outlined,
                    "금액",
                    () {
                      final d = numberFormat.format(widget.post.deposit ?? 0);
                      final r = numberFormat.format(widget.post.rent ?? 0);
                      final m = numberFormat.format(widget.post.manageFee ?? 0);
                      final parts = <String>["보증금 $d만", "월세 $r만"];
                      if ((widget.post.manageFee ?? 0) > 0) {
                        parts.add("관리비 $m만");
                      }
                      return parts.join(" · ");
                    }(),
                    valueRight: true,
                  ),

                  _buildInfoRow(
                    Icons.stairs_outlined,
                    "층수",
                    "${widget.post.corFloor ?? '-'}층 / ${widget.post.wholeFloor ?? '-'}층",
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.square_foot_outlined,
                    "전용 면적",
                    "${widget.post.area ?? '-'}평",
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.bathtub_outlined,
                    "화장실 개수",
                    "${widget.post.toilet ?? '-'}개",
                    valueRight: true,
                  ),

                  const Divider(height: Sizes.size40),
                  const Text(
                    "계약 정보",
                    style: TextStyle(
                      fontSize: Sizes.size20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gaps.v16(context),
                  _buildInfoRow(
                    Icons.event_available_outlined,
                    "입주 가능일",
                    widget.post.movingDate != null
                        ? DateFormat(
                            'yyyy년 MM월 dd일',
                          ).format(widget.post.movingDate!.toDate())
                        : "정보 없음",
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.article_outlined,
                    "계약 기간",
                    "${widget.post.minContract ?? '-'}개월 ~ ${widget.post.maxContract ?? '-'}개월",
                    valueRight: true,
                  ),

                  const Divider(height: Sizes.size40),
                  const Text(
                    "소개글",
                    style: TextStyle(
                      fontSize: Sizes.size20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

          // 네이버 지도
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.size20,
                0,
                Sizes.size20,
                Sizes.size20,
              ),
              child: (hasAddr && lat != null && lng != null)
                  ? SizedBox(
                      height: 240,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Sizes.size10),
                        child: NaverMap(
                          options: NaverMapViewOptions(
                            initialCameraPosition: NCameraPosition(
                              target: NLatLng(lat, lng),
                              zoom: 15,
                            ),
                            locationButtonEnable: false,
                            consumeSymbolTapEvents: false,
                            scrollGesturesEnable: true,
                            zoomGesturesEnable: true,
                            tiltGesturesEnable: false,
                            rotationGesturesEnable: false,
                            indoorEnable: false,
                          ),
                          onMapReady: (controller) async {
                            final marker = NMarker(
                              id: 'post_${widget.post.postId ?? 'unknown'}',
                              position: NLatLng(lat, lng),
                            );
                            controller.addOverlay(marker);
                            await controller.updateCamera(
                              NCameraUpdate.scrollAndZoomTo(
                                target: NLatLng(lat, lng),
                                zoom: 15,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Container(
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
                    ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Sizes.size6,
            horizontal: Sizes.size20,
          ),
          child: ElevatedButton(
            onPressed: _isOwner ? _goEdit : (_startingChat ? null : _startChat),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Sizes.size8),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _isOwner ? '수정하기' : (_startingChat ? '연결 중...' : '채팅으로 연락하기'),
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
