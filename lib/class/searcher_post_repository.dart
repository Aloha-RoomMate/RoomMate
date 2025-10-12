import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate/class/searcher_post.dart';

/// fetchPosts 함수의 결과물을 담기 위한 래퍼(wrapper) 클래스
class PaginatedSearcherPostsResult {
  final List<SearcherPost> posts;
  final DocumentSnapshot? lastDocument; // 다음 페이지를 요청할 때 사용할 커서

  PaginatedSearcherPostsResult({required this.posts, this.lastDocument});
}

/// SearcherPost 데이터 처리를 전담하는 클래스
class SearcherPostRepository {
  final FirebaseFirestore _db;

  SearcherPostRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  // 컬렉션에 대한 참조를 getter로 만들어 코드 중복을 줄입니다.
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('searcherPosts');

  /// 1. 생성 (Create)
  /// 새로운 Searcher 게시글을 생성하고, 생성된 문서 ID를 반환합니다.
  Future<String> createPost(SearcherPost post) async {
    // toMap()으로 변환된 데이터에 서버 타임스탬프를 추가합니다.
    final data = {
      ...post.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      if (post.imageUrls == null) 'imageUrls': <String>[],
    };
    final docRef = await _col.add(data);
    return docRef.id;
  }

  /// 2. 수정 (Update)
  /// postId에 해당하는 문서의 일부 필드를 업데이트합니다.
  /// Map<String, dynamic> patch: 업데이트할 필드와 값만 담은 Map
  Future<void> updatePost(String postId, Map<String, dynamic> patch) async {
    await _col.doc(postId).update({
      ...patch,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 3. 읽기 (Read) - 단일 문서
  /// postId로 특정 게시글 하나만 가져옵니다.
  Future<SearcherPost?> fetchById(String postId) async {
    final doc = await _col.doc(postId).get();
    if (!doc.exists) return null;
    return SearcherPost.fromDoc(doc);
  }

  /// 4. 읽기 (Read) - 페이지네이션
  /// postType에 따라 게시글 목록을 20개씩 불러옵니다.
  Future<PaginatedSearcherPostsResult> fetchPosts({
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

    if (lastItem != null) {
      q = q.startAfterDocument(lastItem);
    }

    final snap = await q.get();
    final posts = snap.docs.map(SearcherPost.fromDoc).toList();

    return PaginatedSearcherPostsResult(
      posts: posts,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  /// 5. 읽기 (Read) - 특정 사용자가 쓴 글
  /// uid로 특정 사용자가 작성한 모든 Searcher 게시글을 가져옵니다.
  Future<List<SearcherPost>> fetchPostByUser(String uid) async {
    final snap = await _col
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(SearcherPost.fromDoc).toList();
  }

  /// 6. 삭제 (Delete)
  /// postId에 해당하는 게시글을 삭제합니다.
  Future<void> deletePost(String postId) => _col.doc(postId).delete();
}
