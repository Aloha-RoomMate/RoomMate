import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// 게시글 생성
  /// createdAt은 서버시간으로 기록
  Future<void> createPost(RoomOwnerPost post) async {
    await _db.collection('roomOwnerPosts').add({
      ...post.toMap(),
      'createdAt': FieldValue.serverTimestamp(), // ✅ 정렬/인덱스 안정
    });
  }

  /// 타입별 최신순 + 페이지네이션
  Future<PaginatedPostsResult> fetchPosts({
    required String postType,
    DocumentSnapshot? lastItem,
  }) async {
    var query = _db
        .collection('roomOwnerPosts')
        .where('postType', isEqualTo: postType)
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (lastItem != null) {
      query = query.startAfterDocument(lastItem);
    }

    final snap = await query.get();
    final posts = snap.docs.map((d) => RoomOwnerPost.fromDoc(d)).toList();

    return PaginatedPostsResult(
      posts: posts,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  /// 특정 사용자의 글
  Future<List<RoomOwnerPost>> fetchPostByUser(String uid) async {
    final snap = await _db
        .collection('roomOwnerPosts')
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => RoomOwnerPost.fromDoc(d)).toList();
  }

  /// 피드(최신 20)
  Future<List<RoomOwnerPost>> fetchAllPosts() async {
    final snap = await _db
        .collection('roomOwnerPosts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snap.docs.map((d) => RoomOwnerPost.fromDoc(d)).toList();
  }
}
