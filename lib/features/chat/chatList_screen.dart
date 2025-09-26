import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/features/chat/chat_screen.dart';
import 'package:roommate/features/chat/userlist_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("chats")
              .where("participants", arrayContains: user.uid)
              .orderBy("updatedAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text("채팅방이 없습니다."));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final chatId = docs[index].id;
                final lastMessage = data["lastMessage"] ?? "";
                final updatedAt = (data["updatedAt"] as Timestamp?)?.toDate();

                final participants = List<String>.from(
                  data["participants"] ?? [],
                );
                final myUid = user.uid;
                final partnerUid = participants.firstWhere((id) => id != myUid);

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(partnerUid)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const ListTile(title: Text("로딩중..."));
                    }
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final displayName = userData["displayName"] ?? "알 수 없음";

                    return ListTile(
                      title: Text(displayName), // ✅ 상대방 이름
                      subtitle: Text(lastMessage),
                      trailing: Text(
                        updatedAt != null
                            ? "${updatedAt.hour}:${updatedAt.minute}"
                            : "",
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(chatRoomId: chatId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserListScreen()),
            );
          },
        ),
      ),
    );
  }
}
