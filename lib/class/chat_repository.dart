import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_snippet.dart';

class ChatRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 두 uid를 정렬해 결정적인 chatRoomId 생성 (문서 생성 X)
  static String makeRoomId(String uid1, String uid2) {
    final uids = [uid1, uid2]..sort();
    return "${uids[0]}_${uids[1]}";
  }

  List<String> _idsFromRoomId(String roomId) {
    final i = roomId.indexOf('_');
    if (i <= 0 || i >= roomId.length - 1) return const [];
    final a = roomId.substring(0, i);
    final b = roomId.substring(i + 1);
    final list = [a, b]..sort();
    return list;
  }

  /// 부모 채팅문서를 안전하게 보장(없으면 생성, 있으면 그대로)
  Future<void> _ensureChatDoc(String chatRoomId) async {
    final chatRef = _db.collection("chats").doc(chatRoomId);
    final snap = await chatRef.get();
    if (snap.exists) return;

    final ids = _idsFromRoomId(chatRoomId);
    await chatRef.set({
      "participants": ids,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
      "lastMessage": "",
      "lastMessageSenderId": null,
      "unreadCounts": {for (final p in ids) p: 0},
      "sharedOriginPostIds": [],
    }, SetOptions(merge: true));
  }

  /// (선택) 기존 API 유지 — 하지만 빈 방이 생기므로 특별한 이유 없으면 사용하지 말 것
  Future<String> createChatRoom(String uid1, String uid2) async {
    final chatRoomId = makeRoomId(uid1, uid2);
    await _ensureChatDoc(chatRoomId);
    return chatRoomId;
  }

  // ─────────────────────────────────────────────────────────────
  // 게시글 카드 1회 자동 공유
  Future<bool> hasSharedOriginPost(String chatRoomId, String postId) async {
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final snap = await chatRef.get();
    final data = snap.data() ?? const {};
    final list = (data['sharedOriginPostIds'] as List?) ?? const [];
    return list.contains(postId);
  }

  /// 게시글 카드를 **한 번만** 전송 (부모 보장 + 트랜잭션)
  Future<bool> sharePostOnce(String chatRoomId, PostSnippet s) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgCol = chatRef.collection('messages');

    await _ensureChatDoc(chatRoomId);

    return _db.runTransaction<bool>((tx) async {
      final chatSnap = await tx.get(chatRef);
      final data = chatSnap.data() ?? <String, dynamic>{};
      final shared = (data['sharedOriginPostIds'] as List?) ?? const [];
      if (shared.contains(s.postId)) return false;

      final msgRef = msgCol.doc();
      tx.set(msgRef, {
        'id': msgRef.id,
        'kind': 'post',
        'senderId': me.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'post': s.toMap(),
      });

      tx.set(
        chatRef,
        {
          'sharedOriginPostIds': FieldValue.arrayUnion([s.postId]),
          'lastMessage': '${s.title} 공유함',
          'lastMessageSenderId': me.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    });
  }

  // ─────────────────────────────────────────────────────────────
  /// 텍스트 메시지 전송
  Future<void> sendMessage(String chatRoomId, String text) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection("chats").doc(chatRoomId);
    final msgRef = chatRef.collection("messages").doc();

    await _ensureChatDoc(chatRoomId);

    await msgRef.set({
      "id": msgRef.id,
      "senderId": me.uid,
      "text": text,
      "senderName": me.displayName ?? "W R U",
      "senderPhotoURL": me.photoURL,
      "createdAt": FieldValue.serverTimestamp(),
      "kind": "text",
    });

    await _db.runTransaction((tx) async {
      final snap = await tx.get(chatRef);
      if (!snap.exists) return;
      final participants = List<String>.from(
        snap.data()?["participants"] ?? const [],
      );

      final updates = <String, dynamic>{
        "lastMessage": text,
        "lastMessageSenderId": me.uid,
        "updatedAt": FieldValue.serverTimestamp(),
      };
      for (final p in participants) {
        updates["unreadCounts.$p"] = (p == me.uid)
            ? 0
            : FieldValue.increment(1);
      }
      tx.set(chatRef, updates, SetOptions(merge: true));
    });
  }

  /// 읽음 처리 — 문서가 없으면 **아무 것도 하지 않음**(빈 방 생성 방지)
  Future<void> markChatRead(String chatRoomId) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection("chats").doc(chatRoomId);
    final snap = await chatRef.get();
    if (!snap.exists) return; // ← 중요: 여기서 만들지 않는다

    await chatRef.set({
      "unreadCounts.${me.uid}": 0,
      "lastSeenAt.${me.uid}": FieldValue.serverTimestamp(),
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
