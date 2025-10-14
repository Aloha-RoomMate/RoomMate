// lib/class/room_owner_post_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/class/room_owner_post.dart';

class PaginatedPostsResult {
  final List<RoomOwnerPost> posts;
  final DocumentSnapshot? lastDocument;

  PaginatedPostsResult({required this.posts, this.lastDocument});
}

class RoomOwnerPostRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RoomOwnerPostRepository({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('roomOwnerPosts'); // ✅ 복수형 통일

  // -------------------- 성별 토큰/정규화(내부 헬퍼) --------------------

  static const Set<String> _maleTokens = {'male', '남성', '남자', 'm', 'M'};
  static const Set<String> _femaleTokens = {'female', '여성', '여자', 'f', 'F'};

  static bool _isMale(String? g) => g != null && _maleTokens.contains(g.trim());
  static bool _isFemale(String? g) =>
      g != null && _femaleTokens.contains(g.trim());

  static String? _normalize(String? g) {
    if (_isMale(g)) return 'male';
    if (_isFemale(g)) return 'female';
    return null;
  }

  static List<String> _synonyms(String? g) {
    if (_isMale(g)) return _maleTokens.toList();
    if (_isFemale(g)) return _femaleTokens.toList();
    return const [];
  }

  Future<String?> _fetchViewerGender() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection('users').doc(uid).get();
    return (snap.data() ?? const {})['gender'] as String?;
  }

  // -------------------- C / U / R / D --------------------

  Future<String> createPost(RoomOwnerPost post) async {
    final data = {
      ...post.toMap(),
      // 저장 시 표준값으로 살짝 정규화(기존 문서는 그대로 둠)
      if (post.authorGender != null)
        'authorGender': _normalize(post.authorGender) ?? post.authorGender,
      'createdAt': FieldValue.serverTimestamp(),
      if (post.imageUrls == null) 'imageUrls': <String>[],
    };
    final doc = await _col.add(data);
    return doc.id;
  }

  Future<void> updatePost(String postId, Map<String, dynamic> patch) async {
    if (patch.containsKey('authorGender')) {
      final raw = patch['authorGender'] as String?;
      patch['authorGender'] = _normalize(raw) ?? raw;
    }
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
    String? myGender, // "남성" 그대로 받아도 됨(동의어 처리)
  }) async {
    // myGender 미전달 시 로그인 사용자 gender를 읽어 자동 적용
    myGender ??= await _fetchViewerGender();

    try {
      var q = _col
          .where('postType', isEqualTo: postType)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // 🔑 규칙 충족/쿼리 통과용: 동의어 집합 whereIn
      final tokens = _synonyms(myGender);
      if (tokens.isNotEmpty) {
        q = q.where('authorGender', whereIn: tokens);
      }

      if (lastItem != null) q = q.startAfterDocument(lastItem);

      final snap = await q.get();
      final posts = snap.docs.map(RoomOwnerPost.fromDoc).toList();
      return PaginatedPostsResult(
        posts: posts,
        lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
      );
    } on FirebaseException catch (e) {
      final msg = e.message ?? '';
      final needsIndex =
          e.code == 'failed-precondition' && msg.contains('index');

      if (!needsIndex) rethrow;

      // 🩹 인덱스 빌드 중 임시 폴백(서버 정렬 없이 받아 클라 정렬)
      var q = _col.where('postType', isEqualTo: postType).limit(limit);

      final tokens = _synonyms(myGender);
      if (tokens.isNotEmpty) {
        q = q.where('authorGender', whereIn: tokens);
      }

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
  Future<List<RoomOwnerPost>> fetchAllPosts({
    int limit = 20,
    String? myGender,
  }) async {
    myGender ??= await _fetchViewerGender();

    var q = _col.orderBy('createdAt', descending: true).limit(limit);

    final tokens = _synonyms(myGender);
    if (tokens.isNotEmpty) {
      q = q.where('authorGender', whereIn: tokens);
    }

    final snap = await q.get();
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
    myGender ??= await _fetchViewerGender();

    // 1) 대략 범위(사전식)로 1차 컷
    var query = _col
        .where('postType', isEqualTo: 'roomOwner')
        .where('addr', isGreaterThanOrEqualTo: GeoPoint(minLat, minLng))
        .where('addr', isLessThanOrEqualTo: GeoPoint(maxLat, maxLng))
        .limit(limit);

    final tokens = _synonyms(myGender);
    if (tokens.isNotEmpty) {
      query = query.where('authorGender', whereIn: tokens);
    }

    final snap = await query.get();

    // 2) 최종 사각형 필터
    var list = snap.docs.map(RoomOwnerPost.fromDoc).where((p) {
      final gp = p.coordinate;
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
