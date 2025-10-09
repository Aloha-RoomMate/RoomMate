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

  late final Future<void> _initialLoadFuture;

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _waitAuthThenFetch();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _waitAuthThenFetch() async {
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
        _posts
          ..clear()
          ..addAll(result.posts);
        _lastDocument = result.lastDocument;
        _hasMore = result.posts.length == 20;
        _isLoadingMore = false;
      });
    }
  }

  // 🔹 Pull-to-refresh에서 호출
  Future<void> _refreshPosts() async {
    // 상태 초기화
    _lastDocument = null;
    _hasMore = true;
    _isLoadingMore = false;
    _posts.clear();
    if (mounted) setState(() {}); // 깜빡임 줄이려면 생략 가능

    await _fetchInitialPosts();
  }

  void _onScroll() {
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 초기 로딩 중에도 당겨서 새로고침 가능하게 하려면 RefreshIndicator 감싸도 됨
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(child: Text('오류 발생: ${snapshot.error}')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshPosts,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(), // 빈 리스트여도 당겨짐
            padding: const EdgeInsets.symmetric(vertical: Sizes.size8),
            itemCount: _posts.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _posts.length) {
                // 바닥 로딩셀
                return _isLoadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              final post = _posts[index];
              return PostContainer(post: post);
            },
          ),
        );
      },
    );
  }
}
