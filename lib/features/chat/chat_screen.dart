import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId; // 채팅방 아이디

  const ChatScreen({super.key, required this.chatRoomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepo = ChatRepository();
  final user = FirebaseAuth.instance.currentUser!;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: Sizes.size16),
            Expanded(
              child: StreamBuilder(
                stream: _chatRepo.watchMessages(widget.chatRoomId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

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
                                    radius: Sizes.size14,
                                    backgroundImage:
                                        (senderPhoto != null &&
                                            senderPhoto.toString().isNotEmpty)
                                        ? NetworkImage(senderPhoto)
                                        : null,
                                    child:
                                        (senderPhoto == null ||
                                            senderPhoto.toString().isEmpty)
                                        ? const Icon(Icons.person, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    senderName,
                                    style: const TextStyle(
                                      fontSize: Sizes.size12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                            if (showHeader && isMe)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 2,
                                  right: 4,
                                ),
                                child: Text(
                                  "나",
                                  style: const TextStyle(
                                    fontSize: Sizes.size12,
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
                                    fontSize: Sizes.size10,
                                    color: Colors.grey[600],
                                  ),
                                );

                                final bubble = Flexible(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.blue[200]
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(
                                        Sizes.size14,
                                      ),
                                    ),
                                    child: Text(
                                      data["text"] ?? "",
                                      style: const TextStyle(
                                        fontSize: Sizes.size16,
                                      ),
                                    ),
                                  ),
                                );
                                return isMe
                                    ? <Widget>[
                                        timeWidget,
                                        const SizedBox(width: 4),
                                        bubble,
                                      ]
                                    : <Widget>[
                                        bubble,
                                        const SizedBox(width: 4),
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
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: "메시지를 입력하세요...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Sizes.size18),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Sizes.size18),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: Sizes.size2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
