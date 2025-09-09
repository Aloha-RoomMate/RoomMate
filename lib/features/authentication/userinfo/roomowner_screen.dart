import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommate/class/user_repository.dart';
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';
import 'package:roommate/features/navigationbar/main_navigation.dart';

const _NCP_KEY_ID = 'udl4f25p0c';
const _NCP_KEY = 'dNKTbZDrKK0ksqtoUEAldGQJL86c96pFgWqrGnKG';

const _JUSO_KEY = "devU01TX0FVVEgyMDI1MDkwMjIxNTIzOTExNjEzOTc=";

class RoomownerScreen extends StatefulWidget {
  final String userType;
  final String jobKinds;

  const RoomownerScreen({
    super.key,
    required this.userType,
    required this.jobKinds,
  });

  @override
  State<RoomownerScreen> createState() => _RoomownerScreenState();
}

class _RoomownerScreenState extends State<RoomownerScreen> {
  final TextEditingController _addrCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _addresses = [];
  bool _isLoading = false;
  String _errorMessage = '';

  NaverMapController? _controller;
  bool _mapReady = false;
  List<NLatLng> _pendingPoints = [];
  final List<NMarker> _markers = [];

  bool get _isNextEnabled => _addrCtrl.text.trim().isNotEmpty;

  Future<http.Response?> _safeGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[HTTP] GET error: $e');
      return null;
    }
  }

  Future<NLatLng?> _coordsFromJusoItem(Map<String, dynamic> item) async {
    final bdMgtSn = (item['bdMgtSn'] ?? '').toString().trim();

    Map<String, String> params;
    if (bdMgtSn.isNotEmpty) {
      params = {
        'confmKey': _JUSO_KEY,
        'resultType': 'json',
        'bdMgtSn': bdMgtSn,
      };
    } else {
      String s(dynamic v) => (v ?? '').toString().trim();
      params = {
        'confmKey': _JUSO_KEY,
        'resultType': 'json',
        'admCd': s(item['admCd']),
        'rnMgtSn': s(item['rnMgtSn']),
        'udrtYn': s(item['udrtYn']),
        'buldMnnm': s(item['buldMnnm']),
        'buldSlno': s(item['buldSlno']),
      };
      // 필수값 빠지면 coord 호출 의미 없음
      final requiredKeys = [
        'admCd',
        'rnMgtSn',
        'udrtYn',
        'buldMnnm',
        'buldSlno',
      ];
      final hasAll = requiredKeys.every((k) => (params[k] ?? '').isNotEmpty);
      if (!hasAll) return null;
    }

    final uri = Uri.https(
      'www.juso.go.kr',
      '/addrlink/addrCoordApi.do',
      params,
    );
    final res = await _safeGet(uri);
    if (res == null || res.statusCode != 200) return null;

    try {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as Map<String, dynamic>?;
      final jusoList = (results?['juso'] as List?) ?? [];
      if (jusoList.isEmpty) {
        debugPrint('[JUSO-COORD] empty');
        return null;
      }
      final j = jusoList.first as Map<String, dynamic>;
      // 공식 응답 좌표 필드: entX/entY (WGS84로 내려오는 경우가 많음)
      final entX = double.tryParse((j['entX'] ?? '').toString());
      final entY = double.tryParse((j['entY'] ?? '').toString());
      if (entX != null && entY != null) {
        return NLatLng(entY, entX);
      }
    } catch (e) {
      debugPrint('[JUSO-COORD] parse error: $e');
    }
    return null;
  }

  // -----------------------
  // 2) 검색 항목 내부의 좌표 필드 바로 사용 (fallback)
  //    wgsX/wgsY → entX/entY → x/y(스케일 보정)
  // -----------------------
  NLatLng? _coordsFromSearchItemFallback(Map<String, dynamic> item) {
    double? d(dynamic v) => double.tryParse((v ?? '').toString().trim());

    // 1순위: WGS84 직교(십진)
    final wgsX = d(item['wgsX']);
    final wgsY = d(item['wgsY']);
    if (wgsX != null && wgsY != null) return NLatLng(wgsY, wgsX);

    // 2순위: entX/entY (실무에서 거의 WGS84 십진)
    final entX = d(item['entX']);
    final entY = d(item['entY']);
    if (entX != null && entY != null) return NLatLng(entY, entX);

    // 3순위: x/y — 일부 응답에서 1e7 스케일로 오는 경우가 있어 보정
    var x = d(item['x']);
    var y = d(item['y']);
    if (x != null && y != null) {
      bool scaled(num v) => v.abs() > 1000000;
      if (scaled(x) || scaled(y)) {
        x = x / 1e7;
        y = y / 1e7;
      }
      if (x.abs() <= 180 && y.abs() <= 90) return NLatLng(y, x);
    }
    return null;
  }

  // -----------------------
  // 3) (보조) 네이버 지오코딩 — 문자열 정제 후 좌표
  // -----------------------
  Future<NLatLng?> _geocodeDetails(String query) async {
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
        try {
          final data = json.decode(res.body);
          final list = (data['addresses'] as List?) ?? [];
          if (list.isEmpty) continue;
          final a = list.first as Map<String, dynamic>;
          final lat = double.tryParse((a['y'] ?? '').toString());
          final lon = double.tryParse((a['x'] ?? '').toString());
          if (lat != null && lon != null) {
            return NLatLng(lat, lon);
          }
        } catch (e) {
          debugPrint('Geocode parse error: $e');
        }
      }
    }
    return null;
  }

  // -----------------------
  // 주소 검색(JUSO) — 기존과 동일
  // -----------------------
  Future<void> _searchAddress(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _errorMessage = '검색어를 입력해주세요.';
        _addresses = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.https('www.juso.go.kr', '/addrlink/addrLinkApi.do', {
      'confmKey': _JUSO_KEY,
      'currentPage': '1',
      'countPerPage': '20',
      'keyword': keyword,
      'resultType': 'json',
    });

    final response = await _safeGet(url);
    if (!mounted) return;

    try {
      if (response != null && response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['results'] != null &&
            decodedData['results']['juso'] != null) {
          setState(() {
            _addresses = decodedData['results']['juso'];
            if (_addresses.isEmpty) {
              _errorMessage = '검색 결과가 없습니다.';
            }
          });
        } else {
          final commonData = decodedData['results']?['common'];
          setState(() {
            _errorMessage =
                (commonData != null ? (commonData['errorMessage'] ?? '') : '')
                    .toString()
                    .trim();
            if (_errorMessage.isEmpty) {
              _errorMessage = '알 수 없는 오류가 발생했습니다.';
            }
            _addresses = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'API 서버 오류: ${response?.statusCode ?? '연결 실패'}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '데이터 요청 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // -----------------------
  // 지도 마커 갱신 (기존 컨트롤러 API만 사용 — addOverlay/deleteOverlay)
  // -----------------------
  Future<void> _refreshMarkers(List<NLatLng> points) async {
    if (!_mapReady || _controller == null) {
      _pendingPoints = points;
      return;
    }

    // 기존 마커 삭제
    for (final m in _markers) {
      try {
        if (m.isAdded) {
          await _controller!.deleteOverlay(m.info);
        }
      } catch (e) {
        debugPrint('deleteOverlay 실패: $e');
      }
    }
    _markers.clear();

    // 새 마커 추가
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final marker = NMarker(
        id: 'pin_${i}_${p.latitude}_${p.longitude}',
        position: p,
      );
      try {
        await _controller!.addOverlay(marker);
        _markers.add(marker);
      } catch (e) {
        debugPrint('addOverlay 실패: $e');
      }
    }
  }

  // 카메라 이동
  Future<void> _focusOnLatLng(NLatLng pos, {double zoom = 16}) async {
    if (!_mapReady || _controller == null) {
      _pendingPoints = [pos];
      return;
    }

    try {
      final cu = NCameraUpdate.scrollAndZoomTo(target: pos, zoom: zoom)
        ..setAnimation(duration: const Duration(milliseconds: 350));
      await _controller!.updateCamera(cu);
    } catch (e) {
      debugPrint('카메라 이동 실패: $e');
    }
  }

  // 다음 버튼 (기존 그대로)
  Future<void> _onNextTap() async {
    if (_addresses.isNotEmpty || _isLoading || _errorMessage.isNotEmpty) return;

    final address = _addrCtrl.text.trim();

    if (address.isNotEmpty) {
      try {
        await UserRepository().setUserTypeData(
          uid: FirebaseAuth.instance.currentUser!.uid,
          type: widget.userType,
          jobKinds: widget.jobKinds,
          address: address,
          searchAreas: null,
        );
      } catch (e) {
        debugPrint("저장 실패: $e");
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DailyRythmScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightCard = Theme.of(context).colorScheme.primary.withOpacity(0.08);

    return Scaffold(
      appBar: AppBar(title: const Text('거주지역 선택')),
      body: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '현재 거주하고있는 위치를 알려주세요',
                style: TextStyle(
                  fontSize: Sizes.size16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gaps.v12,
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _addrCtrl,
                      decoration: InputDecoration(
                        hintText: '주소 입력',
                        border: const OutlineInputBorder(),
                        focusColor: Theme.of(context).primaryColor,
                      ),
                      onSubmitted: (value) => _searchAddress(value),
                    ),
                  ),
                ],
              ),
              Gaps.v16,
              if (_addresses.isNotEmpty ||
                  _isLoading ||
                  _errorMessage.isNotEmpty)
                SizedBox(height: 300, child: _buildResults(lightCard)),
              Gaps.v12,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 350,
                      width: 350,
                      child: NaverMap(
                        options: const NaverMapViewOptions(
                          initialCameraPosition: NCameraPosition(
                            target: NLatLng(37.5665, 126.9780), // 초기 위치(서울)
                            zoom: 12,
                          ),
                        ),
                        onMapReady: (controller) async {
                          _controller = controller;
                          _mapReady = true;

                          // 준비 전 보류된 작업 처리
                          if (_pendingPoints.isNotEmpty) {
                            final first = _pendingPoints.first;
                            await _refreshMarkers(_pendingPoints);
                            await _focusOnLatLng(first);
                            _pendingPoints = [];
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
              GestureDetector(
                onTap: _onNextTap,
                child: FormButton(
                  disabled: !_isNextEnabled,
                  text: "다음",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(Color lightCard) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    } else if (_addresses.isEmpty) {
      return const SizedBox();
    } else {
      return ListView.builder(
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index] as Map<String, dynamic>;
          return Card(
            color: lightCard, // 연한 카드 색
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text('${index + 1}'),
              ),
              title: Text(address['roadAddr'] ?? '도로명 주소 없음'),
              subtitle: Text('[지번] ${address['jibunAddr'] ?? '지번 주소 없음'}'),
              onTap: () async {
                final road = (address['roadAddr'] as String?) ?? '';
                setState(() {
                  _addrCtrl.text = road;
                  _addresses = [];
                  _searchCtrl.clear();
                });

                // 1) 행안부 좌표 API 시도
                NLatLng? pos = await _coordsFromJusoItem(address);

                // 2) 검색응답 내부 좌표 필드 활용
                pos ??= _coordsFromSearchItemFallback(address);

                // 3) 네이버 지오코딩 보조 (괄호 등 제거 후)
                if (pos == null) {
                  final raw = road.isNotEmpty
                      ? road
                      : ((address['jibunAddr'] ?? '') as String);
                  final query = raw.split('(').first.trim();
                  pos = await _geocodeDetails(query);
                }

                if (!context.mounted) return;

                if (pos == null) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(
                      content: Text('좌표를 찾지 못했어요. 다른 주소를 시도해 보세요.'),
                    ),
                  );
                  return;
                }

                if (!_mapReady || _controller == null) {
                  _pendingPoints = [pos]; // 맵 준비 전이면 보류
                  return;
                }

                await _refreshMarkers([pos]);
                await _focusOnLatLng(pos);
              },
            ),
          );
        },
      );
    }
  }
}
