import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/constants/gaps.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String partnerUid;
  final String partnerName;
  final String? partnerPhotoURL;
  final List<String>? quickPhrases;
  final VoidCallback? onSharePost;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.partnerUid,
    required this.partnerName,
    this.partnerPhotoURL,
    this.quickPhrases,
    this.onSharePost,
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

    // 방이 없으면 아무 것도 하지 않음(= 빈 방 생성 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatRepo.markChatRead(widget.chatRoomId);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────── helpers ─────────
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

  Future<void> _sendMessage() async {
    _commitComposing(); // 전송 직전 조합 확정
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    await _chatRepo.sendMessage(widget.chatRoomId, text); // 여기서 방 생성/갱신까지
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
  }

  Future<void> _quickSend(String text) async {
    if (text.trim().isEmpty) return;
    await _chatRepo.sendMessage(widget.chatRoomId, text.trim());
    Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
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

  void _onScaffoldTap() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final chatDocStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .snapshots();

    final quicks = (widget.quickPhrases == null || widget.quickPhrases!.isEmpty)
        ? const ['안녕하세요', '저랑 룸메이트 어떠세요 ?', '집이 멋져요']
        : widget.quickPhrases!;

    final inputStripBg = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withOpacity(0.25);

    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        // ───────── AppBar ─────────
        appBar: AppBar(
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: chatDocStream,
            builder: (context, snap) {
              Timestamp? lastSeenPartner;
              if (snap.hasData && snap.data!.exists) {
                final map = snap.data!.data() ?? const <String, dynamic>{};
                final ls = (map['lastSeenAt'] as Map?) ?? {};
                lastSeenPartner = ls[widget.partnerUid] as Timestamp?;
              }
              final active = _isActiveNow(lastSeenPartner);
              final statusText = active
                  ? 'Active now'
                  : (lastSeenPartner != null
                        ? 'Last seen ${DateFormat.jm().format(lastSeenPartner.toDate())}'
                        : '');

              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: ResponsiveSizes.p(context, 16),
                    backgroundImage:
                        (_partnerPhoto != null && _partnerPhoto!.isNotEmpty)
                        ? NetworkImage(_partnerPhoto!)
                        : null,
                    child: (_partnerPhoto == null || _partnerPhoto!.isEmpty)
                        ? Icon(
                            Icons.person,
                            size: ResponsiveSizes.f(context, 20),
                          )
                        : null,
                  ),
                  Gaps.h10(context),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.partnerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            PopupMenuButton(
              itemBuilder: (c) => const [
                PopupMenuItem(value: 'mute', child: Text('알림 끄기')),
                PopupMenuItem(value: 'block', child: Text('차단')),
              ],
              onSelected: (v) {},
            ),
          ],
        ),

        // ───────── Body ─────────
        body: Column(
          children: [
            // 메시지 리스트
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _chatRepo.watchMessages(widget.chatRoomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  // 최신 메시지가 상대 메시지면 바로 읽음 처리(리스트 뱃지 0으로)
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

                      // 날짜 헤더(하루 단위)
                      bool showDateHeader = false;
                      if (createdAt != null) {
                        if (index == 0) {
                          showDateHeader = true;
                        } else {
                          final prev =
                              (docs[index - 1].data()['createdAt']
                                      as Timestamp?)
                                  ?.toDate();
                          if (prev == null || !_sameDay(createdAt, prev)) {
                            showDateHeader = true;
                          }
                        }
                      }

                      // 묶음의 "마지막" 메시지에만 시간
                      String? timeText;
                      if (createdAt != null) {
                        final isLast = index == docs.length - 1;
                        if (isLast) {
                          timeText = _fmtHm(createdAt);
                        } else {
                          final nextData = docs[index + 1].data();
                          final nextSender = nextData['senderId'] as String?;
                          final nextAt = (nextData['createdAt'] as Timestamp?)
                              ?.toDate();
                          final senderChanged = nextSender != data['senderId'];
                          final minuteChanged = (nextAt == null)
                              ? true
                              : !_sameMinute(createdAt, nextAt);
                          if (senderChanged || minuteChanged) {
                            timeText = _fmtHm(createdAt);
                          }
                        }
                      }

                      final bubble = _MessageBubble(
                        isMe: isMe,
                        text: (data['text'] ?? '').toString(),
                        time: timeText,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateHeader && createdAt != null) ...[
                            SizedBox(height: ResponsiveSizes.p(context, 8)),
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveSizes.p(context, 10),
                                  vertical: ResponsiveSizes.p(context, 4),
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                                child: Text(
                                  _fmtDateKr(createdAt),
                                  style: TextStyle(
                                    fontSize: ResponsiveSizes.f(context, 12),
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveSizes.p(context, 6)),
                          ],
                          bubble,
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // 퀵 전송 칩 (입력창 위)
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
                    ...quicks.map(
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
                    if (widget.onSharePost != null)
                      Padding(
                        padding: EdgeInsets.only(
                          left: ResponsiveSizes.p(context, 4),
                        ),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSizes.p(context, 10),
                              vertical: ResponsiveSizes.p(context, 6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          onPressed: widget.onSharePost,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Share post'),
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

class _BorderlessInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  const _BorderlessInput({
    required this.controller,
    this.onSubmitted,
  });

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

/// 메시지 버블
class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String? time;

  const _MessageBubble({
    required this.isMe,
    required this.text,
    this.time,
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

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: ResponsiveSizes.p(context, 2),
        ),
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
    );

    final timeWidget = (time == null)
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.only(
              right: isMe ? ResponsiveSizes.p(context, 4) : 0,
              left: isMe ? 0 : ResponsiveSizes.p(context, 4),
            ),
            child: Text(
              time!,
              style: TextStyle(
                fontSize: ResponsiveSizes.f(context, 10),
                color: Colors.grey[600],
              ),
            ),
          );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: isMe
          ? <Widget>[timeWidget, bubble]
          : <Widget>[bubble, timeWidget],
    );
  }
}
