import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> createChatRoom(String uid1, String uid2) async {
    final uids = [uid1, uid2]..sort();
    final chatRoomId = "${uids[0]}_${uids[1]}";
    final chatRef = _db.collection("chats").doc(chatRoomId);

    await chatRef.set({
      "participants": uids,
      "lastMessage": "",
      "lastMessageSenderId": null,
      "updatedAt": FieldValue.serverTimestamp(),
      // ✅ 새 메시지 배지용 카운트 초기화
      "unreadCounts": {
        uids[0]: 0,
        uids[1]: 0,
      },
    }, SetOptions(merge: true));

    return chatRoomId;
  }

  Future<void> sendMessage(String chatRoomId, String text) async {
    final user = _auth.currentUser!;
    final chatRef = _db.collection("chats").doc(chatRoomId);
    final msgRef = chatRef.collection("messages").doc();

    // 1) 메시지 추가
    await msgRef.set({
      "id": msgRef.id,
      "senderId": user.uid,
      "text": text,
      "senderName": user.displayName ?? "W R U",
      "senderPhotoURL": user.photoURL,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // 2) 메타 갱신 + 상대 unread 증가(트랜잭션)
    await _db.runTransaction((tx) async {
      final snap = await tx.get(chatRef);
      final participants = List<String>.from(
        snap.data()?["participants"] ?? [],
      );

      final Map<String, Object?> updates = {
        "lastMessage": text,
        "lastMessageSenderId": user.uid,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // 보낸 사람은 0, 상대는 +1
      for (final p in participants) {
        final field = "unreadCounts.$p";
        if (p == user.uid) {
          updates[field] = 0;
        } else {
          updates[field] = FieldValue.increment(1);
        }
      }

      tx.set(chatRef, updates, SetOptions(merge: true));
    });
  }

  /// 채팅방을 읽었을 때 내 unreadCounts를 0으로
  Future<void> markChatRead(String chatRoomId) async {
    final user = _auth.currentUser!;
    final chatRef = _db.collection("chats").doc(chatRoomId);
    await chatRef.set({
      "unreadCounts.${user.uid}": 0,
      "lastSeenAt.${user.uid}": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatRoomId) {
    return _db
        .collection("chats")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }
}
