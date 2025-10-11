import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/searcher_post_repository.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/navigationbar/widgets/room_owner_post_container.dart';
import 'package:roommate/features/navigationbar/widgets/searcher_post_container.dart';

class PostListView extends StatefulWidget {
  /// 'roomOwner' 또는 'Searcher'
  final String postType;

  const PostListView({
    super.key,
    required this.postType,
  });

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  static const _pageSize = 20;

  final RoomOwnerPostRepository _ownerRepo = RoomOwnerPostRepository();
  final SearcherPostRepository _searcherRepo = SearcherPostRepository();

  final ScrollController _scrollController = ScrollController();

  /// 두 타입 모두 담기 위해 Object 사용
  final List<Object> _items = [];

  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  late final Future<void> _initialLoadFuture;

  bool get _isRoomOwner =>
      widget.postType.toLowerCase() == 'roomowner' ||
      widget.postType.toLowerCase() == 'room_owner' ||
      widget.postType.toLowerCase() == 'room-owner' ||
      widget.postType.toLowerCase() == 'room owner';

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
    await _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    if (_isRoomOwner) {
      final res = await _ownerRepo.fetchPosts(postType: 'roomOwner');
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.posts); // List<RoomOwnerPost>
        _lastDocument = res.lastDocument;
        _hasMore = res.posts.length == _pageSize;
        _isLoadingMore = false;
      });
    } else {
      final res = await _searcherRepo.fetchPosts(postType: 'Searcher');
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.posts); // List<SearcherPost>
        _lastDocument = res.lastDocument;
        _hasMore = res.posts.length == _pageSize;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    _lastDocument = null;
    _hasMore = true;
    _isLoadingMore = false;
    _items.clear();
    if (mounted) setState(() {});
    await _fetchInitial();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMore();
    }
  }

  Future<void> _fetchMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    if (_isRoomOwner) {
      final res = await _ownerRepo.fetchPosts(
        postType: 'roomOwner',
        lastItem: _lastDocument,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(res.posts);
        _lastDocument = res.lastDocument;
        _hasMore = res.posts.length == _pageSize;
        _isLoadingMore = false;
      });
    } else {
      final res = await _searcherRepo.fetchPosts(
        postType: 'Searcher',
        lastItem: _lastDocument,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(res.posts);
        _lastDocument = res.lastDocument;
        _hasMore = res.posts.length == _pageSize;
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
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(child: Text('오류 발생: ${snap.error}')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: Sizes.size8),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return _isLoadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }

              final item = _items[index];

              if (item is RoomOwnerPost) {
                return RoomOwnerPostContainer(post: item);
              } else if (item is SearcherPost) {
                return SearcherPostContainer(post: item);
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        );
      },
    );
  }
}
