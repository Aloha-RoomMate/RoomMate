import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/constants/gaps.dart';

import 'package:roommate/class/post_snippet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';

// ⬇️ NEW: 로그 다이얼로그에서 복사 버튼용
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String partnerUid;
  final String partnerName;
  final String? partnerPhotoURL;
  final List<String>? quickPhrases;
  final VoidCallback? onSharePost;

  // 게시글에서 진입 시
  final PostSnippet? postSnippet; // 카드 내용
  final String? initialPrefillText; // 프리필 문구
  final bool autoSharePostOnFirstSend; // 첫 전송 시 1회 카드 자동 공유

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.partnerUid,
    required this.partnerName,
    this.partnerPhotoURL,
    this.quickPhrases,
    this.onSharePost,
    this.postSnippet,
    this.initialPrefillText,
    this.autoSharePostOnFirstSend = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _chatRepo = ChatRepository();
  final _me = FirebaseAuth.instance.currentUser!;
  String? _lastClearedMsgId;
  String? _partnerPhoto;

  final _supabase = Supabase.instance.client;
  final _postRepo = RoomOwnerPostRepository();

  RoomOwnerPost? _originPost;
  bool _iAmAuthorOfOrigin = false;

  bool _firstSendDone = false;
  bool _alreadySharedOrigin = true; // 기본 true, postSnippet 있으면 false로 갱신

  // ⬇️ 빈 방 보호: 문서/메시지 스트림 부착 여부
  bool _listenChatDoc = false;
  bool _listenMessages = false;

  @override
  void initState() {
    super.initState();

    _partnerPhoto = widget.partnerPhotoURL;
    if (_partnerPhoto == null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.partnerUid)
          .get()
          .then((d) {
            if (!mounted) return;
            final p = (d.data() ?? const {})['photoURL'] as String?;
            if (p != null && p.isNotEmpty) setState(() => _partnerPhoto = p);
          });
    }

    _prepareOriginContext();
    _checkChatDocOnce(); // ← 최초 한 번만 존재 여부 확인(있을 때만 스트림 활성화)
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // NEW: 에러를 자세히 보여주는 다이얼로그
  // ─────────────────────────────────────────────────────────────
  Future<void> _showVerboseError(Object e, String actionName) async {
    final formatted = _chatRepo.formatFirebaseError(e);
    final diag = await _chatRepo.diagnoseChat(widget.chatRoomId);

    if (!mounted) return;
    // 짧은 스낵바
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$actionName 실패: $formatted')),
    );

    // 콘솔 로그
    // ignore: avoid_print
    print('$actionName failed: $formatted\n$diag');

    // 자세한 다이얼로그
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$actionName 실패'),
        content: SingleChildScrollView(
          child: SelectableText('$formatted\n\n$diag'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '$formatted\n\n$diag'));
              Navigator.pop(context);
            },
            child: const Text('복사'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _prepareOriginContext() async {
    // 1) 프리필
    if ((widget.initialPrefillText?.isNotEmpty ?? false)) {
      _msgCtrl.text = widget.initialPrefillText!;
      _msgCtrl.selection = TextSelection.collapsed(
        offset: _msgCtrl.text.length,
      );
    }

    // 2) 원글 UI용 정보만 로드(서버에 chats 문서 접근 안함)
    if (widget.postSnippet != null) {
      _alreadySharedOrigin = false; // 첫 전송 시 1회 공유하도록
      try {
        final p = await _postRepo.fetchById(widget.postSnippet!.postId);
        if (!mounted) return;
        setState(() {
          _originPost = p;
          _iAmAuthorOfOrigin = (p?.authorId == _me.uid);
        });
      } catch (_) {}
    } else {
      _alreadySharedOrigin = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _checkChatDocOnce() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .get(); // 존재하지 않으면 exists=false
      if (!mounted) return;
      if (snap.exists) {
        setState(() {
          _listenChatDoc = true;
          _listenMessages = true;
        });
        // 존재할 때만 읽음 처리
        await _chatRepo.markChatRead(widget.chatRoomId);
      }
    } catch (e) {
      // 권한/비존재 에러는 무시 (빈 방 상태 유지)
      // ignore: avoid_print
      print('checkChatDocOnce failed: $e');
    }
  }

  Future<String?> _signedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return await _supabase.storage
          .from('RoomMate-image')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _commitComposing() {
    final v = _msgCtrl.value;
    if (v.composing.isValid) {
      _msgCtrl.value = v.copyWith(
        composing: TextRange.empty,
        selection: TextSelection.collapsed(offset: v.text.length),
      );
    }
  }

  // ── 메시지 전송 ─────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    _commitComposing();
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatRepo.sendMessage(widget.chatRoomId, text);
      _msgCtrl.clear();

      if (!_firstSendDone &&
          widget.autoSharePostOnFirstSend &&
          widget.postSnippet != null) {
        _firstSendDone = true;
        await _chatRepo.sharePostOnce(widget.chatRoomId, widget.postSnippet!);
        _alreadySharedOrigin = true;
        if (mounted) setState(() {});
      }

      if (!_listenMessages || !_listenChatDoc) {
        if (mounted) {
          setState(() {
            _listenChatDoc = true;
            _listenMessages = true;
          });
        }
        await _chatRepo.markChatRead(widget.chatRoomId);
      }

      Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
    } catch (e) {
      if (!mounted) return;
      await _showVerboseError(e, '메시지 전송');
    }
  }

  Future<void> _quickSend(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _chatRepo.sendMessage(widget.chatRoomId, text.trim());

      if (!_firstSendDone &&
          widget.autoSharePostOnFirstSend &&
          widget.postSnippet != null) {
        _firstSendDone = true;
        await _chatRepo.sharePostOnce(widget.chatRoomId, widget.postSnippet!);
        _alreadySharedOrigin = true;
        if (mounted) setState(() {});
      }

      if (!_listenMessages || !_listenChatDoc) {
        if (mounted) {
          setState(() {
            _listenChatDoc = true;
            _listenMessages = true;
          });
        }
        await _chatRepo.markChatRead(widget.chatRoomId);
      }

      Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
    } catch (e) {
      if (!mounted) return;
      await _showVerboseError(e, '메시지 전송');
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;

  String _fmtDateKr(DateTime dt) =>
      '${dt.year}년 ${dt.month.toString().padLeft(2, '0')}월 ${dt.day.toString().padLeft(2, '0')}일';
  String _fmtHm(DateTime dt) => DateFormat.jm().format(dt);

  bool _isActiveNow(Timestamp? ts) {
    if (ts == null) return false;
    final diff = DateTime.now().difference(ts.toDate());
    return diff.inMinutes < 2;
  }

  void _onScaffoldTap() => FocusScope.of(context).unfocus();

  void _openPostDetail(PostSnippet s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PostFetcherPage(postId: s.postId)),
    );
  }

  // ───── 원글 마감/삭제/매칭 (작성자 전용) ─────
  Future<void> _closeOriginPostFromChat() async {
    final s = widget.postSnippet;
    if (s == null || !_iAmAuthorOfOrigin) return;
    try {
      await _postRepo.closePost(s.postId);
      await _chatRepo.sendMessage(widget.chatRoomId, '안내: 게시글이 마감되었습니다.');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글을 마감했어요.')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      await _showVerboseError(e, '마감 알림 전송');
    }
  }

  Future<void> _deleteOriginPostFromChat() async {
    final s = widget.postSnippet;
    if (s == null || !_iAmAuthorOfOrigin) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 완전 삭제하시겠어요? 되돌릴 수 없습니다.'),
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
      await _postRepo.deletePost(s.postId);
      await _chatRepo.sendMessage(widget.chatRoomId, '안내: 게시글이 삭제되었습니다.');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글을 삭제했어요.')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      await _showVerboseError(e, '삭제 알림 전송');
    }
  }

  Future<void> _markMatchedFromChat() async {
    final s = widget.postSnippet;
    if (s == null || !_iAmAuthorOfOrigin) return;
    try {
      await _postRepo.markPostMatched(
        postId: s.postId,
        chatRoomId: widget.chatRoomId,
        partnerUid: widget.partnerUid,
      );
      await _chatRepo.sendMessage(
        widget.chatRoomId,
        '안내: 현재 채팅 상대와 매칭이 완료되었습니다.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('매칭 완료로 표시했어요.')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      await _showVerboseError(e, '매칭 알림 전송');
    }
  }

  @override
  Widget build(BuildContext context) {
    final quicks = (widget.quickPhrases == null || widget.quickPhrases!.isEmpty)
        ? const ['안녕하세요', '저랑 룸메이트 어떠세요 ?', '집이 멋져요']
        : widget.quickPhrases!;

    final inputStripBg = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withOpacity(0.25);

    // chat 문서 스트림(존재 확인 전에는 붙이지 않음)
    final Stream<DocumentSnapshot<Map<String, dynamic>>>? chatDocStream =
        _listenChatDoc
        ? FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatRoomId)
              .snapshots()
        : null;

    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          title: _listenChatDoc
              ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: chatDocStream,
                  builder: (context, snap) {
                    Timestamp? lastSeenPartner;
                    if (snap.hasData && snap.data!.exists) {
                      final map =
                          snap.data!.data() ?? const <String, dynamic>{};
                      final ls = (map['lastSeenAt'] as Map?) ?? {};
                      lastSeenPartner = ls[widget.partnerUid] as Timestamp?;
                    }
                    final active = _isActiveNow(lastSeenPartner);
                    final statusText = active
                        ? 'Active now'
                        : (lastSeenPartner != null
                              ? 'Last seen ${DateFormat.jm().format(lastSeenPartner.toDate())}'
                              : '');

                    return _AppBarTitle(
                      name: widget.partnerName,
                      photoUrl: _partnerPhoto,
                      active: active,
                      statusText: statusText,
                    );
                  },
                )
              : _AppBarTitle(
                  name: widget.partnerName,
                  photoUrl: _partnerPhoto,
                  active: false,
                  statusText: '',
                ),
          actions: [
            PopupMenuButton<String>(
              itemBuilder: (c) {
                final items = <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: 'mute', child: Text('알림 끄기')),
                  const PopupMenuItem(value: 'block', child: Text('차단')),
                ];
                if (widget.postSnippet != null && _iAmAuthorOfOrigin) {
                  items.add(const PopupMenuDivider());
                  items.add(
                    const PopupMenuItem(
                      value: 'matched',
                      child: Text('이 상대와 매칭 완료로 표시'),
                    ),
                  );
                  items.add(
                    const PopupMenuItem(
                      value: 'close_post',
                      child: Text('게시글 마감하기'),
                    ),
                  );
                  items.add(
                    const PopupMenuItem(
                      value: 'delete_post',
                      child: Text('게시글 삭제하기'),
                    ),
                  );
                }
                return items;
              },
              onSelected: (v) async {
                switch (v) {
                  case 'matched':
                    await _markMatchedFromChat();
                    break;
                  case 'close_post':
                    await _closeOriginPostFromChat();
                    break;
                  case 'delete_post':
                    await _deleteOriginPostFromChat();
                    break;
                  default:
                    break;
                }
              },
            ),
          ],
        ),

        body: Column(
          children: [
            // 메시지 리스트(문서가 생기기 전에는 비워둠)
            Expanded(
              child: _listenMessages
                  ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _chatRepo.watchMessages(widget.chatRoomId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          // 권한/기타 오류 시에도 UI는 죽지 않게
                          return const SizedBox.shrink();
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        // 최신 메시지가 상대 메시지면 읽음 갱신
                        if (docs.isNotEmpty) {
                          final last = docs.last;
                          final d = last.data();
                          final isMine = d['senderId'] == _me.uid;
                          if (!isMine && _lastClearedMsgId != last.id) {
                            _chatRepo.markChatRead(widget.chatRoomId);
                            _lastClearedMsgId = last.id;
                          }
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveSizes.p(context, 20),
                            vertical: ResponsiveSizes.p(context, 8),
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final isMe = data['senderId'] == _me.uid;
                            final createdAt = (data['createdAt'] as Timestamp?)
                                ?.toDate();
                            final kind = (data['kind'] ?? 'text').toString();

                            // 날짜 헤더
                            bool showDateHeader = false;
                            if (createdAt != null) {
                              if (index == 0) {
                                showDateHeader = true;
                              } else {
                                final prev =
                                    (docs[index - 1].data()['createdAt']
                                            as Timestamp?)
                                        ?.toDate() ??
                                    DateTime.fromMillisecondsSinceEpoch(0);
                                if (!_sameDay(createdAt, prev)) {
                                  showDateHeader = true;
                                }
                              }
                            }

                            // 묶음 마지막에만 시간
                            String? timeText;
                            if (createdAt != null) {
                              final isLast = index == docs.length - 1;
                              if (isLast) {
                                timeText = _fmtHm(createdAt);
                              } else {
                                final next = docs[index + 1].data();
                                final nextSender = next['senderId'] as String?;
                                final nextAt = (next['createdAt'] as Timestamp?)
                                    ?.toDate();
                                final senderChanged =
                                    nextSender != data['senderId'];
                                final minuteChanged = nextAt == null
                                    ? true
                                    : !_sameMinute(createdAt, nextAt);
                                if (senderChanged || minuteChanged) {
                                  timeText = _fmtHm(createdAt);
                                }
                              }
                            }

                            // 내 메시지 읽지않음 '1'
                            bool showUnreadBadge = false;
                            if (isMe) {
                              if (timeText != null) {
                                showUnreadBadge = true;
                              }
                            }

                            Widget child;
                            if (kind == 'post') {
                              final postMap = (data['post'] as Map?)
                                  ?.cast<String, dynamic>();
                              if (postMap != null) {
                                final s = PostSnippet.fromMap(postMap);
                                child = Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: _PostNoticeBubble(
                                    isMe: isMe,
                                    snippet: s,
                                    getSignedUrl: _signedUrl,
                                    onTap: () => _openPostDetail(s),
                                    time: timeText,
                                  ),
                                );
                              } else {
                                child = const SizedBox.shrink();
                              }
                            } else {
                              child = _MessageBubble(
                                isMe: isMe,
                                text: (data['text'] ?? '').toString(),
                                time: timeText,
                                showUnread: showUnreadBadge,
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDateHeader && createdAt != null) ...[
                                  SizedBox(
                                    height: ResponsiveSizes.p(context, 8),
                                  ),
                                  Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveSizes.p(
                                          context,
                                          10,
                                        ),
                                        vertical: ResponsiveSizes.p(context, 4),
                                      ),
                                      child: Text(
                                        _fmtDateKr(createdAt),
                                        style: TextStyle(
                                          fontSize: ResponsiveSizes.f(
                                            context,
                                            12,
                                          ),
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: ResponsiveSizes.p(context, 6),
                                  ),
                                ],
                                child,
                              ],
                            );
                          },
                        );
                      },
                    )
                  : const SizedBox.expand(), // 빈 방: 조용히 빈 화면
            ),

            // 퀵 전송 칩 + 글 공유하기 버튼
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSizes.p(context, 12),
                vertical: ResponsiveSizes.p(context, 6),
              ),
              color: inputStripBg,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...(quicks).map(
                      (t) => Padding(
                        padding: EdgeInsets.only(
                          right: ResponsiveSizes.p(context, 8),
                        ),
                        child: ActionChip(
                          label: Text(t),
                          onPressed: () => _quickSend(t),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black12),
                          shape: const StadiumBorder(),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ),
                    ),
                    if (widget.postSnippet != null && !_alreadySharedOrigin)
                      Padding(
                        padding: EdgeInsets.only(
                          left: ResponsiveSizes.p(context, 4),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final ok = await _chatRepo.sharePostOnce(
                                widget.chatRoomId,
                                widget.postSnippet!,
                              );
                              setState(() => _alreadySharedOrigin = true);
                              // ok 여부와 무관하게 서버가 1회만 보장
                            } catch (e) {
                              if (!mounted) return;
                              await _showVerboseError(e, '글 공유');
                            }
                          },
                          icon: const Icon(Icons.campaign_outlined),
                          label: const Text('글 공유하기'),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 입력 영역
            Container(
              width: double.infinity,
              color: inputStripBg,
              padding: EdgeInsets.fromLTRB(
                ResponsiveSizes.p(context, 10),
                ResponsiveSizes.p(context, 6),
                ResponsiveSizes.p(context, 10),
                ResponsiveSizes.p(context, 10),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSizes.p(context, 12),
                          vertical: ResponsiveSizes.p(context, 2),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            ResponsiveSizes.p(context, 18),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: _BorderlessInput(
                          controller: _msgCtrl,
                          onSubmitted: _sendMessage,
                        ),
                      ),
                    ),
                    Gaps.h8(context),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _sendMessage,
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

