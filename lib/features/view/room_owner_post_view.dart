// features/view/room_owner_post_view.dart
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

  // Supabase (Private 버킷 → 서명 URL 필요) ✅ 버킷명 일치
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

  /// ✅ 변경된 스택형 정보 행: 제목 아래로 값이 감싸지며 내려감
  // 제목 아래 값 스택형 + 값 정렬 옵션 추가
  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    bool valueRight = false, // ← 값을 오른쪽 정렬할지 여부
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 상단 이미지 슬라이더
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: imagePaths.isEmpty
                  ? Image.asset(
                      'assets/house.jpg',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
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
                            color: Colors.black.withOpacity(0.3),
                            colorBlendMode: BlendMode.darken,
                          );
                        }
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              controller: _pageCtrl,
                              onPageChanged: (i) =>
                                  setState(() => _currentPage = i),
                              itemCount: urls.length,
                              itemBuilder: (_, i) => Image.network(
                                urls[i],
                                fit: BoxFit.cover,
                                loadingBuilder: (c, w, p) => p == null
                                    ? w
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/house.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // 하단 도트 인디케이터
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

          // 본문
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title ?? '제목 없음',
                    style: const TextStyle(
                      fontSize: Sizes.size24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gaps.v16(context),
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
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    "위치",
                    widget.post.addressLabel ?? "위치 정보 부근",
                  ),
                  _buildInfoRow(
                    Icons.attach_money_outlined,
                    "보증금",
                    "${numberFormat.format(widget.post.deposit ?? 0)}만원",
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.local_atm_outlined,
                    "월세",
                    "${numberFormat.format(widget.post.rent ?? 0)}만원",
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.receipt_long_outlined,
                    "관리비",
                    "${numberFormat.format(widget.post.manageFee ?? 0)}만원",
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
