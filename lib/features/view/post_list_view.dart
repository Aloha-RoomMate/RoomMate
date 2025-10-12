import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/searcher_post_repository.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/features/navigationbar/widgets/room_owner_post_container.dart';
import 'package:roommate/features/navigationbar/widgets/searcher_post_container.dart';
import 'package:roommate/constants/responsive_sizes.dart';

class PostListView extends StatefulWidget {
  final String postType;

  const PostListView({super.key, required this.postType});

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView> {
  static const _pageSize = 20;

  final RoomOwnerPostRepository _ownerRepo = RoomOwnerPostRepository();
  final SearcherPostRepository _searcherRepo = SearcherPostRepository();
  final UserRepository _userRepository = UserRepository();
  final ScrollController _scrollController = ScrollController();

  final List<Object> _items = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _myGender;

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
      await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
    }
    final appUser = await _userRepository.fetchMe();
    if (mounted) {
      setState(() {
        _myGender = appUser?.gender;
      });
    }
    await _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    if (_isRoomOwner) {
      final res = await _ownerRepo.fetchPosts(
        postType: 'roomOwner',
        myGender: _myGender,
      );
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
      final res = await _searcherRepo.fetchPosts(
        postType: 'Searcher',
        myGender: _myGender,
      );
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
        myGender: _myGender,
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
        myGender: _myGender,
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

        const columns = 2;
        const imageAspect = 0.93;

        final outerPad = ResponsiveSizes.p(context, 12);
        final crossSpacing = ResponsiveSizes.p(context, 12);
        final mainSpacing = ResponsiveSizes.p(context, 12);

        final screenW = MediaQuery.of(context).size.width;
        final textScale = MediaQuery.textScaleFactorOf(context);

        final itemW =
            (screenW - (outerPad * 2) - crossSpacing * (columns - 1)) / columns;

        final imageH = itemW / imageAspect;

        final fsBody = ResponsiveSizes.f(context, 13);
        final iconS = ResponsiveSizes.f(context, 12);
        final gapSmall = ResponsiveSizes.p(context, 8) * 0.72;
        final padTB = ResponsiveSizes.p(context, 10) * 2;

        final rowH = (fsBody > iconS ? fsBody : iconS) * 1.30;
        final rowCount = _isRoomOwner ? 4 : 3;
        final textBlockH =
            padTB + (gapSmall * (rowCount - 1)) + (rowH * rowCount);

        final baseSlack = ResponsiveSizes.p(context, 12);
        final scaleSlack = (textScale > 1.0 ? (textScale - 1.0) * fsBody : 0);
        final extraSlack4 = ResponsiveSizes.p(context, 4);
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
