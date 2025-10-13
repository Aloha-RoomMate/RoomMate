import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:proj4dart/proj4dart.dart' as proj4;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/class/room_owner_post.dart';
import 'package:roommate/class/room_owner_post_repository.dart';
import 'package:roommate/features/navigationbar/widgets/owner_preview_card.dart';
import 'package:roommate/features/view/room_owner_post_view.dart';

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
  final Map<String, AppUser?> _userCache = {}; // authorId -> AppUser 캐시
  AppUser? _selectedAuthor; // 선택된 글의 작성자
  bool _loadingAuthor = false; // 작성자 로딩 표시
  RoomOwnerPost? _selectedOwnerPost; // 미리보기 대상 포스트
  bool _showOwnerPreview = false; // 미리보기 박스 표시 여부
  String _baseQuery = '';

  // 🔒 오버레이/카메라 동시작업 충돌 방지용 락
  bool _lockOverlayOps = false;
  bool _isAnimatingCamera = false;

  // 줌 상수
  static const double Z_ALL = 11.0;

  // 방주인 게시글 캐시 (데이터 보관용)
  final Map<String, RoomOwnerPost> _ownerCache = {}; // docId -> post
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

  // RoomOwner 마커 관리 상태
  final RoomOwnerPostRepository _postRepo = RoomOwnerPostRepository();
  final Map<String, NMarker> _ownerMarkers = {}; // docId -> marker
  Timer? _viewportDebounce;

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
    if (res == null || res.statusCode != 200) {
      debugPrint('[LOCAL] FAIL ${res?.statusCode} body=${res?.body}');
      return [];
    }

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

    // 기존 검색 마커 제거
    for (final m in _markers) {
      try {
        if (m.isAdded) {
          await _controller!.deleteOverlay(m.info);
        }
      } catch (_) {}
    }
    _markers.clear();

    // 새 검색 마커 생성
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
    } catch (e) {
      debugPrint('[SHEET] animateTo failed: $e');
    }
  }

  void _toggleSheet() {
    try {
      final s = _sheetCtrl.size;
      final target = (s <= _sheetMin + 0.02) ? _sheetMid : _sheetMin;
      _animateSheet(target);
    } catch (e) {
      _animateSheet(_sheetMid);
    }
  }

  bool get _showSuggestionList =>
      _searchFocus.hasFocus && _recentSearches.isNotEmpty && !_loading;

  Future<({double minLat, double minLng, double maxLat, double maxLng})?>
  _getVisibleBounds() async {
    if (_controller == null) return null;
    final b = await _controller!.getContentBounds(withPadding: true);
    final lats = [b.northEast.latitude, b.southWest.latitude]..sort();
    final lngs = [b.northEast.longitude, b.southWest.longitude]..sort();
    return (
      minLat: lats.first,
      minLng: lngs.first,
      maxLat: lats.last,
      maxLng: lngs.last,
    );
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
          if (entry.value.isAdded) {
            await _controller!.deleteOverlay(entry.value.info);
          }
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

        // 작성자 정보 로드 (있으면 캐시)
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
      final all = await _postRepo.fetchAllPosts(limit: 1000);
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
          // 1) 지도
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                // 줌 14 보정
                if (_zoomTo14OnNextIdle && _controller != null) {
                  _zoomTo14OnNextIdle = false;
                  final pos = await _controller!.getCameraPosition();
                  final cu = NCameraUpdate.scrollAndZoomTo(
                    target: pos.target,
                    zoom: 14,
                  )..setAnimation(duration: const Duration(milliseconds: 250));
                  await _controller!.updateCamera(cu);
                }

                // 🔒 락 중이면 마커 리프레시 스킵
                if (_lockOverlayOps || _isAnimatingCamera) return;

                _viewportDebounce?.cancel();
                _viewportDebounce = Timer(
                  const Duration(milliseconds: 250),
                  () async {
                    if (_lockOverlayOps || _isAnimatingCamera) return;
                    final cam = await _controller!.getCameraPosition();
                    if (cam.zoom < Z_ALL) {
                      await _showAllOwnerMarkersFromCache();
                    } else {
                      await _refreshOwnerMarkersForViewport();
                    }
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

          // 2) 상단 검색 UI
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: Colors.black26,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchAndList,
                      decoration: InputDecoration(
                        hintText: '장소/주소 검색 :',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black87,
                        ),
                        suffixIcon: IconButton(
                          icon: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxSuggestHeight),
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxChipHeight),
                          child: Material(
                            color: Colors.transparent,
                            elevation: 2,
                            shadowColor: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1,
                                vertical: 1,
                              ),
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
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

          // 3) 하단 검색 결과 시트
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          spreadRadius: 2,
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
                              padding: const EdgeInsets.only(
                                top: 8,
                                left: 12,
                                right: 8,
                                bottom: 8,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '검색 결과 ${_results.length}개',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if (_selectedPlace != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                _selectedPlace!.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 18,
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
                                                  style: const TextStyle(
                                                    fontSize: 12,
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
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index.isOdd) {
                                return const Divider(
                                  endIndent: 20,
                                  indent: 20,
                                  height: 0,
                                );
                              }
                              final itemIndex = index ~/ 2;
                              final p = _results[itemIndex];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  child: Text('${itemIndex + 1}'),
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
                                  // 안전하게 카메라 이동
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
                            childCount: _results.isNotEmpty
                                ? (_results.length * 2 - 1)
                                : 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // 4) 미리보기 카드 (맨 위)
          if (_showOwnerPreview && _selectedOwnerPost != null)
            OwnerPreviewCard(
              post: _selectedOwnerPost!,
              author: _selectedAuthor,
              loadingAuthor: _loadingAuthor,
              onClose: () => setState(() => _showOwnerPreview = false),
              onOpen: () {
                final post = _selectedOwnerPost;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RoomOwnerPostView(post: post!),
                  ),
                );
              },
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
