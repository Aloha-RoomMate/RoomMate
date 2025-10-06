import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:roommate/class/room_owner_post.dart';

/// 페이지네이션 결과 래퍼
class PaginatedPostsResult {
  final List<RoomOwnerPost> posts;
  final DocumentSnapshot? lastDocument;

  PaginatedPostsResult({
    required this.posts,
    this.lastDocument,
  });
}

class RoomOwnerPostRepository {
  final FirebaseFirestore _db;

  RoomOwnerPostRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('roomOwnerPosts');

  /// 게시글 생성
  /// - 규칙 통과 필수 필드: authorId == 현재 사용자 uid, createdAt = serverTimestamp
  Future<String> createPost(RoomOwnerPost post) async {
    // toMap()에는 createdAt을 넣지 않는다. (서버 타임스탬프로 기록)
    final data = {
      ...post.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      // imageUrls가 null이면 규칙상 통과는 하지만, 리스트로 고정하는 편이 안정적
      if (post.imageUrls == null) 'imageUrls': <String>[],
    };

    try {
      final docRef = await _col.add(data);
      if (kDebugMode) {
        debugPrint('[RoomOwnerPostRepository] create ok: ${docRef.id}');
      }
      return docRef.id;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[RoomOwnerPostRepository] create FAIL '
          'code=${e.code} message=${e.message}',
        );
      }
      rethrow;
    }
  }

  /// 게시글 수정
  /// - 규칙: authorId 불변 + updatedAt = serverTimestamp()
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    final patch = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await _col.doc(postId).update(patch);
      if (kDebugMode) {
        debugPrint('[RoomOwnerPostRepository] update ok: $postId');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[RoomOwnerPostRepository] update FAIL '
          'code=${e.code} message=${e.message}',
        );
      }
      rethrow;
    }
  }

  /// 단건 조회
  Future<RoomOwnerPost?> fetchById(String postId) async {
    final doc = await _col.doc(postId).get();
    if (!doc.exists) return null;
    return RoomOwnerPost.fromDoc(doc);
  }

  /// 실시간 구독
  Stream<RoomOwnerPost?> watchById(String postId) {
    return _col.doc(postId).snapshots().map((s) {
      if (!s.exists) return null;
      return RoomOwnerPost.fromDoc(s);
    });
  }

  /// 타입별 최신순 + 페이지네이션
  Future<PaginatedPostsResult> fetchPosts({
    required String postType,
    DocumentSnapshot? lastItem,
    int limit = 20,
  }) async {
    var query = _col
        .where('postType', isEqualTo: postType)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastItem != null) {
      query = query.startAfterDocument(lastItem);
    }

    final snap = await query.get();
    final posts = snap.docs
        .map((d) => RoomOwnerPost.fromDoc(d))
        .toList(growable: false);

    return PaginatedPostsResult(
      posts: posts,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
    // ⚠️ 인덱스 필요: postType + createdAt (이미 콘솔에서 만들어둔 그거면 됨)
  }

  /// 특정 사용자의 글
  Future<List<RoomOwnerPost>> fetchPostByUser(String uid) async {
    final snap = await _col
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => RoomOwnerPost.fromDoc(d)).toList();
    // ⚠️ 인덱스 필요: authorId + createdAt (필요 시 콘솔에서 추가)
  }

  /// 피드(최신 20)
  Future<List<RoomOwnerPost>> fetchAllPosts({int limit = 20}) async {
    final snap = await _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => RoomOwnerPost.fromDoc(d)).toList();
  }

  /// (선택) 삭제 - 규칙상 소유자만 가능
  Future<void> deletePost(String postId) async {
    await _col.doc(postId).delete();
  }
}
