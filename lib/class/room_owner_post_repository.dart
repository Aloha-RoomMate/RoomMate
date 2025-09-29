import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate/class/room_owner_post.dart';

/// fetchPosts 함수의 결과물을 담기 위한 래퍼(wrapper) 클래스
/// 게시글 리스트와 다음 페이지를 위한 마지막 문서 정보를 함께 전달합니다.
class PaginatedPostsResult {
  final List<RoomOwnerPost> posts;
  final DocumentSnapshot? lastDocument;

  PaginatedPostsResult({required this.posts, this.lastDocument});
}

class RoomOwnerPostRepository {
  final FirebaseFirestore _db; // final: init list 필요

  RoomOwnerPostRepository({
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance; // 유일한 연결 통로 - instance

  /// 게시글 올리기
  Future<void> createPost(RoomOwnerPost post) async {
    await _db.collection('roomOwnerPosts').add(post.toMap());
  }

  /// 타입별 + 페이지네이션 기능이 추가된 게시글 목록 불러오기
  Future<PaginatedPostsResult> fetchPosts({
    required String postType,
    DocumentSnapshot? lastItem, // 마지막으로 본 문서를 전달받음
  }) async {
    // 1. 기본 쿼리 생성: postType으로 필터링하고 최신순으로 정렬
    var query = _db
        .collection('roomOwnerPosts')
        .where('postType', isEqualTo: postType)
        .orderBy('createdAt', descending: true)
        .limit(20); // 한번에 20개씩

    // 2. 만약 마지막으로 본 문서가 있다면, 그 다음부터 쿼리 시작
    if (lastItem != null) {
      query = query.startAfterDocument(lastItem);
    }

    final querySnapshot = await query.get();
    final posts = querySnapshot.docs
        .map((doc) => RoomOwnerPost.fromDoc(doc))
        .toList();

    // 3. 게시글 리스트와 마지막 문서를 함께 반환
    return PaginatedPostsResult(
      posts: posts,
      lastDocument: querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.last
          : null,
    );
  }

  /// 특정 유저 게시글 가져오기
  Future<List<RoomOwnerPost>> fetchPostByUser(String uid) async {
    final querySnapshot = await _db
        .collection('roomOwnerPosts')
        .where('authorId', isEqualTo: uid)
        .get();

    return querySnapshot.docs.map((doc) => RoomOwnerPost.fromDoc(doc)).toList();
  }

  /// 피드용. 모든 post 가져오기.
  Future<List<RoomOwnerPost>> fetchAllPosts() async {
    final querySnapshot = await _db
        .collection('roomOwnerPosts')
        .orderBy('createdAt', descending: true)
        .limit(20) // 최신 20개만 가져오기
        .get();

    return querySnapshot.docs.map((doc) => RoomOwnerPost.fromDoc(doc)).toList();
  }
}
