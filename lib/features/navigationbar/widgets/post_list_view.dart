import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
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
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchInitialPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await _repository.fetchPosts(postType: widget.postType);

    if (mounted) {
      setState(() {
        _posts.addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length == 20; // 20개 미만이면 더 이상 데이터 없음
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    // 스크롤이 거의 끝에 도달하면 다음 페이지 로드
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await _repository.fetchPosts(
      postType: widget.postType,
      lastItem: _lastDocument,
    );

    if (mounted) {
      setState(() {
        _posts.addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length == 20;
        _isLoading = false;
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
    // 초기 로딩 중일 때
    if (_posts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 게시글이 하나도 없을 때
    if (_posts.isEmpty && !_hasMore) {
      return const Center(child: Text('게시글이 없습니다.'));
    }

    // 게시글 목록 + 하단 로딩 인디케이터
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      // _hasMore가 true이면, 로딩 인디케이터를 위한 추가 공간(+1) 확보
      itemCount: _posts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 마지막 아이템 차례이고, 더 불러올 데이터가 있다면 로딩 인디케이터를 표시
        if (index == _posts.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final post = _posts[index];
        return PostContainer(post: post);
      },
    );
  }
}
