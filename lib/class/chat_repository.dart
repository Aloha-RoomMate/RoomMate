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
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatRoomId;
  }

  Future<void> sendMessage(String chatRoomId, String text) async {
    final user = _auth.currentUser!;
    final msgRef = _db
        .collection("chats")
        .doc(chatRoomId) // ✅ 변수로 전달
        .collection("messages")
        .doc();

    await msgRef.set({
      "senderId": user.uid, // ✅ 키 통일
      "text": text,
      "senderName": user.displayName ?? "W R U",
      "senderPhotoURL": user.photoURL,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // 채팅방 문서 업데이트
    await _db.collection("chats").doc(chatRoomId).set({
      "lastMessage": text,
      "updatedAt": FieldValue.serverTimestamp(),
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
