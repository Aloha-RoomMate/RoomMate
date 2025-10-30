// lib/class/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_snippet.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ChatRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static String makeRoomId(String a, String b) {
    final u = [a, b]..sort();
    return "${u[0]}_${u[1]}";
  }

  List<String> _idsFromRoomId(String roomId) {
    final i = roomId.indexOf('_');
    if (i <= 0 || i >= roomId.length - 1) return const [];
    final a = roomId.substring(0, i);
    final b = roomId.substring(i + 1);
    final list = [a, b]..sort();
    return list;
  }

  Future<void> _ensureChatDoc(String chatRoomId) async {
    final ids = _idsFromRoomId(chatRoomId);
    final chatRef = _db.collection('chats').doc(chatRoomId);
    await chatRef.set({
      'participants': ids,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageSenderId': null,
      'unreadCounts': {for (final p in ids) p: 0},
      'hasContent': false,
      'sharedOriginPostIds': [],
    }, SetOptions(merge: true));
  }

  Future<String> createChatRoom(String uid1, String uid2) async {
    final id = makeRoomId(uid1, uid2);
    await _ensureChatDoc(id);
    return id;
  }

  // -------- 텍스트 전송: 항상 부모 먼저 upsert --------
  Future<void> sendMessage(String chatRoomId, String text) async {
    final me = _auth.currentUser!;
    final ids = _idsFromRoomId(chatRoomId);
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgRef = chatRef.collection('messages').doc();

    await _ensureChatDoc(chatRoomId);

    // 1) 메시지
    await msgRef.set({
      'id': msgRef.id,
      'kind': 'text',
      'senderId': me.uid,
      'senderName': me.displayName ?? '',
      'senderPhotoURL': me.photoURL,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2) 메타
    final other = ids.firstWhere((e) => e != me.uid, orElse: () => me.uid);
    await chatRef.set({
      'lastMessage': text,
      'lastMessageSenderId': me.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'hasContent': true,
      'unreadCounts.${me.uid}': 0,
      'unreadCounts.$other': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // -------- 글 공유: 트랜잭션으로 중복 방지 --------
  Future<bool> sharePostOnce(String chatRoomId, PostSnippet s) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final ids = _idsFromRoomId(chatRoomId);

    return _db.runTransaction<bool>((tx) async {
      // 0) 부모 보장
      tx.set(chatRef, {
        'participants': ids,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final snap = await tx.get(chatRef);
      final shared =
          (snap.data()?['sharedOriginPostIds'] as List?)?.cast<String>() ?? [];

      if (shared.contains(s.postId)) {
        // 이미 공유됨 → 아무것도 안 함
        return false;
      }

      // 1) 메시지(같은 트랜잭션)
      final msgRef = chatRef.collection('messages').doc();
      tx.set(msgRef, {
        'id': msgRef.id,
        'kind': 'post',
        'senderId': me.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'post': s.toMap(),
      });

      // 2) 메타 업데이트 + 공유 목록 반영
      final other = ids.firstWhere((e) => e != me.uid, orElse: () => me.uid);
      tx.set(chatRef, {
        'updatedAt': FieldValue.serverTimestamp(),
        'hasContent': true,
        'lastMessage': '${s.title} 공유함',
        'lastMessageSenderId': me.uid,
        'sharedOriginPostIds': FieldValue.arrayUnion([s.postId]),
        'unreadCounts.${me.uid}': 0,
        'unreadCounts.$other': FieldValue.increment(1),
      }, SetOptions(merge: true));

      return true;
    });
  }

  // 읽음 처리
  Future<void> markChatRead(String chatRoomId) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final snap = await chatRef.get();
    if (!snap.exists) return;
    await chatRef.set({
      'unreadCounts.${me.uid}': 0,
      'lastSeenAt.${me.uid}': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  // 오류 포맷/진단(기존과 동일)
  String formatFirebaseError(Object e) {
    if (e is FirebaseException) {
      return '[FirebaseException/${e.code}] ${e.message} (plugin=${e.plugin})';
    }
    return e.toString();
  }

  Future<String> diagnoseChat(String chatRoomId) async {
    final me = _auth.currentUser?.uid;
    final parts = _idsFromRoomId(chatRoomId);
    final idIncludesMeByPrefix =
        (me != null) && chatRoomId.startsWith('${me}_');
    final idIncludesMeBySuffix = (me != null) && chatRoomId.endsWith('_$me');
    final idIncludesMe = idIncludesMeByPrefix || idIncludesMeBySuffix;

    final buf = StringBuffer()
      ..writeln('=== Chat Diagnose ===')
      ..writeln('me: $me')
      ..writeln('roomId: $chatRoomId')
      ..writeln('parsedIds: $parts')
      ..writeln('meInParsedIds: ${me != null && parts.contains(me)}')
      ..writeln('idIncludesMe(by prefix): $idIncludesMeByPrefix')
      ..writeln('idIncludesMe(by suffix): $idIncludesMeBySuffix')
      ..writeln('idIncludesMe(overall): $idIncludesMe');

    try {
      final snap = await _db.collection('chats').doc(chatRoomId).get();
      buf.writeln('chat.exists: ${snap.exists}');
      if (snap.exists) {
        final data = snap.data() ?? {};
        buf.writeln('chat.participants: ${data['participants']}');
      }
    } on FirebaseException catch (e) {
      buf.writeln('chat get() failed: [${e.code}] ${e.message}');
    }
    buf.writeln(
      'rules expectation: messages/create allowed if idIncludesMe && senderId==me',
    );
    return buf.toString();
  }
}
