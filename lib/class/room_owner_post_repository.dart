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

  /// 현재 지도의 뷰포트(사각형) 안에 들어오는 roomOwner 게시글만 가져오기
  Future<List<RoomOwnerPost>> fetchOwnerPostsInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int limit = 200,
  }) async {
    // GeoPoint는 (lat, lng) 순으로 정렬되므로 사각형 범위 질의가 가능
    final snap = await _col
        .where('postType', isEqualTo: 'roomOwner')
        .where('addr', isGreaterThanOrEqualTo: GeoPoint(minLat, minLng))
        .where('addr', isLessThanOrEqualTo: GeoPoint(maxLat, maxLng))
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => RoomOwnerPost.fromDoc(d))
        .where((p) => p.addr != null) // 혹시 null 방어
        .toList();
  }
}
