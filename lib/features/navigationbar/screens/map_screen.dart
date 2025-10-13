import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:proj4dart/proj4dart.dart' as proj4;

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

const _NCP_KEY_ID = 'udl4f25p0c';
const _NCP_KEY = 'dNKTbZDrKK0ksqtoUEAldGQJL86c96pFgWqrGnKG';
const _DEV_CLIENT_ID = 'GtXY6mLUVHuqtjYd9TQo';
const _DEV_CLIENT_SECRET = 'RxLgj3LSvg';
const Duration _httpTimeout = Duration(seconds: 7);

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

  String _baseQuery = '';
  bool _lockOverlayOps = false;
  bool _isAnimatingCamera = false;

  static const double Z_ALL = 11.0;

  final Map<String, RoomOwnerPost> _ownerCache = {};
  final _searchCtrl = TextEditingController(text: '');
  final _searchFocus = FocusNode();

  NaverMapController? _controller;
  bool _loading = false;
  bool _zoomTo14OnNextIdle = false;

  late final proj4.Projection _wgs84;
  late final proj4.Projection _katec;

  final List<String> _recentSearches = [];
  List<PlaceInfo> _results = [];
  PlaceInfo? _selectedPlace;
  final List<NMarker> _markers = [];
  final Set<String> _relatedRegions = {};

  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  static const double _sheetMin = 0.10;
  static const double _sheetInit = 0.18;
  static const double _sheetMid = 0.35;
  static const double _sheetMax = 0.65;

  final RoomOwnerPostRepository _postRepo = RoomOwnerPostRepository();
  final UserRepository _userRepository = UserRepository();
  final Map<String, NMarker> _ownerMarkers = {};
  Timer? _viewportDebounce;
  String? _myGender;

  @override
  void initState() {
    super.initState();
    _wgs84 = proj4.Projection.get('EPSG:4326')!;
    _katec = proj4.Projection.add(
      'KATEC',
      '+proj=tmerc +lat_0=38 +lon_0=128 +k=0.9999 '
          '+x_0=400000 +y_0=600000 +ellps=bessel +units=m +no_defs '
          '+towgs84=-115.80,474.99,674.11,1.16,-2.31,-1.63,6.43',
    );
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

  NLatLng _tm128ToLatLng(num mapx, num mapy) {
    final tm = proj4.Point(x: mapx.toDouble(), y: mapy.toDouble());
    final wgs = _katec.transform(_wgs84, tm);
    return NLatLng(wgs.y, wgs.x);
  }

  NLatLng _localCoordsToLatLng(num mapx, num mapy) {
    final x = mapx.toDouble();
    final y = mapy.toDouble();
    if (x.abs() >= 1e8 && y.abs() >= 1e8) {
      final lon = x / 1e7;
      final lat = y / 1e7;
      return NLatLng(lat, lon);
    }
    return _tm128ToLatLng(x, y);
  }

  Future<http.Response?> _safeGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http.get(uri, headers: headers).timeout(_httpTimeout);
    } on TimeoutException {
      debugPrint('[HTTP] TIMEOUT: $uri');
      return null;
    } catch (e) {
      debugPrint('[HTTP] ERROR: $uri -> $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _searchLocalList(
    String keyword, {
    int display = 20,
  }) async {
    final uri = Uri.https('openapi.naver.com', '/v1/search/local.json', {
      'query': keyword,
      'display': '$display',
      'start': '1',
      'sort': 'random',
    });
    final res = await _safeGet(
      uri,
      headers: {
        'X-Naver-Client-Id': _DEV_CLIENT_ID,
        'X-Naver-Client-Secret': _DEV_CLIENT_SECRET,
        'Accept': 'application/json',
      },
    );
    if (res == null || res.statusCode != 200) return [];
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<_GeocodeResult?> _geocodeDetails(String query) async {
    final hosts = [
      'naveropenapi.apigw.ntruss.com',
      'naveropenapi.apigw.fin-ntruss.com',
    ];
    for (final host in hosts) {
      final uri = Uri.https(host, '/map-geocode/v2/geocode', {'query': query});
      final res = await _safeGet(
        uri,
        headers: {
          'X-NCP-APIGW-API-KEY-ID': _NCP_KEY_ID,
          'X-NCP-APIGW-API-KEY': _NCP_KEY,
          'Accept': 'application/json',
        },
      );
      if (res == null) continue;
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = (data['addresses'] as List?) ?? [];
        if (list.isEmpty) continue;
        final a = list.first as Map<String, dynamic>;
        final lat = double.tryParse(a['y']?.toString() ?? '');
        final lon = double.tryParse(a['x']?.toString() ?? '');
        if (lat == null || lon == null) continue;
        return _GeocodeResult(
          pos: NLatLng(lat, lon),
          roadAddress: (a['roadAddress'] as String?)?.trim(),
          jibunAddress: (a['jibunAddress'] as String?)?.trim(),
        );
      }
    }
    return null;
  }

  String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'</?b>'), '').replaceAll('&amp;', '&');

  String _extractRegion(String? addressOrRoad) {
    if (addressOrRoad == null || addressOrRoad.trim().isEmpty) return '';
    final parts = addressOrRoad.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
    return parts.first;
  }

  Future<List<PlaceInfo>> _buildPlacesFromLocalItems(
    List<Map<String, dynamic>> items,
  ) async {
    final List<PlaceInfo> list = [];
    final seen = <String>{};

    for (final m in items) {
      final title = _stripHtml((m['title'] ?? '').toString());
      final category = (m['category'] as String?)?.trim();
      final tel = (m['telephone'] as String?)?.trim();
      final road = (m['roadAddress'] as String?)?.trim();
      final addr = (m['address'] as String?)?.trim();

      NLatLng? pos;
      final mx = double.tryParse(m['mapx']?.toString() ?? '');
      final my = double.tryParse(m['mapy']?.toString() ?? '');
      if (mx != null && my != null) {
        pos = _localCoordsToLatLng(mx, my);
      } else {
        final chosen = (road != null && road.isNotEmpty) ? road : (addr ?? '');
        if (chosen.isNotEmpty) {
          final geo = await _geocodeDetails(chosen);
          pos = geo?.pos;
        }
      }
      if (pos == null) continue;

      final key = '${title}_${pos.latitude}_${pos.longitude}';
      if (!seen.add(key)) continue;

      list.add(
        PlaceInfo(
          pos: pos,
          title: title.isEmpty ? (road ?? addr ?? '알 수 없음') : title,
          address: addr,
          roadAddress: road,
          tel: tel,
          category: category,
        ),
      );
    }
    return list;
  }

  Future<void> _searchAndList(String raw, {bool refineByRegion = false}) async {
    if (_controller == null) return;
    final q = raw.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _selectedPlace = null;
    });

    try {
      final items = await _searchLocalList(q, display: 20);
      var places = await _buildPlacesFromLocalItems(items);

      if (places.isEmpty) {
        final g = await _geocodeDetails(q) ?? await _geocodeDetails('서울 $q');
        if (g != null) {
          places = [
            PlaceInfo(
              pos: g.pos,
              title: q,
              address: g.jibunAddress,
              roadAddress: g.roadAddress,
            ),
          ];
        }
      }

      await _refreshMarkers(places);

      final newRegions = places
          .map((p) => _extractRegion(p.displayAddress))
          .where((s) => s.isNotEmpty);

      setState(() {
        _results = places;

        if (refineByRegion) {
          _relatedRegions.addAll(newRegions);
        } else {
          _relatedRegions
            ..clear()
            ..addAll(newRegions);
          _baseQuery = q;
        }

        _recentSearches.removeWhere((e) => e == q);
        _recentSearches.insert(0, q);
        if (_recentSearches.length > 12) {
          _recentSearches.removeRange(12, _recentSearches.length);
        }
      });

      if (places.isNotEmpty) {
        await _focusOnPlace(
          places.first,
          animateZoom: false,
          collapseSheet: false,
        );
      }

      _searchFocus.unfocus();
      _animateSheet(_sheetMid);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshMarkers(List<PlaceInfo> places) async {
    if (_controller == null) return;

    for (final m in _markers) {
      try {
        if (m.isAdded) await _controller!.deleteOverlay(m.info);
      } catch (_) {}
    }
    _markers.clear();

    for (var i = 0; i < places.length; i++) {
      final p = places[i];
      final marker = NMarker(
        id: 'pin_${i}_${p.pos.latitude}_${p.pos.longitude}',
        position: p.pos,
      );

      marker.setOnTapListener((_) async {
        if (_controller == null) return;
        _lockOverlayOps = true;
        _isAnimatingCamera = true;

        setState(() {
          _selectedPlace = p;
          _selectedOwnerPost = null;
          _showOwnerPreview = false;
        });

        await Future<void>.delayed(const Duration(milliseconds: 16));
        final cu = (NCameraUpdate.scrollAndZoomTo(target: p.pos, zoom: 16)
          ..setAnimation(duration: const Duration(milliseconds: 350)));
        try {
          await _controller!.updateCamera(cu);
        } catch (_) {}

        _isAnimatingCamera = false;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        _lockOverlayOps = false;
      });

      await _controller!.addOverlay(marker);
      _markers.add(marker);
    }
  }

  Future<void> _focusOnPlace(
    PlaceInfo p, {
    bool animateZoom = true,
    bool collapseSheet = false,
  }) async {
    if (_controller == null) return;
    setState(() => _selectedPlace = p);

    final cu = animateZoom
        ? (NCameraUpdate.scrollAndZoomTo(target: p.pos, zoom: 16)
            ..setAnimation(duration: const Duration(milliseconds: 350)))
        : (NCameraUpdate.scrollAndZoomTo(target: p.pos)
            ..setAnimation(duration: const Duration(milliseconds: 250)));
    await _controller!.updateCamera(cu);

    if (collapseSheet) _animateSheet(_sheetInit);
  }

  void _animateSheet(double size) {
    try {
      _sheetCtrl.animateTo(
        size,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  void _toggleSheet() {
    try {
      final s = _sheetCtrl.size;
      final target = (s <= _sheetMin + 0.02) ? _sheetMid : _sheetMin;
      _animateSheet(target);
    } catch (_) {
      _animateSheet(_sheetMid);
    }
  }

  bool get _showSuggestionList =>
      _searchFocus.hasFocus && _recentSearches.isNotEmpty && !_loading;

  Future<({double minLat, double minLng, double maxLat, double maxLng})?>
  _getVisibleBounds() async {
    final ctrl = _controller;
    if (!mounted || ctrl == null) return null;
    try {
      final b = await ctrl.getContentBounds(withPadding: true);
      final lats = [b.northEast.latitude, b.southWest.latitude]..sort();
      final lngs = [b.northEast.longitude, b.southWest.longitude]..sort();
      return (
        minLat: lats.first,
        minLng: lngs.first,
        maxLat: lats.last,
        maxLng: lngs.last,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshOwnerMarkersForViewport() async {
    if (_controller == null || _lockOverlayOps || _isAnimatingCamera) return;

    final cam = await _controller!.getCameraPosition();
    if (cam.zoom < Z_ALL) return;

    final bounds = await _getVisibleBounds();
    if (bounds == null) return;

    final posts = await _postRepo.fetchOwnerPostsInBounds(
      minLat: bounds.minLat,
      minLng: bounds.minLng,
      maxLat: bounds.maxLat,
      maxLng: bounds.maxLng,
      limit: 250,
      myGender: null,
    );

    for (final p in posts) {
      final id = p.postId ?? '';
      if (id.isEmpty) continue;
      _ownerCache[id] = p;
    }

    final neededIds = posts.map((p) => p.postId).whereType<String>().toSet();

    for (final entry in _ownerMarkers.entries.toList()) {
      if (!neededIds.contains(entry.key)) {
        try {
          if (entry.value.isAdded)
            await _controller!.deleteOverlay(entry.value.info);
        } catch (_) {}
        _ownerMarkers.remove(entry.key);
      }
    }

    for (final id in neededIds) {
      if (_ownerMarkers.containsKey(id)) continue;
      final p = _ownerCache[id]!;
      final gp = p.addr;
      if (gp == null) continue;

      final marker = NMarker(
        id: 'owner_$id',
        position: NLatLng(gp.latitude, gp.longitude),
      );

      marker.setOnTapListener((_) async {
        if (_controller == null) return;
        _lockOverlayOps = true;
        _isAnimatingCamera = true;

        setState(() {
          _selectedOwnerPost = p;
          _showOwnerPreview = true;
          _selectedPlace = null;
          _selectedAuthor = null;
        });

        final uid = p.authorId;
        if (uid != null && uid.isNotEmpty) {
          _ensureAuthorLoaded(uid);
        }

        await Future<void>.delayed(const Duration(milliseconds: 16));
        final target = NLatLng(gp.latitude, gp.longitude);
        final cu = (NCameraUpdate.scrollAndZoomTo(target: target, zoom: 16)
          ..setAnimation(duration: const Duration(milliseconds: 350)));
        try {
          await _controller!.updateCamera(cu);
        } catch (_) {}

        _isAnimatingCamera = false;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        _lockOverlayOps = false;
      });

      await _controller!.addOverlay(marker);
      _ownerMarkers[id] = marker;
    }
  }

  Future<void> _showAllOwnerMarkersFromCache() async {
    if (_controller == null || _lockOverlayOps || _isAnimatingCamera) return;

    if (_ownerCache.isEmpty) {
      final all = await _postRepo.fetchAllPosts(limit: 1000, myGender: null);
      for (final p in all) {
        final id = p.postId ?? '';
        if (id.isEmpty) continue;
        _ownerCache[id] = p;
      }
    }

    for (final entry in _ownerCache.entries) {
      final id = entry.key;
      if (_ownerMarkers.containsKey(id)) continue;
      final p = entry.value;
      final gp = p.addr;
      if (gp == null) continue;

      final marker = NMarker(
        id: 'owner_$id',
        position: NLatLng(gp.latitude, gp.longitude),
      );

      marker.setOnTapListener((_) async {
        if (_controller == null) return;
        _lockOverlayOps = true;
        _isAnimatingCamera = true;

        setState(() {
          _selectedOwnerPost = p;
          _showOwnerPreview = true;
          _selectedPlace = null;
          _selectedAuthor = null;
        });

        final uid = p.authorId;
        if (uid != null && uid.isNotEmpty) {
          _ensureAuthorLoaded(uid);
        }

        await Future<void>.delayed(const Duration(milliseconds: 16));
        final target = NLatLng(gp.latitude, gp.longitude);
        final cu = (NCameraUpdate.scrollAndZoomTo(target: target, zoom: 16)
          ..setAnimation(duration: const Duration(milliseconds: 350)));
        try {
          await _controller!.updateCamera(cu);
        } catch (_) {}

        _isAnimatingCamera = false;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        _lockOverlayOps = false;
      });

      await _controller!.addOverlay(marker);
      _ownerMarkers[id] = marker;
    }
  }

  Future<void> _ensureAuthorLoaded(String uid) async {
    if (_userCache.containsKey(uid)) {
      setState(() => _selectedAuthor = _userCache[uid]);
      return;
    }

    setState(() => _loadingAuthor = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final user = AppUser.fromDoc(doc);
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
      final list = _recentSearches
          .where((s) => s.contains(key))
          .toList(growable: false);
      return list.isEmpty ? _recentSearches : list;
    }();

    final h = MediaQuery.of(context).size.height;
    final maxSuggestHeight = (h * 0.35).clamp(160.0, 260.0);
    final maxChipHeight = (h * 0.20).clamp(80.0, 140.0);

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveSizes.p(context, 8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveSizes.p(context, 18),
              ),
              child: NaverMap(
                onMapReady: (c) {
                  _controller = c;
                  _refreshOwnerMarkersForViewport();
                },
                onCameraChange: (reason, animated) {
                  if (reason == NCameraUpdateReason.location ||
                      reason == NCameraUpdateReason.control) {
                    _zoomTo14OnNextIdle = true;
                  }
                },
                onCameraIdle: () async {
                  final ctrl0 = _controller;
                  if (_zoomTo14OnNextIdle && ctrl0 != null) {
                    _zoomTo14OnNextIdle = false;
                    try {
                      final pos = await ctrl0.getCameraPosition();
                      final cu =
                          NCameraUpdate.scrollAndZoomTo(
                            target: pos.target,
                            zoom: 14,
                          )..setAnimation(
                            duration: const Duration(milliseconds: 250),
                          );
                      if (mounted) await ctrl0.updateCamera(cu);
                    } catch (_) {}
                  }

                  if (_lockOverlayOps || _isAnimatingCamera) return;

                  _viewportDebounce?.cancel();
                  _viewportDebounce = Timer(
                    const Duration(milliseconds: 250),
                    () async {
                      if (!mounted) return;
                      if (_lockOverlayOps || _isAnimatingCamera) return;
                      final ctrl = _controller;
                      if (ctrl == null) return;
                      try {
                        final cam = await ctrl.getCameraPosition();
                        if (cam.zoom < Z_ALL) {
                          await _showAllOwnerMarkersFromCache();
                        } else {
                          await _refreshOwnerMarkersForViewport();
                        }
                      } catch (_) {}
                    },
                  );
                },
                options: const NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: NLatLng(37.5665, 126.9780),
                    zoom: 13.5,
                  ),
                  locationButtonEnable: true,
                ),
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
                        border: InputBorder.none,
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

                if (_relatedRegions.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSizes.p(context, 12),
                          vertical: ResponsiveSizes.p(context, 4),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: (h * 0.20).clamp(80.0, 140.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            elevation: 2,
                            shadowColor: Colors.black12,
                            borderRadius: BorderRadius.circular(
                              ResponsiveSizes.p(context, 12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveSizes.p(context, 1),
                                vertical: ResponsiveSizes.p(context, 1),
                              ),
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: ResponsiveSizes.p(context, 8),
                                  runSpacing: ResponsiveSizes.p(context, 8),
                                  children: _relatedRegions.take(12).map((
                                    region,
                                  ) {
                                    final base = _baseQuery.isNotEmpty
                                        ? _baseQuery
                                        : _searchCtrl.text.trim();
                                    final query = base.isEmpty
                                        ? region
                                        : '$base $region';
                                    return ActionChip(
                                      backgroundColor: Colors.white,
                                      shape: const StadiumBorder(
                                        side: BorderSide(color: Colors.black12),
                                      ),
                                      label: Text(
                                        '# $region',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      onPressed: () => _searchAndList(
                                        query,
                                        refineByRegion: true,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          if (_results.isNotEmpty)
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
                              padding: EdgeInsets.only(
                                top: ResponsiveSizes.p(context, 8),
                                left: ResponsiveSizes.p(context, 12),
                                right: ResponsiveSizes.p(context, 8),
                                bottom: ResponsiveSizes.p(context, 8),
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p.displayAddress.isNotEmpty)
                                    Text(
                                      p.displayAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                  if ((p.tel ?? '').isNotEmpty)
                                    Text(
                                      p.tel!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  if ((p.category ?? '').isNotEmpty)
                                    Text(
                                      p.category!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                _lockOverlayOps = true;
                                _isAnimatingCamera = true;
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 16),
                                );
                                final cu =
                                    (NCameraUpdate.scrollAndZoomTo(
                                      target: p.pos,
                                      zoom: 16,
                                    )..setAnimation(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                    ));
                                try {
                                  await _controller?.updateCamera(cu);
                                } catch (_) {}
                                _isAnimatingCamera = false;
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 50),
                                );
                                _lockOverlayOps = false;
                              },
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
    );
  }
}

class PlaceInfo {
  final NLatLng pos;
  final String title;
  final String? address;
  final String? roadAddress;
  final String? tel;
  final String? category;

  PlaceInfo({
    required this.pos,
    required this.title,
    this.address,
    this.roadAddress,
    this.tel,
    this.category,
  });

  String get displayAddress => (roadAddress != null && roadAddress!.isNotEmpty)
      ? roadAddress!
      : (address ?? '');
}

class _GeocodeResult {
  final NLatLng pos;
  final String? roadAddress;
  final String? jibunAddress;

  const _GeocodeResult({
    required this.pos,
    this.roadAddress,
    this.jibunAddress,
  });
}
