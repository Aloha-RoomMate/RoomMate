import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate/class/room_owner_post.dart';

class PaginatedPostsResult {
  final List<RoomOwnerPost> posts;
  final DocumentSnapshot? lastDocument;

  PaginatedPostsResult({required this.posts, this.lastDocument});
}

class RoomOwnerPostRepository {
  final FirebaseFirestore _db;

  RoomOwnerPostRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collectionRef =>
      _db.collection('roomOwnerPosts'); // ✅ 복수형으로 통일

  Future<String> createPost(RoomOwnerPost post) async {
    final data = {
      ...post.toMap(),
      'createdAt': FieldValue.serverTimestamp(), // ✅ 정렬/규칙용
      if (post.imageUrls == null) 'imageUrls': <String>[],
    };
    final docRef = await _collectionRef.add(data);
    return docRef.id;
  }

  Future<void> updatePost(String postId, Map<String, dynamic> patch) async {
    await _collectionRef.doc(postId).update({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<RoomOwnerPost?> fetchById(String postId) async {
    final doc = await _collectionRef.doc(postId).get();
    if (!doc.exists) return null;
    return RoomOwnerPost.fromDoc(doc);
  }

  /// 피드(예: postType 별) 조회 + 페이지네이션
  Future<PaginatedPostsResult> fetchPosts({
    required String postType,
    DocumentSnapshot? lastItem,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> postsQuery = _collectionRef
        .where('postType', isEqualTo: postType)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastItem != null) {
      postsQuery = postsQuery.startAfterDocument(lastItem);
    }

    final snapshot = await postsQuery.get();
    final posts = snapshot.docs.map(RoomOwnerPost.fromDoc).toList();

    return PaginatedPostsResult(
      posts: posts,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// 특정 사용자(uid)의 글 전부(정렬만, 페이지네이션 없음)
  Future<List<RoomOwnerPost>> fetchPostByUser(String uid) async {
    final snapshot = await _collectionRef
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(RoomOwnerPost.fromDoc).toList();
  }

  /// 특정 사용자(uid)의 글 — 페이지네이션 (인덱스 빌드 중이면 폴백)
  Future<PaginatedPostsResult> fetchUserPostsPaged({
    required String uid,
    DocumentSnapshot? lastItem,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> postsQuery = _collectionRef
          .where('authorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastItem != null) {
        postsQuery = postsQuery.startAfterDocument(lastItem);
      }

      final snapshot = await postsQuery.get();
      final posts = snapshot.docs.map(RoomOwnerPost.fromDoc).toList();

      return PaginatedPostsResult(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } on FirebaseException catch (e) {
      final message = e.message ?? '';
      final isIndexBuilding =
          e.code == 'failed-precondition' &&
          (message.contains('index') || message.contains('currently building'));

      if (!isIndexBuilding) rethrow;

      // 🩹 폴백: 서버 정렬 없이 가져온 뒤 클라이언트에서 createdAt desc 정렬
      Query<Map<String, dynamic>> fallbackQuery = _collectionRef
          .where('authorId', isEqualTo: uid)
          .limit(limit);

      if (lastItem != null) {
        fallbackQuery = fallbackQuery.startAfterDocument(lastItem);
      }

      final snapshot = await fallbackQuery.get();

      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTs = a.data()['createdAt'];
          final bTs = b.data()['createdAt'];
          final aDt = (aTs is Timestamp)
              ? aTs.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final bDt = (bTs is Timestamp)
              ? bTs.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return bDt.compareTo(aDt); // desc
        });

      final posts = sortedDocs.map(RoomOwnerPost.fromDoc).toList();

      return PaginatedPostsResult(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    }
  }

  Future<List<RoomOwnerPost>> fetchAllPosts({int limit = 20}) async {
    final snapshot = await _collectionRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(RoomOwnerPost.fromDoc).toList();
  }

  Future<void> deletePost(String postId) => _collectionRef.doc(postId).delete();
}