class _AppBarTitle extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool active;
  final String statusText;

  const _AppBarTitle({
    required this.name,
    required this.photoUrl,
    required this.active,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: ResponsiveSizes.p(context, 16),
          backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
              ? NetworkImage(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? Icon(Icons.person, size: ResponsiveSizes.f(context, 20))
              : null,
        ),
        Gaps.h10(context),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Row(
              children: [
                if (active)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.greenAccent,
                    ),
                  ),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BorderlessInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  const _BorderlessInput({required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: TextInputAction.send,
      controller: controller,
      minLines: 1,
      maxLines: 4,
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: const InputDecoration(
        hintText: '메시지를 입력하세요…',
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent, width: 2),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

/// 기본 텍스트 메시지 버블
class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String? time;
  final bool showUnread;

  const _MessageBubble({
    required this.isMe,
    required this.text,
    this.time,
    this.showUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final myColor = Theme.of(context).primaryColor;
    final bubbleColor = isMe ? myColor : Colors.grey[200];
    final textColor = isMe ? Colors.white : Colors.black87;

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    final content = Text(
      text,
      softWrap: true,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontSize: ResponsiveSizes.f(context, 16),
        color: textColor,
      ),
    );

    final bubble = Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: ResponsiveSizes.p(context, 2)),
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSizes.p(context, 8),
            horizontal: ResponsiveSizes.p(context, 12),
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: content,
        ),
      ),
    );

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (time != null)
          Padding(
            padding: EdgeInsets.only(
              right: isMe ? ResponsiveSizes.p(context, 4) : 0,
              left: isMe ? 0 : ResponsiveSizes.p(context, 4),
            ),
            child: Text(
              time!,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: ResponsiveSizes.f(context, 10),
                color: Colors.grey[600],
              ),
            ),
          ),
        if (isMe && showUnread) ...[
          SizedBox(width: ResponsiveSizes.p(context, 4)),
          Text(
            '1',
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: ResponsiveSizes.f(context, 10),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: isMe
          ? <Widget>[
              meta,
              SizedBox(width: ResponsiveSizes.p(context, 4)),
              bubble,
            ]
          : <Widget>[
              bubble,
              SizedBox(width: ResponsiveSizes.p(context, 4)),
              meta,
            ],
    );
  }
}

