import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/constants/gaps.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId; // 채팅방 아이디
  final String partnerUid;
  final String partnerName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.partnerUid, // ✅ this로 받아서
    required this.partnerName, // ✅ 필드에 저장
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepo = ChatRepository();
  final user = FirebaseAuth.instance.currentUser!;
  String? _lastClearedMsgId; // 중복 mark 방지(선택)

  void _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    await _chatRepo.sendMessage(widget.chatRoomId, _msgCtrl.text.trim());
    _msgCtrl.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // ✅ 화면 진입 시 읽음 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatRepo.markChatRead(widget.chatRoomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partnerName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSizes.p(context, 20),
        ),
        child: Column(
          children: [
            Gaps.v16(context),
            Expanded(
              child: StreamBuilder(
                stream: _chatRepo.watchMessages(widget.chatRoomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  // ✅ 최신 메시지가 '상대'가 보낸 거면 읽음 처리
                  if (docs.isNotEmpty) {
                    final lastDoc = docs.last;
                    final lastData = lastDoc.data();
                    final isMine = lastData["senderId"] == user.uid;
                    if (!isMine && _lastClearedMsgId != lastDoc.id) {
                      _chatRepo.markChatRead(widget.chatRoomId);
                      _lastClearedMsgId = lastDoc.id;
                    }
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final isMe = data["senderId"] == user.uid;
                      final senderName = data["senderName"] ?? "알 수 없음";
                      final senderPhoto = data["senderPhotoURL"];
                      final createdAt = (data["createdAt"] as Timestamp?)
                          ?.toDate();

                      final bool showHeader =
                          index == 0 ||
                          docs[index - 1].data()["senderId"] !=
                              data["senderId"];

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (showHeader && !isMe)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: ResponsiveSizes.p(context, 14),
                                    backgroundImage:
                                        (senderPhoto != null &&
                                            senderPhoto.toString().isNotEmpty)
                                        ? NetworkImage(senderPhoto)
                                        : null,
                                    child:
                                        (senderPhoto == null ||
                                            senderPhoto.toString().isEmpty)
                                        ? Icon(
                                            Icons.person,
                                            size: ResponsiveSizes.f(
                                              context,
                                              16,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Gaps.h6(context),
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: ResponsiveSizes.f(context, 12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                            if (showHeader && isMe)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: ResponsiveSizes.p(context, 2),
                                  right: ResponsiveSizes.p(context, 4),
                                ),
                                child: Text(
                                  "나",
                                  style: TextStyle(
                                    fontSize: ResponsiveSizes.f(context, 12),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: () {
                                final timeWidget = Text(
                                  createdAt != null
                                      ? "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}"
                                      : "",
                                  style: TextStyle(
                                    fontSize: ResponsiveSizes.f(context, 10),
                                    color: Colors.grey[600],
                                  ),
                                );

                                final bubble = Flexible(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: ResponsiveSizes.p(context, 2),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveSizes.p(context, 8),
                                      horizontal: ResponsiveSizes.p(
                                        context,
                                        12,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.blue[200]
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveSizes.p(context, 14),
                                      ),
                                    ),
                                    child: Text(
                                      data["text"] ?? "",
                                      style: TextStyle(
                                        fontSize: ResponsiveSizes.f(
                                          context,
                                          16,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                return isMe
                                    ? <Widget>[
                                        timeWidget,
                                        Gaps.h4(context),
                                        bubble,
                                      ]
                                    : <Widget>[
                                        bubble,
                                        Gaps.h4(context),
                                        timeWidget,
                                      ];
                              }(),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(ResponsiveSizes.p(context, 8)),
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: InputDecoration(
                          hintText: "메시지를 입력하세요...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveSizes.p(context, 18),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveSizes.p(context, 18),
                            ),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: ResponsiveSizes.p(context, 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Gaps.h8(context),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.blue),
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
