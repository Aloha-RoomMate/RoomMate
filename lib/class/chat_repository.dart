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
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgCol = chatRef.collection('messages');
    final me = _auth.currentUser!;
    return _db.runTransaction<bool>((tx) async {
      final chatSnap = await tx.get(chatRef);
      final data = chatSnap.data() ?? <String, dynamic>{};
      final shared = (data['sharedOriginPostIds'] as List?) ?? const [];
      if (shared.contains(s.postId)) {
        return false; // 이미 공유됨
      }

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
  /// 메시지 전송 시에만 채팅방 문서를 원자적으로 생성/갱신
  Future<void> sendMessage(String chatRoomId, String text) async {
    final me = _auth.currentUser!;
    final idsFromKey = _idsFromRoomId(chatRoomId);

    final chatRef = _db.collection("chats").doc(chatRoomId);
    final msgRef = chatRef.collection("messages").doc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(chatRef);
      // participants 확정(문서 없으면 roomId 파싱)
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

      // 메타 갱신(+ 최초 생성 포함)
      final updates = <String, dynamic>{
        "participants": participants,
        "lastMessage": text,
        "lastMessageSenderId": me.uid,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (!snap.exists) {
        updates["createdAt"] = FieldValue.serverTimestamp();
      }

      // unreadCounts: 보낸 사람은 0, 상대는 +1
      for (final p in participants) {
        final field = "unreadCounts.$p";
        if (p == me.uid) {
          updates[field] = 0;
        } else {
          updates[field] = FieldValue.increment(1);
        }
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
      if (!snap.exists) return; // 빈 방 생성 방지

      tx.set(
        chatRef,
        {
          "unreadCounts.${me.uid}": 0,
          "lastSeenAt.${me.uid}": FieldValue.serverTimestamp(),
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
    await _db.collection('chats').doc(chatRoomId).set({
      'lastMessage': '${s.title} 공유함',
      'lastMessageSenderId': me.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
