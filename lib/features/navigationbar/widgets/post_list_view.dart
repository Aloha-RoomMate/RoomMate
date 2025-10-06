import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/widgets/post_container.dart';

class PostListView extends StatefulWidget {
  final String postType; // 'roomOwner' 또는 'Searcher'

  const PostListView({
    super.key,
    required this.postType,
  });

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  final RoomOwnerPostRepository _repository = RoomOwnerPostRepository();
  final ScrollController _scrollController = ScrollController();

  final List<RoomOwnerPost> _posts = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  // late 사용해서 유저 정보 가져올 시간 벌어줌.
  late final Future<void> _initialLoadFuture;

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _waitAuthThenFetch();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _waitAuthThenFetch() async {
    // 인증될 때까지 대기
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.authStateChanges().firstWhere(
        (u) => u != null,
      );
    }
    await _fetchInitialPosts();
  }

  Future<void> _fetchInitialPosts() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final result = await _repository.fetchPosts(postType: widget.postType);

    if (mounted) {
      setState(() {
        _posts.addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length == 20; // 20개 미만이면 더 이상 데이터 없음
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    // 스크롤이 거의 끝에 도달하면 다음 페이지 로드
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final result = await _repository.fetchPosts(
      postType: widget.postType,
      lastItem: _lastDocument,
    );

    if (mounted) {
      setState(() {
        _posts.addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length == 20;
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialLoadFuture,
      builder: (context, snapshot) {
        // 로딩 중 이면
        if (snapshot.connectionState == ConnectionState.waiting) {
          return (Center(child: CircularProgressIndicator()));
        }
        // 에러 발생 시
        if (snapshot.hasError) {
          return Center(
            child: Text('오류 발생: ${snapshot.error}'),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(vertical: Sizes.size8),
          itemCount: _posts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return _isLoadingMore
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SizedBox.shrink();
            }
            final post = _posts[index];
            return PostContainer(post: post);
          },
        );
      },
    );
  }
}
