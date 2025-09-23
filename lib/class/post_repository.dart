import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate/class/post.dart';

class PostRepository {
  final FirebaseFirestore _db; // final: init list 필요

  PostRepository({
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance; // 유일한 연결 통로 - instance

  /// 게시글 올리기
  Future<void> createPost(Post post) async {
    await _db.collection('roomOwnerPosts').add(post.toMap());
  }

  /// 특정 유저 게시글 가져오기
  Future<List<Post>> fetchPostByUser(String uid) async {
    final querySnapshot = await _db
        .collection('roomOwnerPosts')
        .where('authorId', isEqualTo: uid)
        .get();

    return querySnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
  }

  /// 피드용. 모든 post 가져오기.
  Future<List<Post>> fetchAllPosts() async {
    final querySnapshot = await _db
        .collection('roomOwnerPosts')
        .orderBy('createdAt', descending: true)
        .limit(20) // 최신 20개만 가져오기
        .get();

    return querySnapshot.docs.map((doc) => Post.fromDoc(doc)).toList();
  }
}
