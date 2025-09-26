import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/features/chat/chat_screen.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("사용자 선택")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final users = snapshot.data!.docs;
          return ListView(
            children: users.where((doc) => doc.id != currentUser.uid).map((
              doc,
            ) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data["displayName"] ?? "이름 없음"),
                onTap: () async {
                  final chatRepo = ChatRepository();
                  final chatId = await chatRepo.createChatRoom(
                    currentUser.uid,
                    doc.id,
                  );

                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatRoomId: chatId),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
