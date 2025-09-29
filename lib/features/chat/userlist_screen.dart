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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;
          return ListView(
            children: users
                .where((doc) => doc.id != currentUser.uid) // 내 계정 제외
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String partnerUid = doc.id; // ✅ 정의
                  final String partnerName =
                      (data["displayName"] ?? "이름 없음") as String; // ✅ 정의

                  return ListTile(
                    title: Text(partnerName),
                    onTap: () async {
                      final chatRepo = ChatRepository();

                      // 방 생성(또는 재사용) 후 chatId 받기
                      final chatId = await chatRepo.createChatRoom(
                        currentUser.uid,
                        partnerUid,
                      );

                      if (!context.mounted) return;

                      // 뒤로가기로 유저 리스트로 돌아오려면 push 권장
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatRoomId: chatId,
                            partnerUid: partnerUid, // ✅ 실제 값 전달
                            partnerName: partnerName, // ✅ 실제 값 전달
                          ),
                        ),
                      );

                      // 만약 리스트 화면을 스택에서 제거하고 싶다면 위 push 대신 pushReplacement 사용
                    },
                  );
                })
                .toList(),
          );
        },
      ),
    );
  }
}
