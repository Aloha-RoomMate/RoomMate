import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_snippet.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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

  // ─────────────────────────────────────────────────────────────
  // 선택적: 부모 chat 문서를 미리 만들어두고 싶을 때만 사용 (필수 아님)
  Future<void> _ensureChatDoc(String chatRoomId) async {
    final ids = _idsFromRoomId(chatRoomId);
    final chatRef = _db.collection('chats').doc(chatRoomId);

    try {
      await chatRef.set({
        'participants': ids,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageSenderId': null,
        'unreadCounts': {for (final p in ids) p: 0},
        'sharedOriginPostIds': [],
      }, SetOptions(merge: true));
      debugPrint('[ensureChatDoc] upsert ok: $chatRoomId');
    } on FirebaseException catch (e) {
      debugPrint('[ensureChatDoc] fail: code=${e.code} msg=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ensureChatDoc] fail: $e');
      rethrow;
    }
  }

  /// 필요하면 선생성
  Future<String> createChatRoom(String uid1, String uid2) async {
    final id = makeRoomId(uid1, uid2);
    await _ensureChatDoc(id);
    return id;
  }

  // ── 게시글 카드 1회 공유 ─────────────────────────────────────────────
  Future<bool> sharePostOnce(String chatRoomId, PostSnippet s) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final ids = _idsFromRoomId(chatRoomId);
    final other = ids.firstWhere((e) => e != me.uid, orElse: () => me.uid);
    final msgId = 'post_${s.postId}_${me.uid}'; // 결정적 ID

    return await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(chatRef);
      final already = snap.exists
          ? List.from(
              snap.data()?['sharedOriginPostIds'] ?? const [],
            ).contains(s.postId)
          : false;
      if (already) {
        debugPrint('[sharePostOnce] already shared, skip');
        return false;
      }

      // 1) 메시지(결정적 ID → 중복 생성 불가)
      final msgRef = chatRef.collection('messages').doc(msgId);
      tx.set(msgRef, {
        'id': msgId,
        'kind': 'post',
        'senderId': me.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'post': s.toMap(),
      });

      // 2) 메타
      tx.set(chatRef, {
        'participants': ids,
        'sharedOriginPostIds': FieldValue.arrayUnion([s.postId]),
        'lastMessage': '${s.title} 공유함',
        'lastMessageSenderId': me.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'hasContent': true,
        'unreadCounts.${me.uid}': 0,
        'unreadCounts.$other': FieldValue.increment(1),
      }, SetOptions(merge: true));

      return true;
    });
  }

  // ChatRepository 클래스 내부에 추가
  String formatFirebaseError(Object e) {
    // FirebaseException이면 코드/메시지까지 예쁘게 포맷
    if (e is FirebaseException) {
      final code = e.code;
      final msg = e.message ?? '';
      final plugin = e.plugin;
      return '[FirebaseException/$code] $msg (plugin=$plugin)';
    }
    // 그 외는 문자열화
    return e.toString();
  }

  // ChatRepository 클래스 안
  Future<String> diagnoseChat(String chatRoomId) async {
    final me = _auth.currentUser?.uid;
    final parts = _idsFromRoomId(chatRoomId);

    // ⬇️ 여기 수정: '$me_'  →  '${me}_'
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
    } catch (e) {
      buf.writeln('chat get() failed: $e');
    }

    buf.writeln(
      'rules expectation: messages/create allowed if idIncludesMe && senderId==me',
    );
    return buf.toString();
  }

  // (선택) 기존에 내가 준 diagnose()가 있다면 두 개 다 둬도 되고,
  // 없다면 이런 alias도 추가해두면 콘솔에서 바로 확인 가능
  Future<void> diagnose(String chatRoomId) async {
    final s = await diagnoseChat(chatRoomId);
    // ignore: avoid_print
    print(s);
  }

  // ── 텍스트 전송 ─────────────────────────────────────────────────────
  Future<void> sendMessage(String chatRoomId, String text) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgRef = chatRef.collection('messages').doc();
    final ids = _idsFromRoomId(chatRoomId);

    debugPrint('[sendMessage] START uid=${me.uid}, room=$chatRoomId');

    // 1) 메시지 먼저
    try {
      await msgRef.set({
        'id': msgRef.id,
        'senderId': me.uid,
        'text': text,
        'senderName': me.displayName ?? 'W R U',
        'senderPhotoURL': me.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'kind': 'text',
      });
      debugPrint('[sendMessage] messages/${msgRef.id} written');
    } on FirebaseException catch (e) {
      debugPrint(
        '[sendMessage] write message FAILED: code=${e.code} msg=${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[sendMessage] write message FAILED: $e');
      rethrow;
    }

    // 2) 메타 upsert (실패해도 메시지는 이미 있음)
    try {
      final other = ids.firstWhere((e) => e != me.uid, orElse: () => me.uid);
      await chatRef.set({
        'participants': ids, // 최초일 때만 생성, 있으면 유지
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
        'lastMessageSenderId': me.uid,
        'hasContent': true,
        'unreadCounts.${me.uid}': 0,
        'unreadCounts.$other': FieldValue.increment(1),
        'sharedOriginPostIds': FieldValue.arrayUnion([]),
      }, SetOptions(merge: true));
      debugPrint('[sendMessage] meta upsert ok');
    } on FirebaseException catch (e) {
      debugPrint(
        '[sendMessage] meta upsert FAILED: code=${e.code} msg=${e.message}',
      );
      // swallow: 화면은 메시지 스트림으로 정상 보일 수 있음
    } catch (e) {
      debugPrint('[sendMessage] meta upsert FAILED: $e');
    }
  }

  /// 읽음 처리: 문서 없으면 SKIP(빈 방 생성 방지)
  Future<void> markChatRead(String chatRoomId) async {
    final me = _auth.currentUser!;
    final chatRef = _db.collection('chats').doc(chatRoomId);

    try {
      final snap = await chatRef.get();
      debugPrint('[markChatRead] chat.exists=${snap.exists} for $chatRoomId');
      if (!snap.exists) return;

      await chatRef.set({
        'unreadCounts.${me.uid}': 0,
        'lastSeenAt.${me.uid}': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[markChatRead] cleared unread for ${me.uid}');
    } on FirebaseException catch (e) {
      debugPrint('[markChatRead] FAILED: code=${e.code} msg=${e.message}');
    } catch (e) {
      debugPrint('[markChatRead] FAILED: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String chatRoomId) {
    debugPrint('[watchMessages] attach stream for $chatRoomId');
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
