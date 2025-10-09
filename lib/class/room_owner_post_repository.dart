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

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('roomOwnerPosts'); // ✅ 복수형으로 통일

  Future<String> createPost(RoomOwnerPost post) async {
    final data = {
      ...post.toMap(),
      'createdAt': FieldValue.serverTimestamp(), // ✅ 정렬/규칙용
      if (post.imageUrls == null) 'imageUrls': <String>[],
    };
    final docRef = await _col.add(data);
    return docRef.id;
  }

  Future<void> updatePost(String postId, Map<String, dynamic> patch) async {
    await _col.doc(postId).update({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<RoomOwnerPost?> fetchById(String postId) async {
    final doc = await _col.doc(postId).get();
    if (!doc.exists) return null;
    return RoomOwnerPost.fromDoc(doc);
  }

  Future<PaginatedPostsResult> fetchPosts({
    required String postType,
    DocumentSnapshot? lastItem,
    int limit = 20,
  }) async {
    var q = _col
        .where('postType', isEqualTo: postType)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastItem != null) q = q.startAfterDocument(lastItem);
    final snap = await q.get();
    final posts = snap.docs.map(RoomOwnerPost.fromDoc).toList();
    return PaginatedPostsResult(
      posts: posts,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<List<RoomOwnerPost>> fetchPostByUser(String uid) async {
    final snap = await _col
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(RoomOwnerPost.fromDoc).toList();
  }

  Future<List<RoomOwnerPost>> fetchAllPosts({int limit = 20}) async {
    final snap = await _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(RoomOwnerPost.fromDoc).toList();
  }

  Future<void> deletePost(String postId) => _col.doc(postId).delete();
}
