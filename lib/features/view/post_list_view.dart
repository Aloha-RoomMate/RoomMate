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

// (옵션) 추천 정렬용
import 'package:roommate/features/recommend/compatibility.dart';
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
  VoidCallback _filterListener = () {}; // ← late 이슈 방지: 기본 no-op

  // Searcher 필터 옵션 풀(현재 로드 기준)
  List<String> _areaPool = [];
  List<String> _roomPool = [];
  List<String> _payPool = [];

  bool get _isRoomOwnerList =>
      widget.postType.toLowerCase() == 'roomowner' ||
      widget.postType.toLowerCase() == 'room_owner' ||
      widget.postType.toLowerCase() == 'room-owner' ||
      widget.postType.toLowerCase() == 'room owner';

  FeedTarget get _target =>
      _isRoomOwnerList ? FeedTarget.roomOwner : FeedTarget.searcher;

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _waitAuthThenFetch();
    _scrollController.addListener(_onScroll);

    // 필터 변경 시 항상 갱신(타겟은 화면이 결정)
    _filterListener = () => _refresh();
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
      await FirebaseAuth.instance.authStateChanges().firstWhere(
        (u) => u != null,
      );
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
        _rebuildSearcherPools(); // owner에서는 사실상 비움
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
        _rebuildSearcherPools();
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
        _rebuildSearcherPools();
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
        _rebuildSearcherPools();
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

  // Searcher 글들의 옵션 풀 수집
  void _rebuildSearcherPools() {
    if (_isRoomOwnerList) {
      _areaPool = [];
      _roomPool = [];
      _payPool = [];
      return;
    }
    final areas = <String>{};
    final rooms = <String>{};
    final pays = <String>{};
    for (final it in _items) {
      if (it is SearcherPost) {
        for (final a in (it.wantArea ?? const <String>[])) {
          final s = a.trim();
          if (s.isNotEmpty) areas.add(s);
        }
        for (final r in (it.wantRoom ?? const <String>[])) {
          final s = r.trim();
          if (s.isNotEmpty) rooms.add(s);
        }
        for (final p in (it.wantPay ?? const <String>[])) {
          final s = p.trim();
          if (s.isNotEmpty) pays.add(s);
        }
      }
    }
    _areaPool = areas.toList()..sort();
    _roomPool = rooms.toList()..sort();
    _payPool = pays.toList()..sort();
  }

  // ───── 클라 필터/정렬 ─────

  bool _matchesOwner(RoomOwnerPost p, FeedFilterState f) {
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

  bool _matchesSearcher(SearcherPost p, FeedFilterState f) {
    if (f.depositMin != null && (p.deposit ?? 0) < f.depositMin!) return false;
    if (f.depositMax != null && (p.deposit ?? 1 << 30) > f.depositMax!)
      return false;

    if (f.searcherBudgetMin != null || f.searcherBudgetMax != null) {
      final a = p.minRent ?? 0;
      final b = p.maxRent ?? 1 << 30;
      final selMin = f.searcherBudgetMin ?? 0;
      final selMax = f.searcherBudgetMax ?? (1 << 30);
      final overlap = (a <= selMax) && (b >= selMin);
      if (!overlap) return false;
    }

    if (f.contractMin != null || f.contractMax != null) {
      final a = p.minContract ?? 0;
      final b = p.maxContract ?? 1 << 30;
      final selMin = f.contractMin ?? 0;
      final selMax = f.contractMax ?? (1 << 30);
      final overlap = (a <= selMax) && (b >= selMin);
      if (!overlap) return false;
    }

    // 희망 지역
    if ((f.wantAreas?.isNotEmpty ?? false)) {
      final areas = (p.wantArea ?? const <String>[])
          .map((e) => e.trim())
          .toSet();
      if (areas.intersection(f.wantAreas!).isEmpty) return false;
    }
    // 희망 방 종류
    if ((f.wantRooms?.isNotEmpty ?? false)) {
      final rooms = (p.wantRoom ?? const <String>[])
          .map((e) => e.trim())
          .toSet();
      if (rooms.intersection(f.wantRooms!).isEmpty) return false;
    }
    // 희망 지불 구조
    if ((f.wantPays?.isNotEmpty ?? false)) {
      final pays = (p.wantPay ?? const <String>[]).map((e) => e.trim()).toSet();
      if (pays.intersection(f.wantPays!).isEmpty) return false;
    }

    return true;
  }

  DateTime _createdAtOf(Object o) {
    if (o is RoomOwnerPost)
      return o.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (o is SearcherPost)
      return o.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<List<Object>> _applyFilterAndSort(List<Object> raw) async {
    final f = _filter.state;

    // 1) 필터링
    final filtered = <Object>[];
    if (_isRoomOwnerList) {
      for (final it in raw) {
        if (it is RoomOwnerPost && _matchesOwner(it, f)) filtered.add(it);
      }
    } else {
      for (final it in raw) {
        if (it is SearcherPost && _matchesSearcher(it, f)) filtered.add(it);
      }
    }

    // 2) 정렬 (거리순 제거)
    switch (f.sort) {
      case FeedSort.newest:
        filtered.sort((a, b) => _createdAtOf(b).compareTo(_createdAtOf(a)));
        break;
      case FeedSort.oldest:
        filtered.sort((a, b) => _createdAtOf(a).compareTo(_createdAtOf(b)));
        break;
      case FeedSort.recommend:
        {
          if (_isRoomOwnerList) break; // Owner글에는 추천정렬 없음
          if (_me == null) break;
          final scores = <String, double>{};
          for (final it in filtered) {
            if (it is SearcherPost && it.authorId != null) {
              final other = await _userRepository.fetchUserById(it.authorId!);
              if (other != null) {
                final comp = scoreUsers(_me!, other);
                final s =
                    0.70 * comp.structSim +
                    0.15 * comp.hobbySim +
                    0.15 * comp.textSim;
                scores[it.postId ?? it.authorId!] = s;
              }
            }
          }
          filtered.sort((a, b) {
            double sa = 0, sb = 0;
            if (a is SearcherPost)
              sa = scores[a.postId ?? a.authorId ?? ''] ?? 0;
            if (b is SearcherPost)
              sb = scores[b.postId ?? b.authorId ?? ''] ?? 0;
            return sb.compareTo(sa);
          });
        }
        break;
      case FeedSort.payMatch:
      case FeedSort.roomMatch:
      case FeedSort.distance:
        // 미사용/확장용
        break;
    }

    return filtered;
  }

  // ─────────────────────────────────────────────

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
          future: _applyFilterAndSort(_items),
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
                  // ✅ 현재 탭(Target) 기준으로 활성 조건이 있을 때만 칩 표시
                  if (state.isActiveForTarget(_target))
                    SliverToBoxAdapter(
                      child: FeedFilterChips(
                        target: _target,
                        state: state,
                        onOpenSheet: () {
                          FeedFilterBottomSheet.show(
                            context,
                            _me,
                            target: _target,
                            areas: _areaPool,
                            rooms: _roomPool,
                            pays: _payPool,
                          );
                        },
                        onClear: () => _filter.clear(_target),
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
