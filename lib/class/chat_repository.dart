// lib/class/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_snippet.dart';

class ChatRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ───────────────────────────────────────────────────────────────
  // Helpers
  List<String> _idsFromRoomId(String roomId) {
    final i = roomId.indexOf('_');
    if (i <= 0 || i >= roomId.length - 1) return const [];
    final a = roomId.substring(0, i);
    final b = roomId.substring(i + 1);
    final list = [a, b]..sort();
    return list;
  }

  Future<void> _ensureChatDoc(String chatRoomId) async {
    final chatRef = _db.collection("chats").doc(chatRoomId);
    final snap = await chatRef.get();
    if (snap.exists) return;

    final me = _auth.currentUser!;
    final ids = _idsFromRoomId(chatRoomId);
    final participants = ids.isEmpty ? <String>[me.uid] : ids;

    // 규칙과 맞추기: create/update 시 request.resource.data.participants 에 auth.uid 포함
    await chatRef.set({
      "participants": participants,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
      "lastMessage": "",
      "lastMessageSenderId": null,
      "unreadCounts": {for (final p in participants) p: 0},
      "sharedOriginPostIds": [],
    }, SetOptions(merge: true));
  }

  // ───────────────────────────────────────────────────────────────
  /// uid를 정렬한 결정적 chatRoomId 생성 + 문서 선생성(merge)
  Future<String> createChatRoom(String uid1, String uid2) async {
    final uids = [uid1, uid2]..sort();
    final chatRoomId = "${uids[0]}_${uids[1]}";
    final chatRef = _db.collection("chats").doc(chatRoomId);

    await chatRef.set({
      "participants": uids,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
      "lastMessage": "",
      "lastMessageSenderId": null,
      "unreadCounts": {uids[0]: 0, uids[1]: 0},
      "sharedOriginPostIds": [],
    }, SetOptions(merge: true));

    return chatRoomId;
  }

  /// 해당 방에서 postId 카드가 이미 공유됐는지 확인
  Future<bool> hasSharedOriginPost(String chatRoomId, String postId) async {
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final snap = await chatRef.get();
    final data = snap.data() ?? const {};
    final list = (data['sharedOriginPostIds'] as List?) ?? const [];
    return list.contains(postId);
  }

  /// '게시글 카드'를 **한 번만** 공유 (트랜잭션으로 1회 보장)
  /// 반환: 실제 전송되면 true, 이미 공유된 상태면 false
  Future<bool> sharePostOnce(String chatRoomId, PostSnippet s) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgCol = chatRef.collection('messages');

    // 부모 문서가 반드시 존재해야 메시지 규칙을 통과함
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
        'post': s.toMap(), // ← post_snippet.dart 구조와 일치
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

  /// 텍스트 메시지 전송
  Future<void> sendMessage(String chatRoomId, String text) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection("chats").doc(chatRoomId);
    final msgRef = chatRef.collection("messages").doc();

    // 부모 보장 (규칙 만족 위해 선 생성)
    await _ensureChatDoc(chatRoomId);

    // 1) 메시지 생성
    await msgRef.set({
      "id": msgRef.id,
      "senderId": me.uid,
      "text": text,
      "senderName": me.displayName ?? "W R U",
      "senderPhotoURL": me.photoURL,
      "createdAt": FieldValue.serverTimestamp(),
      "kind": "text",
    });

    // 2) 메타 갱신(짧은 트랜잭션)
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

  /// 읽음 처리
  Future<void> markChatRead(String chatRoomId) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection("chats").doc(chatRoomId);
    await chatRef.set({
      "unreadCounts.${me.uid}": 0,
      "lastSeenAt.${me.uid}": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 메시지 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatRoomId) {
    return _db
        .collection("chats")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }
}
