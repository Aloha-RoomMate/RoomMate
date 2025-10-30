import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_snippet.dart';

class ChatRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 두 uid를 정렬해 결정적인 roomId 생성 (문서 생성 X)
  static String makeRoomId(String uid1, String uid2) {
    final u = [uid1, uid2]..sort();
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

  /// 부모 chat 문서 보장(없으면 생성, 있으면 유지)
  Future<void> _ensureChatDoc(String chatRoomId) async {
    final chatRef = _db.collection('chats').doc(chatRoomId);

    final ids = _idsFromRoomId(chatRoomId);
    await chatRef.set({
      'participants': ids,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageSenderId': null,
      'unreadCounts': {for (final p in ids) p: 0},
      'sharedOriginPostIds': [],
    }, SetOptions(merge: true));
  }

  /// (남겨둠) 필요하면 바로 방을 선생성
  Future<String> createChatRoom(String uid1, String uid2) async {
    final id = makeRoomId(uid1, uid2);
    await _ensureChatDoc(id);
    return id;
  }

  // ── 게시글 카드 1회 공유 ─────────────────────────────────────────────
  // ChatRepository.dart — sharePostOnce() 전체 교체
  Future<bool> sharePostOnce(String chatRoomId, PostSnippet s) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgCol = chatRef.collection('messages');

    await _ensureChatDoc(chatRoomId);

    // 메시지 카드 추가
    final msgRef = msgCol.doc();
    await msgRef.set({
      'id': msgRef.id,
      'kind': 'post',
      'senderId': me.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'post': s.toMap(),
    });

    final ids = _idsFromRoomId(chatRoomId);
    if (ids.length < 2) {
      throw Exception('Invalid chatRoomId: $chatRoomId');
    }
    final other = ids.firstWhere((e) => e != me.uid, orElse: () => me.uid);

    // 메타만 합치기 (arrayUnion 이중 방지)
    await chatRef.set({
      'sharedOriginPostIds': FieldValue.arrayUnion([s.postId]),
      'lastMessage': '${s.title} 공유함',
      'lastMessageSenderId': me.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'hasContent': true,
      'unreadCounts.${me.uid}': 0,
      'unreadCounts.$other': FieldValue.increment(1),
    }, SetOptions(merge: true));

    return true;
  }

  // ── 텍스트 전송 ─────────────────────────────────────────────────────
  // ChatRepository.dart — sendMessage() 만 수정
  Future<void> sendMessage(String chatRoomId, String text) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgRef = chatRef.collection('messages').doc();

    await _ensureChatDoc(chatRoomId);

    await msgRef.set({
      'id': msgRef.id,
      'senderId': me.uid,
      'text': text,
      'senderName': me.displayName ?? 'W R U',
      'senderPhotoURL': me.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'kind': 'text',
    });

    final ids = _idsFromRoomId(chatRoomId);
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

  /// 읽음 처리: 문서 없으면 아예 수행하지 않음(빈 방 생성 방지)
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
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
