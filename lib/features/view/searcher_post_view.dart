// lib/features/view/searcher_post_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/features/chat/chat_screen.dart';
import 'package:roommate/features/view/user_profile_view.dart';
import 'package:roommate/features/navigationbar/screens/mypage_screen.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';
import 'package:roommate/class/searcher_post_repository.dart';

class SearcherPostView extends StatefulWidget {
  final SearcherPost post;

  const SearcherPostView({
    super.key,
    required this.post,
  });

  @override
  State<SearcherPostView> createState() => _SearcherPostViewState();
}

class _SearcherPostViewState extends State<SearcherPostView> {
  final UserRepository _userRepository = UserRepository();
  final ChatRepository _chatRepo = ChatRepository();
  final SearcherPostRepository _searcherRepo = SearcherPostRepository();

  late Future<AppUser?> _authorFuture;
  bool _startingChat = false;

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

  // === MainNavigation으로 이동 (RoomOwnerPostView와 동일한 패턴) ===
  void _goMain() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 0)),
      (route) => false,
    );
  }

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
      await _chatRepo.ensureChatDoc(chatRoomId);

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
    } on FirebaseException catch (e, st) {
      debugPrint('🔥 startChat FirebaseException: ${e.code} ${e.message}\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅 시작 실패: ${e.code}')),
      );
    } catch (e, st) {
      debugPrint('🔥 startChat Other error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅 시작 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  void _goEdit() {
    // TODO: 방 구하기 게시물 수정 화면으로 이동 (준비되면 활성화)
    // Navigator.push(context, MaterialPageRoute(builder: (_) => SearcherPostScreen(postToEdit: widget.post)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수정 기능은 아직 준비 중입니다.')),
    );
  }

  Future<void> _handleDelete() async {
    final postId = widget.post.postId;
    if (postId == null || postId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제할 게시글 ID가 없어요.')),
      );
      return;
    }

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
      await _searcherRepo.deletePost(postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글을 삭제했어요.')),
      );
      _goMain(); // ✅ 삭제 후 메인으로
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern();
    final p = widget.post;

    final wantAreas = (p.wantArea ?? const <String>[]).join(', ');
    final wantRoom = (p.wantRoom ?? const <String>[]).join(', ');
    final wantPay = (p.wantPay ?? const <String>[]).join(', ');

    final deposit = numberFormat.format(p.deposit ?? 0);
    final minRent = numberFormat.format(p.minRent ?? 0);
    final maxRent = numberFormat.format(p.maxRent ?? 0);

    final movingDate = p.movingDate != null
        ? DateFormat('yyyy년 MM월 dd일').format(p.movingDate!.toDate())
        : "정보 없음";
    final contract = '${p.minContract ?? '-'}개월 ~ ${p.maxContract ?? '-'}개월';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // === SliverAppBar (RoomOwnerPostView 스타일) ===
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goMain, // ✅ MainNavigation으로
              tooltip: '뒤로',
            ),
            title: const Text(
              '상세 보기',
              style: TextStyle(
                fontSize: Sizes.size18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (_isOwner)
                IconButton(
                  tooltip: '삭제하기',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _handleDelete,
                ),
            ],
          ),

          // === 본문 ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    p.title ?? '제목 없음',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Gaps.v20(context),

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
                          final meUid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == meUid) {
                            // ✅ 내 글이면 마이페이지
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MypageScreen(isBlocked: false),
                              ),
                            );
                          } else {
                            // ✅ 남의 글이면 상대 프로필
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UserProfileView(targetUid: uid),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const Divider(height: Sizes.size40),

                  const Text(
                    "희망 조건",
                    style: TextStyle(
                      fontSize: Sizes.size20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gaps.v16(context),

                  _buildInfoRow(
                    Icons.location_on_outlined,
                    "희망 지역",
                    wantAreas.isEmpty ? '-' : wantAreas,
                  ),
                  _buildInfoRow(
                    Icons.home_outlined,
                    "희망 구조",
                    wantRoom.isEmpty ? '-' : wantRoom,
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.payment_outlined,
                    "지불 방식",
                    wantPay.isEmpty ? '-' : wantPay,
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.attach_money_outlined,
                    "희망 예산",
                    "보증금 $deposit만 / 월세 $minRent만 ~ $maxRent만",
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.event_available_outlined,
                    "입주 희망일",
                    movingDate,
                    valueRight: true,
                  ),
                  _buildInfoRow(
                    Icons.article_outlined,
                    "희망 계약 기간",
                    contract,
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
        ],
      ),
      // === 하단 버튼: 투명 바텀앱바 ===
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
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