/// 게시글 공지 카드 버블
class _PostNoticeBubble extends StatelessWidget {
  final bool isMe;
  final PostSnippet snippet;
  final Future<String?> Function(String?) getSignedUrl;
  final VoidCallback onTap;
  final String? time;

  const _PostNoticeBubble({
    required this.isMe,
    required this.snippet,
    required this.getSignedUrl,
    required this.onTap,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    final outer = FutureBuilder<String?>(
      future: getSignedUrl(snippet.imagePath),
      builder: (context, snap) {
        final img = snap.data;

        final card = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: ResponsiveSizes.p(context, 2),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveSizes.p(context, 12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.campaign_outlined, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '게시글을 보고 연락했어요',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 8)),
                    Text(
                      snippet.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: ResponsiveSizes.f(context, 15),
                      ),
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 4)),
                    Text(
                      '${snippet.priceLabel()} · ${snippet.nearLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: ResponsiveSizes.f(context, 12),
                      ),
                    ),
                    SizedBox(height: ResponsiveSizes.p(context, 10)),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: img != null
                              ? Image.network(
                                  img,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.home_outlined),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.article_outlined, size: 18),
                                const SizedBox(width: 6),
                                const Expanded(child: Text('글 확인하기')),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return Flexible(child: card);
      },
    );

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (time != null)
          Padding(
            padding: EdgeInsets.only(
              right: isMe ? ResponsiveSizes.p(context, 4) : 0,
              left: isMe ? 0 : ResponsiveSizes.p(context, 4),
            ),
            child: Text(
              time!,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: ResponsiveSizes.f(context, 10),
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: isMe
          ? <Widget>[
              meta,
              SizedBox(width: ResponsiveSizes.p(context, 4)),
              outer,
            ]
          : <Widget>[
              outer,
              SizedBox(width: ResponsiveSizes.p(context, 4)),
              meta,
            ],
    );
  }
}

/// postId로 문서를 읽어 RoomOwnerPostView를 띄워주는 간단한 Fetcher
class _PostFetcherPage extends StatelessWidget {
  final String postId;
  const _PostFetcherPage({required this.postId});

  @override
  Widget build(BuildContext context) {
    final repo = RoomOwnerPostRepository();
    return FutureBuilder<RoomOwnerPost?>(
      future: repo.fetchById(postId),
      builder: (context, snap) {
        if (!snap.hasData) {
          if (snap.connectionState == ConnectionState.done &&
              snap.data == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('게시글을 찾을 수 없어요.')),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return RoomOwnerPostView(post: snap.data!);
      },
    );
  }
}
