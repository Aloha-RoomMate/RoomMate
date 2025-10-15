import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/class/searcher_post.dart';
import 'package:roommate/class/searcher_post_repository.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/features/navigationbar/widgets/feed_filter.dart';
import 'package:roommate/features/navigationbar/widgets/room_owner_post_container.dart';
import 'package:roommate/features/navigationbar/widgets/searcher_post_container.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/class/app_user.dart';

class PostListView extends StatefulWidget {
  final String postType; // 'roomOwner' | 'Searcher'

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
  AppUser? _me;

  late final Future<void> _initialLoadFuture;

  final _filter = FeedFilterController.instance;
  VoidCallback _filterListener = () {};

  bool get _isRoomOwnerList =>
      widget.postType.toLowerCase() == 'roomowner' ||
      widget.postType.toLowerCase() == 'room_owner' ||
      widget.postType.toLowerCase() == 'room-owner' ||
      widget.postType.toLowerCase() == 'room owner';

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _waitAuthThenFetch();
    _scrollController.addListener(_onScroll);

    _filterListener = () => setState(() {}); // Rebuild on filter change
    _filter.addListener(_filterListener);
  }

  @override
  void dispose() {
    _filter.removeListener(_filterListener);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _waitAuthThenFetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
    }
    _me = await _userRepository.fetchMe();
    _myGender = _me?.gender;
    await _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    if (_isRoomOwnerList) {
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
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    if (_isRoomOwnerList) {
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

  Future<List<Object>> _filterItems(List<Object> raw) async {
    final f = _filter.state;
    if (!f.isActive) {
      return raw;
    }

    List<Object> currentlyFiltered = List.from(raw);

    // Apply house filter
    if (f.isHouseFilterActive) {
      if (_isRoomOwnerList) {
        currentlyFiltered.retainWhere((item) => item is RoomOwnerPost && _matchesHouse(item, f));
      } else { // This is the Searcher list
        currentlyFiltered.retainWhere((item) => item is SearcherPost && _matchesSearcherHouseFilters(item, f));
      }
    }

    // Apply person filter
    if (f.isPersonFilterActive) {
      List<Object> personFiltered = [];
      for (final item in currentlyFiltered) {
        String? authorId;
        if (item is RoomOwnerPost) {
          authorId = item.authorId;
        } else if (item is SearcherPost) {
          authorId = item.authorId;
        }

        if (authorId != null) {
          final author = await _userRepository.fetchUserById(authorId);
          if (author != null && _matchesPerson(author, f)) {
            personFiltered.add(item);
          }
        }
      }
      currentlyFiltered = personFiltered;
    }

    return currentlyFiltered;
  }

  bool _matchesHouse(RoomOwnerPost p, FeedFilterState f) {
    if (f.depositMin != null && (p.deposit ?? 0) < f.depositMin!) return false;
    if (f.depositMax != null && (p.deposit ?? 1 << 30) > f.depositMax!)
      return false;

    if (f.rentMin != null && (p.rent ?? 0) < f.rentMin!) return false;
    if (f.rentMax != null && (p.rent ?? 1 << 30) > f.rentMax!) return false;

    if (f.manageMin != null && (p.manageFee ?? 0) < f.manageMin!) return false;
    if (f.manageMax != null && (p.manageFee ?? 1 << 30) > f.manageMax!)
      return false;

    if (f.contractMin != null || f.contractMax != null) {
      final a = p.minContract ?? 0;
      final b = p.maxContract ?? 1 << 30;
      final selMin = f.contractMin ?? 0;
      final selMax = f.contractMax ?? (1 << 30);
      final overlap = (a <= selMax) && (b >= selMin);
      if (!overlap) return false;
    }
    return true;
  }

  bool _matchesSearcherHouseFilters(SearcherPost p, FeedFilterState f) {
    // Deposit
    if (f.depositMin != null && (p.deposit ?? 0) < f.depositMin!) return false;
    if (f.depositMax != null && (p.deposit ?? 1 << 30) > f.depositMax!) return false;

    // Rent
    if (f.rentMin != null || f.rentMax != null) {
      final searcherMinRent = p.minRent ?? 0;
      final searcherMaxRent = p.maxRent ?? (1 << 30);
      final filterMinRent = f.rentMin ?? 0;
      final filterMaxRent = f.rentMax ?? (1 << 30);
      final overlap = (searcherMinRent <= filterMaxRent) && (searcherMaxRent >= filterMinRent);
      if (!overlap) return false;
    }

    // Contract Period
    if (f.contractMin != null || f.contractMax != null) {
      final searcherMinContract = p.minContract ?? 0;
      final searcherMaxContract = p.maxContract ?? (1 << 30);
      final filterMinContract = f.contractMin ?? 0;
      final filterMaxContract = f.contractMax ?? (1 << 30);
      final overlap = (searcherMinContract <= filterMaxContract) && (searcherMaxContract >= filterMinContract);
      if (!overlap) return false;
    }

    return true;
  }

  bool _matchesPerson(AppUser u, FeedFilterState f) {
    final userColiving = u.coliving;
    final filterColiving = f.colivingFilter;

    if (userColiving == null || filterColiving == null) return true;

    if (filterColiving.coSpace.isNotEmpty &&
        userColiving.coSpace != filterColiving.coSpace) return false;
    if (filterColiving.interaction.isNotEmpty &&
        userColiving.interaction != filterColiving.interaction) return false;
    if (filterColiving.cleanOption.isNotEmpty &&
        userColiving.cleanOption != filterColiving.cleanOption) return false;
    if (filterColiving.bathroom.isNotEmpty &&
        userColiving.bathroom != filterColiving.bathroom) return false;
    if (filterColiving.smoking && !userColiving.smoking) return false;
    if (filterColiving.pet.isNotEmpty &&
        !filterColiving.pet.any((p) => userColiving.pet.contains(p)))
      return false;

    return true;
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

        return FutureBuilder<List<Object>>(
          future: _filterItems(_items),
          builder: (context, listSnap) {
            if (listSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final shown = listSnap.data ?? const <Object>[];

            const columns = 2;
            const imageAspect = 0.93;

            final outerPad = ResponsiveSizes.p(context, 12);
            final crossSpacing = ResponsiveSizes.p(context, 12);
            final mainSpacing = ResponsiveSizes.p(context, 12);

            final screenW = MediaQuery.of(context).size.width;
            final textScale = MediaQuery.textScaleFactorOf(context);

            final itemW =
                (screenW - (outerPad * 2) - crossSpacing * (columns - 1)) /
                    columns;
            final imageH = itemW / imageAspect;

            final fsBody = ResponsiveSizes.f(context, 13);
            final iconS = ResponsiveSizes.f(context, 12);
            final gapSmall = ResponsiveSizes.p(context, 8) * 0.72;
            final padTB = ResponsiveSizes.p(context, 10) * 2;
            final rowH = (fsBody > iconS ? fsBody : iconS) * 1.30;
            final rowCount = _isRoomOwnerList ? 4 : 3;
            final textBlockH =
                padTB + (gapSmall * (rowCount - 1)) + (rowH * rowCount);

            final baseSlack = ResponsiveSizes.p(context, 12);
            final scaleSlack = (textScale > 1.0
                ? (textScale - 1.0) * fsBody
                : 0);
            final extraSlack4 = ResponsiveSizes.p(context, 4);
            final mainExtent =
                imageH + textBlockH + baseSlack + scaleSlack + extraSlack4;

            final state = _filter.state;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.isActive)
                    SliverToBoxAdapter(
                      child: FeedFilterChips(
                        state: state,
                        onOpenSheet: () {
                          FeedFilterBottomSheet.show(context);
                        },
                        onClear: () => _filter.clear(),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.all(outerPad),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == shown.length) {
                            return _hasMore
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : const SizedBox.shrink();
                          }
                          final item = shown[index];
                          if (_isRoomOwnerList && item is RoomOwnerPost) {
                            return RoomOwnerPostContainer(
                              post: item,
                              imageAspect: imageAspect,
                            );
                          } else if (!_isRoomOwnerList &&
                              item is SearcherPost) {
                            return SearcherPostContainer(
                              post: item,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        childCount: shown.length + (_hasMore ? 1 : 0),
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: crossSpacing,
                        mainAxisSpacing: mainSpacing,
                        mainAxisExtent: mainExtent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}