import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/features/navigationbar/widgets/owner_preview_card.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';
import 'package:roommate/class/chat_repository.dart';
import 'package:roommate/features/chat/chat_screen.dart';

import 'package:roommate/constants/responsive_sizes.dart';
import 'package:roommate/constants/gaps.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Map<String, AppUser?> _userCache = {};
  AppUser? _selectedAuthor;
  bool _loadingAuthor = false;

  RoomOwnerPost? _selectedOwnerPost;
  bool _showOwnerPreview = false;

  bool _lockOverlayOps = false;
  bool _isAnimatingCamera = false;

  static const double Z_ALL = 11.0;

  final Map<String, RoomOwnerPost> _ownerCache = {};
  final _searchCtrl = TextEditingController(text: '');
  final _searchFocus = FocusNode();

  GoogleMapController? _controller;
  bool _loading = false;

  final List<String> _recentSearches = [];
  List<PlaceInfo> _results = [];
  PlaceInfo? _selectedPlace;
  Set<Marker> _searchMarkers = {};

  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  static const double _sheetMin = 0.10;
  static const double _sheetInit = 0.18;
  static const double _sheetMid = 0.35;
  static const double _sheetMax = 0.65;

  final RoomOwnerPostRepository _postRepo = RoomOwnerPostRepository();
  final UserRepository _userRepository = UserRepository();
  Map<String, Marker> _ownerMarkers = {};
  Timer? _viewportDebounce;
  String? _myGender;

  @override
  void initState() {
    super.initState();
    _fetchUserGender();
  }

  Future<void> _fetchUserGender() async {
    final appUser = await _userRepository.fetchMe();
    if (mounted) {
      setState(() {
        _myGender = appUser?.gender;
      });
    }
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _searchAndList(String raw) async {
    if (_controller == null) return;
    final query = raw.trim();
    if (query.isEmpty) return;

    _searchFocus.unfocus();
    setState(() {
      _loading = true;
      _selectedPlace = null;
      _results.clear();
      _searchMarkers.clear();
      _showOwnerPreview = false;
    });

    try {
      final locations = await geocoding.locationFromAddress(query);
      if (!mounted) return;

      if (locations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 결과가 없습니다.')),
        );
        return;
      }

      final places = <PlaceInfo>[];
      final newMarkers = <Marker>{};
      for (var i = 0; i < locations.length; i++) {
        final loc = locations[i];
        final place = PlaceInfo(
          pos: LatLng(loc.latitude, loc.longitude),
          title: query,
        );
        places.add(place);
        newMarkers.add(
          Marker(
            markerId: MarkerId('search_$i'),
            position: place.pos,
            infoWindow: InfoWindow(title: place.title),
            onTap: () => _onSearchMarkerTapped(place),
          ),
        );
      }

      setState(() {
        _results = places;
        _searchMarkers = newMarkers;
        if (places.isNotEmpty) {
          _selectedPlace = places.first;
        }
        _recentSearches.removeWhere((e) => e == query);
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 12) {
          _recentSearches.removeRange(12, _recentSearches.length);
        }
      });

      if (places.isNotEmpty) {
        await _focusOnPlace(places.first, animateZoom: true);
      }
      _animateSheet(_sheetMid);
    } catch (e) {
      debugPrint('[GEOCODING] ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주소를 좌표로 변환하는 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchMarkerTapped(PlaceInfo place) {
    setState(() {
      _selectedPlace = place;
      _selectedOwnerPost = null;
      _showOwnerPreview = false;
    });
    _focusOnPlace(place, animateZoom: true);
  }

  Future<void> _focusOnPlace(PlaceInfo p, {bool animateZoom = true}) async {
    if (_controller == null) return;
    final zoom = await _controller!.getZoomLevel();
    final cu = CameraUpdate.newCameraPosition(
      CameraPosition(target: p.pos, zoom: animateZoom ? 15 : zoom),
    );
    await _controller!.animateCamera(cu);
  }

  void _animateSheet(double size) {
    _sheetCtrl.animateTo(
      size,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleSheet() {
    final s = _sheetCtrl.size;
    final target = (s <= _sheetMin + 0.02) ? _sheetMid : _sheetMin;
    _animateSheet(target);
  }

  bool get _showSuggestionList =>
      _searchFocus.hasFocus && _recentSearches.isNotEmpty && !_loading;

  Future<LatLngBounds?> _getVisibleBounds() async {
    if (!mounted || _controller == null) return null;
    try {
      return await _controller!.getVisibleRegion();
    } catch (e) {
      debugPrint('[MAP] getVisibleBounds error: $e');
      return null;
    }
  }

  void _showMarkerInfo() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 80),
          duration: Duration(seconds: 3),
          content: Text('마커는 실제 집에서 반경 200m 내에 랜덤으로 찍힌 부분입니다.'),
        ),
      );
  }

  Future<void> _refreshOwnerMarkersForViewport() async {
    if (_controller == null || _lockOverlayOps || _isAnimatingCamera) return;

    final zoom = await _controller!.getZoomLevel();
    if (zoom < Z_ALL) {
      // If zoomed out too far, show all markers from cache instead
      await _showAllOwnerMarkersFromCache();
      return;
    }

    final bounds = await _getVisibleBounds();
    if (bounds == null) return;

    final posts = await _postRepo.fetchOwnerPostsInBounds(
      minLat: bounds.southwest.latitude,
      minLng: bounds.southwest.longitude,
      maxLat: bounds.northeast.latitude,
      maxLng: bounds.northeast.longitude,
      limit: 250,
      myGender: _myGender,
    );

    final newMarkers = <String, Marker>{};
    for (final p in posts) {
      final id = p.postId ?? '';
      if (id.isEmpty) continue;
      _ownerCache[id] = p;

      final gp = p.coordinate;
      if (gp == null) continue;

      final markerId = MarkerId('owner_$id');
      newMarkers[id] = Marker(
        markerId: markerId,
        position: LatLng(gp.latitude, gp.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: () => _onOwnerMarkerTapped(p),
      );
    }

    if (mounted) {
      setState(() {
        _ownerMarkers = newMarkers;
      });
    }
  }

  Future<void> _showAllOwnerMarkersFromCache() async {
    if (_controller == null || _lockOverlayOps || _isAnimatingCamera) return;

    if (_ownerCache.isEmpty) {
      final all = await _postRepo.fetchAllPosts(
        limit: 1000,
        myGender: _myGender,
      );
      for (final p in all) {
        final id = p.postId ?? '';
        if (id.isEmpty) continue;
        _ownerCache[id] = p;
      }
    }

    final newMarkers = <String, Marker>{};
    for (final entry in _ownerCache.entries) {
      final id = entry.key;
      final p = entry.value;
      final gp = p.coordinate;
      if (gp == null) continue;

      newMarkers[id] = Marker(
        markerId: MarkerId('owner_$id'),
        position: LatLng(gp.latitude, gp.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: () => _onOwnerMarkerTapped(p),
      );
    }

    if (mounted) {
      setState(() {
        _ownerMarkers = newMarkers;
      });
    }
  }

  void _onOwnerMarkerTapped(RoomOwnerPost post) async {
    if (_controller == null) return;
    _lockOverlayOps = true;
    _isAnimatingCamera = true;

    setState(() {
      _selectedOwnerPost = post;
      _showOwnerPreview = true;
      _selectedPlace = null;
      _searchMarkers.clear();
    });

    final uid = post.authorId;
    if (uid != null && uid.isNotEmpty) {
      _ensureAuthorLoaded(uid);
    }

    final gp = post.coordinate;
    if (gp != null) {
      final target = LatLng(gp.latitude, gp.longitude);
      final zoom = await _controller!.getZoomLevel();
      final cu = CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom < 15 ? 15 : zoom),
      );
      try {
        await _controller!.animateCamera(cu);
      } catch (_) {}
    }

    _isAnimatingCamera = false;
    await Future.delayed(const Duration(milliseconds: 50));
    _lockOverlayOps = false;
  }

  Future<void> _ensureAuthorLoaded(String uid) async {
    if (_userCache.containsKey(uid)) {
      setState(() => _selectedAuthor = _userCache[uid]);
      return;
    }

    setState(() => _loadingAuthor = true);
    try {
      final user = await _userRepository.fetchUserById(uid);
      _userCache[uid] = user;
      if (!mounted) return;
      if (_selectedOwnerPost?.authorId == uid) {
        setState(() => _selectedAuthor = user);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _selectedAuthor = null);
    } finally {
      if (mounted) setState(() => _loadingAuthor = false);
    }
  }

  Future<void> _startChatWithOwner() async {
    final post = _selectedOwnerPost;
    final partnerUid = post?.authorId ?? '';
    if (partnerUid.isEmpty) return;

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    final chatRepo = ChatRepository();
    final chatRoomId = await chatRepo.createChatRoom(me.uid, partnerUid);

    if (!mounted) return;
    final partnerName = _selectedAuthor?.displayName ?? '사용자';
    final partnerPhoto = _selectedAuthor?.photoURL;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoomId: chatRoomId,
          partnerUid: partnerUid,
          partnerName: partnerName,
          partnerPhotoURL: partnerPhoto,
          quickPhrases: const ['안녕하세요!', '방 보러 가도 될까요?', '위치가 어디인가요?'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuggestions = () {
      final key = _searchCtrl.text.trim();
      if (key.isEmpty) return _recentSearches;
      return _recentSearches.where((s) => s.contains(key)).toList();
    }();

    final h = MediaQuery.of(context).size.height;
    final maxSuggestHeight = (h * 0.35).clamp(160.0, 260.0);

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveSizes.p(context, 8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveSizes.p(context, 18),
              ),
              child: GoogleMap(
                webGestureHandling: WebGestureHandling.greedy,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.5665, 126.9780), // Seoul City Hall
                  zoom: 13.5,
                ),
                onMapCreated: (c) {
                  _controller = c;
                  _refreshOwnerMarkersForViewport();
                },
                onCameraIdle: () {
                  if (_lockOverlayOps || _isAnimatingCamera) return;
                  _viewportDebounce?.cancel();
                  _viewportDebounce = Timer(
                    const Duration(milliseconds: 400),
                    () {
                      if (mounted && !_lockOverlayOps && !_isAnimatingCamera) {
                        _refreshOwnerMarkersForViewport();
                      }
                    },
                  );
                },
                markers: _searchMarkers.union(_ownerMarkers.values.toSet()),
                myLocationEnabled: true,

                // 기본 컨트롤 제거
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Gaps.v12(context),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSizes.p(context, 12),
                  ),
                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(
                      ResponsiveSizes.p(context, 12),
                    ),
                    shadowColor: Colors.black26,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchAndList,
                      decoration: InputDecoration(
                        hintText: '장소/주소 검색 :',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: ResponsiveSizes.f(context, 14),
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSizes.p(context, 14),
                          vertical: ResponsiveSizes.p(context, 12),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black87,
                        ),
                        suffixIcon: IconButton(
                          icon: _loading
                              ? SizedBox(
                                  width: ResponsiveSizes.p(context, 20),
                                  height: ResponsiveSizes.p(context, 20),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.black87,
                                ),
                          onPressed: _loading
                              ? null
                              : () => _searchAndList(_searchCtrl.text),
                          tooltip: '검색',
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                if (_showSuggestionList)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSizes.p(context, 12),
                      vertical: ResponsiveSizes.p(context, 8),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxSuggestHeight),
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(
                          ResponsiveSizes.p(context, 12),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: filteredSuggestions.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Colors.black12),
                          itemBuilder: (context, index) {
                            final item = filteredSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.history,
                                color: Colors.black54,
                              ),
                              title: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.black45,
                                ),
                                tooltip: '제거',
                                onPressed: () => setState(
                                  () => _recentSearches.remove(item),
                                ),
                              ),
                              onTap: () => _searchAndList(item),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_results.isNotEmpty && !_showOwnerPreview)
            DraggableScrollableSheet(
              controller: _sheetCtrl,
              initialChildSize: _sheetInit,
              minChildSize: _sheetMin,
              maxChildSize: _sheetMax,
              snap: true,
              snapSizes: const [_sheetMin, _sheetMid, _sheetMax],
              builder: (context, scrollController) {
                return SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(ResponsiveSizes.p(context, 16)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: ResponsiveSizes.p(context, 12),
                          spreadRadius: ResponsiveSizes.p(context, 2),
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ],
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: InkWell(
                            onTap: _toggleSheet,
                            child: Padding(
                              padding: EdgeInsets.all(
                                ResponsiveSizes.p(context, 8),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: ResponsiveSizes.p(context, 36),
                                    height: ResponsiveSizes.p(context, 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveSizes.p(context, 2),
                                      ),
                                    ),
                                  ),
                                  Gaps.v8(context),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Gaps.h8(context),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '검색 결과 ${_results.length}개',
                                              style: TextStyle(
                                                fontSize: ResponsiveSizes.f(
                                                  context,
                                                  14,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if (_selectedPlace != null) ...[
                                              Gaps.v4(context),
                                              Text(
                                                _selectedPlace!.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: ResponsiveSizes.f(
                                                    context,
                                                    18,
                                                  ),
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              if (_selectedPlace!
                                                  .displayAddress
                                                  .isNotEmpty)
                                                Text(
                                                  _selectedPlace!
                                                      .displayAddress,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: ResponsiveSizes.f(
                                                      context,
                                                      12,
                                                    ),
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: '접기/펼치기',
                                        icon: const Icon(
                                          Icons.unfold_more,
                                          color: Colors.black87,
                                        ),
                                        onPressed: _toggleSheet,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        SliverList.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => Divider(
                            endIndent: ResponsiveSizes.p(context, 20),
                            indent: ResponsiveSizes.p(context, 20),
                            height: 0,
                          ),
                          itemBuilder: (context, i) {
                            final p = _results[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                child: Text('${i + 1}'),
                              ),
                              title: Text(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                p.displayAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              onTap: () => _onSearchMarkerTapped(p),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (_showOwnerPreview && _selectedOwnerPost != null)
            OwnerPreviewCard(
              post: _selectedOwnerPost!,
              author: _selectedAuthor,
              loadingAuthor: _loadingAuthor,
              onClose: () => setState(() => _showOwnerPreview = false),
              onOpen: () {
                final post = _selectedOwnerPost;
                if (post == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoomOwnerPostView(post: post),
                  ),
                );
              },
              onChat: _startChatWithOwner,
            ),
        ],
      ),
      // ⬇⬇⬇ 왼쪽 하단으로 이동
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          left: ResponsiveSizes.p(context, 6),
          bottom: ResponsiveSizes.p(context, 6),
        ),
        child: FloatingActionButton.small(
          focusColor: Colors.white,
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          onPressed: _showMarkerInfo,
          tooltip: '마커 안내',
          child: const Icon(Icons.info_outline, size: 16),
        ),
      ),
    );
  }
}

class PlaceInfo {
  final LatLng pos;
  final String title;
  final String? address;
  final String? roadAddress;

  PlaceInfo({
    required this.pos,
    required this.title,
    this.address,
    this.roadAddress,
  });

  String get displayAddress => (roadAddress != null && roadAddress!.isNotEmpty)
      ? roadAddress!
      : (address ?? '');
}
