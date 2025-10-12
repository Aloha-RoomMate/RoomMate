// lib/class/room_owner_post_repository.dart
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
      _db.collection('roomOwnerPosts'); // ✅ 복수형 통일

  // -------------------- C / U / R / D --------------------

  Future<String> createPost(RoomOwnerPost post) async {
    final data = {
      ...post.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      if (post.imageUrls == null) 'imageUrls': <String>[],
    };
    final doc = await _col.add(data);
    return doc.id;
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

  Future<void> deletePost(String postId) => _col.doc(postId).delete();

  // -------------------- 목록 / 피드 --------------------

  /// postType 피드(페이지네이션)
  Future<PaginatedPostsResult> fetchPosts({
    required String postType,
    DocumentSnapshot? lastItem,
    int limit = 20,
    String? myGender,
  }) async {
    var q = _col
        .where('postType', isEqualTo: postType)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (myGender != null) {
      q = q.where('authorGender', isEqualTo: myGender);
    }

    if (lastItem != null) q = q.startAfterDocument(lastItem);

    final snap = await q.get();
    final posts = snap.docs.map(RoomOwnerPost.fromDoc).toList();
    return PaginatedPostsResult(
      posts: posts,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  /// 특정 사용자 글 전체(단순 정렬)
  Future<List<RoomOwnerPost>> fetchPostByUser(String uid) async {
    final snap = await _col
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(RoomOwnerPost.fromDoc).toList();
  }

  /// 특정 사용자 글 — 페이지네이션 (인덱스 빌드 중이면 폴백)
  Future<PaginatedPostsResult> fetchUserPostsPaged({
    required String uid,
    DocumentSnapshot? lastItem,
    int limit = 20,
  }) async {
    try {
      var q = _col
          .where('authorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (lastItem != null) q = q.startAfterDocument(lastItem);

      final snap = await q.get();
      final list = snap.docs.map(RoomOwnerPost.fromDoc).toList();
      return PaginatedPostsResult(
        posts: list,
        lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
      );
    } on FirebaseException catch (e) {
      final msg = e.message ?? '';
      final building =
          e.code == 'failed-precondition' &&
          (msg.contains('index') || msg.contains('currently building'));
      if (!building) rethrow;

      // 🩹 폴백: 서버 정렬 없이 받아서 클라에서 createdAt desc 정렬
      var q = _col.where('authorId', isEqualTo: uid).limit(limit);
      if (lastItem != null) q = q.startAfterDocument(lastItem);

      final snap = await q.get();
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final at = a.data()['createdAt'];
          final bt = b.data()['createdAt'];
          final ad = (at is Timestamp)
              ? at.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final bd = (bt is Timestamp)
              ? bt.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad); // desc
        });

      final list = docs.map(RoomOwnerPost.fromDoc).toList();
      return PaginatedPostsResult(
        posts: list,
        lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
      );
    }
  }

  /// 최신글 일부
  Future<List<RoomOwnerPost>> fetchAllPosts({int limit = 20, String? myGender}) async {
    var query = _col.orderBy('createdAt', descending: true).limit(limit);
    if (myGender != null) {
      query = query.where('authorGender', isEqualTo: myGender);
    }
    final snap = await query.get();
    return snap.docs.map(RoomOwnerPost.fromDoc).toList();
  }

  // -------------------- 지도(뷰포트 내) --------------------

  /// 현재 지도 사각형(viewport) 안의 RoomOwner 글만 가져오기
  ///
  /// ⚠️ Firestore의 GeoPoint 단일 필드 범위 질의는 사전식 정렬이라
  ///    정확한 사각형 컷이 되지 않을 수 있음.
  ///    → 1) GeoPoint로 대략 범위 질의
  ///    → 2) 클라이언트에서 lat/lng로 최종 필터
  Future<List<RoomOwnerPost>> fetchOwnerPostsInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int limit = 200,
    String? myGender,
  }) async {
    // 1) 대략 범위(사전식)로 1차 컷
    var query = _col
        .where('postType', isEqualTo: 'roomOwner')
        .where('addr', isGreaterThanOrEqualTo: GeoPoint(minLat, minLng))
        .where('addr', isLessThanOrEqualTo: GeoPoint(maxLat, maxLng))
        .limit(limit);

    if (myGender != null) {
      query = query.where('authorGender', isEqualTo: myGender);
    }

    final snap = await query.get();

    // 2) 최종 사각형 필터
    var list = snap.docs.map(RoomOwnerPost.fromDoc).where((p) {
      final gp = p.addr;
      if (gp == null) return false;
      final lat = gp.latitude, lng = gp.longitude;
      return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
    }).toList();

    // 필요시 최종 개수 제한(1차 limit에서 더 줄어들 수 있음)
    if (list.length > limit) {
      list = list.take(limit).toList();
    }
    return list;
  }
}
