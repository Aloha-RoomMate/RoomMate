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

  Future<void> sendMessage(String chatroomId, String text) async {
    final user = _auth.currentUser!;
    final msg = _db
        .collection('chats')
        .doc('chatroomId')
        .collection('messages')
        .doc();

    await msg.set({
      "senderID": user.uid,
      "text": text,
      'sendAt': FieldValue.serverTimestamp(),
    });
    await _db.collection("chats").doc('chatroomId').set({
      // 두명의 UID 를 모두 넣어야 함.
      "partner": [user.uid],
      'lastMessage': text,
      'sendAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 실시간으로 데이터를 계속 보내주는 Stream
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatRoomId) {
    return _db
        .collection("chats")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }
}
