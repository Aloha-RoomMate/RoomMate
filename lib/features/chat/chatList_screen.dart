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

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: user.uid)
            .orderBy("updatedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("채팅방이 없습니다."));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final raw = docs[index];
              final data = raw.data() as Map<String, dynamic>;
              final chatId = raw.id;

              final lastMessage = (data["lastMessage"] ?? "") as String;
              final updatedAt = (data["updatedAt"] as Timestamp?)?.toDate();

              final participants = List<String>.from(
                data["participants"] ?? [],
              );
              final myUid = user.uid;
              final partnerUid = participants.firstWhere(
                (id) => id != myUid,
                orElse: () => "",
              );

              if (partnerUid.isEmpty) {
                // 비정상 데이터 보호
                return const ListTile(
                  title: Text("잘못된 채팅 데이터"),
                  subtitle: Text("참여자 정보를 확인할 수 없습니다."),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(partnerUid)
                    .get(),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting ||
                      !userSnap.hasData) {
                    return const ListTile(title: Text("로딩중..."));
                  }

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final displayName =
                      (userData["displayName"] ?? "알 수 없음") as String;
                  final photoUrl =
                      (userData["photoUrl"] ?? userData["profileImageUrl"])
                          as String?;

                  return ListTile(
                    leading: _RoundedSquareAvatar(
                      size: 48,
                      photoUrl: photoUrl,
                      fallbackText: displayName.isNotEmpty
                          ? displayName[0]
                          : '?',
                    ),
                    title: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatTime(updatedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatRoomId: chatId,
                            partnerUid: partnerUid,
                            partnerName: displayName,
                          ),
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
            MaterialPageRoute(builder: (_) => const UserListScreen()),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "";
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return "$h:$m";
    } else {
      // 다른 날이면 MM/dd 표기로
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      return "$mm/$dd";
    }
  }
}

/// 둥근 사각형 아바타 위젯
class _RoundedSquareAvatar extends StatelessWidget {
  const _RoundedSquareAvatar({
    super.key,
    required this.size,
    this.photoUrl,
    this.fallbackText = '?',
    this.radius = 12,
  });

  final double size;
  final String? photoUrl;
  final String fallbackText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    final fg = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget child;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // 로딩 표시
          loadingBuilder: (ctx, w, progress) {
            if (progress == null) return w;
            return _loading(bg);
          },
          // 실패 시 대체
          errorBuilder: (_, __, ___) => _fallback(bg, fg),
        ),
      );
    } else {
      child = _fallback(bg, fg);
    }

    return SizedBox(width: size, height: size, child: child);
  }

  Widget _loading(Color bg) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _fallback(Color bg, Color fg) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackText.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
