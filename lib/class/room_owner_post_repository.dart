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
      _db.collection('roomOwnerPosts');

  // -------------------- 성별 토큰/정규화(규칙과 동일) --------------------
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
      if (post.authorGender != null)
        'authorGender': _normalize(post.authorGender) ?? post.authorGender,
      'status': post.status ?? 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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

  // 과거 별칭 유지
  Future<RoomOwnerPost?> fetchPostById(String postId) => fetchById(postId);

  Future<void> deletePost(String postId) => _col.doc(postId).delete();

  // -------------------- 목록 / 피드 --------------------

  Future<PaginatedPostsResult> fetchPosts({
    required String postType,
    DocumentSnapshot? lastItem,
    int limit = 20,
    String? myGender,
  }) async {
    myGender ??= await _fetchViewerGender();
    final tokens = _synonyms(myGender);
    if (tokens.isEmpty) {
      // 규칙상 sameGender가 필요하므로 성별이 없으면 쿼리 자체를 막아 permission-denied 회피
      throw StateError('설정에서 성별을 먼저 지정해주세요.');
    }

    try {
      // 규칙과 동일한 필터(동일 성별)를 서버 쿼리에 포함
      var q = _col
          .where('postType', isEqualTo: postType)
          .where('status', isEqualTo: 'open')
          .where('authorGender', whereIn: tokens)
          .orderBy('updatedAt', descending: true)
          .limit(limit);

      if (lastItem != null) q = q.startAfterDocument(lastItem);

      final snap = await q.get();
      final posts = snap.docs.map(RoomOwnerPost.fromDoc).toList();

      return PaginatedPostsResult(
        posts: posts,
        lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
      );
    } on FirebaseException catch (e) {
      // 인덱스 미구축/빌드 중 → 폴백
      final msg = e.message ?? '';
      final needsIndex =
          e.code == 'failed-precondition' &&
          msg.toLowerCase().contains('index');
      if (!needsIndex) rethrow;

      // 🩹 폴백: sameGender 필터는 유지(규칙 충족), 정렬은 클라에서 처리
      var q = _col
          .where('postType', isEqualTo: postType)
          .where('authorGender', whereIn: tokens)
          .limit(limit * 4); // 넉넉히 받아서 클라 정렬

      if (lastItem != null) q = q.startAfterDocument(lastItem);

      final snap = await q.get();
      final docs = snap.docs.toList()
        ..sort((a, b) {
          DateTime asDate(dynamic v) {
            if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
            if (v is Timestamp) return v.toDate();
            if (v is DateTime) return v;
            if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
            if (v is String) {
              try {
                return DateTime.parse(v);
              } catch (_) {
                return DateTime.fromMillisecondsSinceEpoch(0);
              }
            }
            return DateTime.fromMillisecondsSinceEpoch(0);
          }

          final ad = asDate(a.data()['updatedAt'] ?? a.data()['createdAt']);
          final bd = asDate(b.data()['updatedAt'] ?? b.data()['createdAt']);
          return bd.compareTo(ad); // desc
        });

      // UI 정책상 open만 노출
      final filtered = docs
          .where((d) => (d.data()['status'] ?? 'open') == 'open')
          .take(limit)
          .map(RoomOwnerPost.fromDoc)
          .toList();

      return PaginatedPostsResult(
        posts: filtered,
        lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
      );
    }
  }

  Future<List<RoomOwnerPost>> fetchPostByUser(String uid) async {
    final snap = await _col
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(RoomOwnerPost.fromDoc).toList();
  }

  Future<PaginatedPostsResult> fetchUserPostsPaged({
    required String uid,
    DocumentSnapshot? lastItem,
    int limit = 20,
    String? authorGender,
  }) async {
    try {
      var q = _col
          .where('authorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final tokens = _synonyms(authorGender);
      if (tokens.isNotEmpty) {
        q = q.where('authorGender', whereIn: tokens);
      }

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

      var q = _col.where('authorId', isEqualTo: uid).limit(limit * 3);
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
        lastDocument: docs.isNotEmpty ? docs.last : null,
      );
    }
  }

  Future<List<RoomOwnerPost>> fetchAllPosts({
    int limit = 20,
    String? myGender,
  }) async {
    myGender ??= await _fetchViewerGender();
    final tokens = _synonyms(myGender);
    if (tokens.isEmpty) return const [];

    var q = _col
        .where('authorGender', whereIn: tokens)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    final snap = await q.get();
    return snap.docs.map(RoomOwnerPost.fromDoc).toList();
  }

  // -------------------- 지도(뷰포트 내) --------------------
  Future<List<RoomOwnerPost>> fetchOwnerPostsInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int limit = 200,
    String? myGender,
  }) async {
    myGender ??= await _fetchViewerGender();
    final tokens = _synonyms(myGender);
    if (tokens.isEmpty) return const [];

    try {
      var query = _col
          .where('postType', isEqualTo: 'roomOwner')
          .where('status', isEqualTo: 'open')
          .where('authorGender', whereIn: tokens)
          .where('coordinate', isGreaterThanOrEqualTo: GeoPoint(minLat, minLng))
          .where('coordinate', isLessThanOrEqualTo: GeoPoint(maxLat, maxLng))
          .limit(limit);

      final snap = await query.get();

      var list = snap.docs.map(RoomOwnerPost.fromDoc).where((p) {
        final gp = p.coordinate;
        if (gp == null) return false;
        final lat = gp.latitude, lng = gp.longitude;
        return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
      }).toList();

      if (list.length > limit) list = list.take(limit).toList();
      return list;
    } on FirebaseException catch (e) {
      final needsIndex = e.code == 'failed-precondition';
      if (!needsIndex) rethrow;

      // 🩹 폴백: sameGender는 서버 필터로 유지, 좌표는 클라에서 필터
      var q = _col
          .where('postType', isEqualTo: 'roomOwner')
          .where('authorGender', whereIn: tokens)
          .limit(800);

      final snap = await q.get();
      final list = snap.docs
          .map(RoomOwnerPost.fromDoc)
          .where((p) => (p.status ?? 'open') == 'open')
          .where((p) {
            final gp = p.coordinate;
            if (gp == null) return false;
            final lat = gp.latitude, lng = gp.longitude;
            return lat >= minLat &&
                lat <= maxLat &&
                lng >= minLng &&
                lng <= maxLng;
          })
          .take(limit)
          .toList();

      return list;
    }
  }
}

// === 상태 관리 유틸 ===
extension RoomOwnerPostRepositoryStatus on RoomOwnerPostRepository {
  Future<void> closePost(String postId) async {
    await updatePost(postId, {
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markPostMatched({
    required String postId,
    required String chatRoomId,
    required String partnerUid,
  }) async {
    await updatePost(postId, {
      'status': 'matched',
      'matchedChatRoomId': chatRoomId,
      'matchedWithUid': partnerUid,
      'matchedAt': FieldValue.serverTimestamp(),
    });
  }
}
