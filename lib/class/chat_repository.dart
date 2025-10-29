// lib/class/chat_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'post_snippet.dart';

class ChatRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 두 uid를 정렬해 결정적인 chatRoomId 생성 (문서 생성 X)
  Future<String> createChatRoom(String uid1, String uid2) async {
    final uids = [uid1, uid2]..sort();
    return "${uids[0]}_${uids[1]}"; // ← uid_uid 포맷 유지
  }

  /// chatRoomId("a_b")에서 uid 2개를 복원
  List<String> _idsFromRoomId(String roomId) {
    final i = roomId.indexOf('_');
    if (i <= 0 || i >= roomId.length - 1) return const [];
    final a = roomId.substring(0, i);
    final b = roomId.substring(i + 1);
    final list = [a, b]..sort();
    return list;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Origin Post 공유(한 번만)

  Future<bool> hasSharedOriginPost(String chatRoomId, String postId) async {
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final snap = await chatRef.get();
    final data = snap.data() ?? const {};
    final list = (data['sharedOriginPostIds'] as List?) ?? const [];
    return list.contains(postId);
  }

  /// 공지형 '게시글 카드'를 **한 번만** 보내고, sharedOriginPostIds 에 기록
  /// 반환값: 실제 전송되면 true, 이미 보낸 적 있으면 false
  Future<bool> sharePostOnce(String chatRoomId, PostSnippet s) async {
    await ensureChatDoc(chatRoomId); // 부모 문서 보장

    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgCol = chatRef.collection('messages');
    final me = _auth.currentUser!;

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

  // ──────────────────────────────────────────────────────────────────────────
  /// 채팅 문서가 없으면 participants와 기본 필드를 채워 생성 (멱등)
  Future<void> ensureChatDoc(String chatRoomId) async {
    final ids = _idsFromRoomId(chatRoomId);

    // 파싱 실패는 규칙 거절 전에 즉시 에러로
    if (ids.length != 2) {
      throw StateError('Invalid chatRoomId: "$chatRoomId" → parsed=$ids');
    }

    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('Not signed in while ensuring chat doc');
    }
    if (!ids.contains(me.uid)) {
      // 규칙: participants에 나 자신이 반드시 포함되어야 함
      throw StateError(
        'participants does not contain me.uid. me=${me.uid}, ids=$ids',
      );
    }

    final chatRef = _db.collection("chats").doc(chatRoomId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(chatRef);
      if (snap.exists) return; // 멱등

      tx.set(chatRef, {
        "participants": ids,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "unreadCounts": {ids[0]: 0, ids[1]: 0},
      });
    });
  }

  /// 메시지 전송 (부모 문서 선보장 + 메타 갱신)
  Future<void> sendMessage(String chatRoomId, String text) async {
    await ensureChatDoc(chatRoomId);

    final me = _auth.currentUser!;
    final idsFromKey = _idsFromRoomId(chatRoomId);

    final chatRef = _db.collection("chats").doc(chatRoomId);
    final msgRef = chatRef.collection("messages").doc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(chatRef);

      final participants = snap.exists
          ? List<String>.from(snap.data()?["participants"] ?? idsFromKey)
          : idsFromKey;

      // 메시지 생성
      tx.set(msgRef, {
        "id": msgRef.id,
        "senderId": me.uid,
        "text": text,
        "senderName": me.displayName ?? "W R U",
        "senderPhotoURL": me.photoURL,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // unreadCounts를 맵 전체 갱신(필드패스 점 표기 회피)
      final currentUnread = Map<String, dynamic>.from(
        snap.data()?["unreadCounts"] ?? {},
      );
      for (final p in participants) {
        if (p == me.uid) {
          currentUnread[p] = 0;
        } else {
          final prev = (currentUnread[p] ?? 0);
          currentUnread[p] = (prev is int ? prev : 0) + 1;
        }
      }

      final updates = <String, dynamic>{
        "participants": participants,
        "lastMessage": text,
        "lastMessageSenderId": me.uid,
        "updatedAt": FieldValue.serverTimestamp(),
        "unreadCounts": currentUnread,
      };
      if (!snap.exists) {
        updates["createdAt"] = FieldValue.serverTimestamp();
      }

      tx.set(chatRef, updates, SetOptions(merge: true));
    });
  }

  /// 채팅방을 읽었을 때 내 unreadCounts를 0으로 (방이 없으면 무시)
  Future<void> markChatRead(String chatRoomId) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection("chats").doc(chatRoomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(chatRef);
      if (!snap.exists) return;

      final currentUnread = Map<String, dynamic>.from(
        snap.data()?["unreadCounts"] ?? {},
      );
      currentUnread[me.uid] = 0;

      final lastSeen = Map<String, dynamic>.from(
        snap.data()?["lastSeenAt"] ?? {},
      );
      lastSeen[me.uid] = FieldValue.serverTimestamp();

      tx.set(
        chatRef,
        {
          "unreadCounts": currentUnread,
          "lastSeenAt": lastSeen,
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(
    String chatRoomId,
  ) {
    return _db
        .collection("chats")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }

  /// (선택) 강제 공유(한 번 제한 없이) — 기존 코드 유지 호환
  Future<void> sendPostShare(String chatRoomId, PostSnippet s) async {
    await ensureChatDoc(chatRoomId);

    final me = _auth.currentUser!;
    final msgRef = _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    await msgRef.set({
      'id': msgRef.id,
      'kind': 'post',
      'senderId': me.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'post': s.toMap(),
    });

    await _db.collection('chats').doc(chatRoomId).set(
      {
        'lastMessage': '${s.title} 공유함',
        'lastMessageSenderId': me.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
