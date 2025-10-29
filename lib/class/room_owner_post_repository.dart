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
      if (post.authorGender != null)
        'authorGender': _normalize(post.authorGender) ?? post.authorGender,
      'status': post.status ?? 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(), // ⬅️ 추가
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

  // ✅ 과거 코드 호환용 별칭
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

    try {
      var q = _col
          .where('postType', isEqualTo: postType)
          .where('status', isEqualTo: 'open')
          .orderBy('updatedAt', descending: true) // ⬅️ 변경 권장
          .limit(limit);

      if (lastItem != null) q = q.startAfterDocument(lastItem);
      if (tokens.isNotEmpty) {
        q = q.where('authorGender', whereIn: tokens);
      }

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

      // ===== 폴백 경로 (인덱스 빌드 중) =====
      // 1) 서버 쿼리는 최소화: postType만, 커서는 서버 순서(__name__) 기준 유지
      // 2) 클라이언트에서 status=='open'와 gender 토큰 필터링 + updatedAt/createdAt 정렬
      var q = _col
          .where('postType', isEqualTo: postType)
          .limit(limit * 5); // ⬅️ 넉넉히
      if (lastItem != null) q = q.startAfterDocument(lastItem);

      final snap = await q.get();
      // 커서는 반드시 '서버가 돌려준 순서'의 마지막 스냅샷으로 잡아야 함
      final serverLast = snap.docs.isNotEmpty ? snap.docs.last : null;

      // 클라이언트 필터
      List<RoomOwnerPost> all = snap.docs.map(RoomOwnerPost.fromDoc).toList();
      all = all
          .where((p) => (p.status ?? 'open') == 'open')
          .toList(); // ⬅️ 마감 제거

      if (tokens.isNotEmpty) {
        final tokSet = tokens.toSet();
        all = all.where((p) {
          final g = p.authorGender;
          if (g == null) return false;
          // 저장은 보통 'male'/'female'로 정규화돼 있으니 토큰셋에 포함되면 통과
          return tokSet.contains(g);
        }).toList();
      }

      // 정렬: updatedAt > createdAt
      DateTime ts(RoomOwnerPost p) =>
          p.updatedAt ?? p.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      all.sort((a, b) => ts(b).compareTo(ts(a)));

      final page = all.take(limit).toList();

      return PaginatedPostsResult(
        posts: page,
        lastDocument: serverLast, // ⬅️ 서버 커서 유지(중요)
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

      var q = _col.where('authorId', isEqualTo: uid).limit(limit);

      final tokens = _synonyms(authorGender);
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
        lastDocument: docs.isNotEmpty ? docs.last : null,
      );
    }
  }

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
    final list = snap.docs.map(RoomOwnerPost.fromDoc).toList();
    return list;
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

    try {
      var query = _col
          .where('postType', isEqualTo: 'roomOwner')
          .where('status', isEqualTo: 'open') // ✅ 추가
          .where('coordinate', isGreaterThanOrEqualTo: GeoPoint(minLat, minLng))
          .where('coordinate', isLessThanOrEqualTo: GeoPoint(maxLat, maxLng))
          .limit(limit);

      if (tokens.isNotEmpty) {
        query = query.where('authorGender', whereIn: tokens);
      }

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

      var q = _col.where('postType', isEqualTo: 'roomOwner').limit(800);
      if (tokens.isNotEmpty) q = q.where('authorGender', whereIn: tokens);

      final snap = await q.get();
      final list = snap.docs
          .map(RoomOwnerPost.fromDoc)
          .where((p) => (p.status ?? 'open') == 'open') // ⬅️ 추가
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

// === 상태 관리 유틸(추가) ===
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
