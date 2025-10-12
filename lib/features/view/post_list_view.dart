import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/searcher_post_repository.dart';
import 'package:roommate/features/navigationbar/widgets/room_owner_post_container.dart';
import 'package:roommate/features/navigationbar/widgets/searcher_post_container.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class PostListView extends StatefulWidget {
  /// 'roomOwner' 또는 'Searcher'
  final String postType;

  const PostListView({super.key, required this.postType});

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  static const _pageSize = 20;

  final RoomOwnerPostRepository _ownerRepo = RoomOwnerPostRepository();
  final SearcherPostRepository _searcherRepo = SearcherPostRepository();
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
          ..addAll(res.posts);
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
          ..addAll(res.posts);
        _lastDocument = res.lastDocument;
        _hasMore = res.posts.length == _pageSize;
        _isLoadingMore = false;
      });
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
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMore();
    }
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
                SizedBox(height: ResponsiveSizes.height(context, 120 / 800)),
                Center(child: Text('오류 발생: ${snap.error}')),
              ],
            ),
          );
        }

        // ====== Responsive grid metrics ======
        const columns = 2;
        const imageAspect = 0.93; // ← 0.90 에서 살짝 ↑ (height = width / aspect)

        final outerPad = ResponsiveSizes.p(context, 12);
        final crossSpacing = ResponsiveSizes.p(context, 12);
        final mainSpacing = ResponsiveSizes.p(context, 12);

        final screenW = MediaQuery.of(context).size.width;
        final textScale = MediaQuery.textScaleFactorOf(context);

        final itemW =
            (screenW - (outerPad * 2) - crossSpacing * (columns - 1)) / columns;

        // 이미지 높이 = width / aspect
        final imageH = itemW / imageAspect;

        // ----- 텍스트 블록: RoomOwner 4줄 / Searcher 3줄 -----
        final fsBody = ResponsiveSizes.f(context, 13);
        final iconS = ResponsiveSizes.f(context, 12);
        final gapSmall = ResponsiveSizes.p(context, 8) * 0.72;
        final padTB = ResponsiveSizes.p(context, 10) * 2;

        final rowH = (fsBody > iconS ? fsBody : iconS) * 1.30;
        final rowCount = _isRoomOwner ? 4 : 3;
        final textBlockH =
            padTB + (gapSmall * (rowCount - 1)) + (rowH * rowCount);

        // 필요하면 아래 주석 해제해 2dp만 더 얹기
        final baseSlack = ResponsiveSizes.p(context, 12);
        final scaleSlack = (textScale > 1.0 ? (textScale - 1.0) * fsBody : 0);
        final extraSlack4 = ResponsiveSizes.p(context, 4); // ← 추가 여유 4dp
        final mainExtent =
            imageH + textBlockH + baseSlack + scaleSlack + extraSlack4;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: GridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(outerPad),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: mainSpacing,
              mainAxisExtent: mainExtent,
            ),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return _isLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink();
              }
              final item = _items[index];
              if (_isRoomOwner && item is RoomOwnerPost) {
                return RoomOwnerPostContainer(
                  post: item,
                  imageAspect: imageAspect,
                );
              } else if (!_isRoomOwner && item is SearcherPost) {
                return SearcherPostContainer(
                  post: item,
                  imageAspect: imageAspect,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}
