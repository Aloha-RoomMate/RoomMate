import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';

const _NCP_KEY_ID = 'udl4f25p0c';
const _NCP_KEY = 'dNKTbZDrKK0ksqtoUEAldGQJL86c96pFgWqrGnKG';

class RoomownerScreen extends StatefulWidget {
  const RoomownerScreen({super.key});

  @override
  State<RoomownerScreen> createState() => _RoomownerScreenState();
}

class _RoomownerScreenState extends State<RoomownerScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _addrCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final String _apiKey = "devU01TX0FVVEgyMDI1MDkwMjIxNTIzOTExNjEzOTc=";
  List<dynamic> _addresses = [];
  bool _isLoading = false;
  String _errorMessage = '';
  NaverMapController? _controller;
  final _searchFocus = FocusNode();
  final List<NMarker> _markers = [];

  bool get _isNextEnabled {
    return _addrCtrl.text.trim().isNotEmpty;
  }

  Future<NLatLng?> _geocodeDetails(String query) async {
    final hosts = [
      'naveropenapi.apigw.ntruss.com',
      'naveropenapi.apigw.fin-ntruss.com',
    ];
    for (final host in hosts) {
      final uri = Uri.https(host, '/map-geocode/v2/geocode', {'query': query});
      try {
        final res = await http.get(
          uri,
          headers: {
            'X-NCP-APIGW-API-KEY-ID': _NCP_KEY_ID,
            'X-NCP-APIGW-API-KEY': _NCP_KEY,
            'Accept': 'application/json',
          },
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final list = (data['addresses'] as List?) ?? [];
          if (list.isEmpty) continue;
          final a = list.first as Map<String, dynamic>;
          final lat = double.tryParse(a['y']?.toString() ?? '');
          final lon = double.tryParse(a['x']?.toString() ?? '');
          if (lat != null && lon != null) {
            return NLatLng(lat, lon);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _refreshMarkers(List<NLatLng> points) async {
    if (_controller == null) return;

    // 기존 마커 제거
    for (final m in _markers) {
      try {
        if (m.isAdded) await _controller!.deleteOverlay(m.info);
      } catch (_) {}
    }
    _markers.clear();

    // 새 마커 추가
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final marker = NMarker(
        id: 'pin_${i}_${p.latitude}_${p.longitude}',
        position: p,
      );
      await _controller!.addOverlay(marker);
      _markers.add(marker);
    }
  }

  Future<void> _focusOnLatLng(NLatLng pos, {double zoom = 16}) async {
    if (_controller == null) return;
    final cu = NCameraUpdate.scrollAndZoomTo(target: pos, zoom: zoom)
      ..setAnimation(duration: const Duration(milliseconds: 350));
    await _controller!.updateCamera(cu);
  }

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
      'confmKey': _apiKey,
      'currentPage': '1',
      'countPerPage': '20',
      'keyword': keyword,
      'resultType': 'json',
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
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
          final commonData = decodedData['results']['common'];
          setState(() {
            _errorMessage = commonData['errorMessage'] ?? '알 수 없는 오류가 발생했습니다.';
            _addresses = [];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'API 서버 오류: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '데이터 요청 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNextTap() {
    if (_addresses.isNotEmpty || _isLoading || _errorMessage.isNotEmpty) return;

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
              const SizedBox(height: 12),
              Gaps.v12,
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _addrCtrl,
                      decoration: const InputDecoration(
                        hintText: '주소 입력',
                        border: OutlineInputBorder(),
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
                SizedBox(
                  height: 300,
                  child: _buildResults(),
                ),

              Gaps.v12,
              Wrap(
                children: [],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 350,
                      width: 350,
                      child: NaverMap(),
                    ),
                  ),
                ],
              ),

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

  Widget _buildResults() {
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
          final address = _addresses[index];
          return GestureDetector(
            onTap: () async {
              final road = address['roadAddr'] as String? ?? '';
              setState(() {
                _addrCtrl.text = road;
                _addresses = [];
                _searchCtrl.clear();
              });
              final pos = await _geocodeDetails(
                road.isNotEmpty ? road : (address['jibunAddr'] ?? ''),
              );
              if (pos != null) {
                await _refreshMarkers([pos]); // 📍 마커 1개 찍기
                await _focusOnLatLng(pos); // 🎥 카메라 이동
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('좌표를 찾을 수 없어요. 다른 주소를 시도해 보세요.'),
                  ),
                );
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(address['roadAddr'] ?? '도로명 주소 없음'),
                subtitle: Text('[지번] ${address['jibunAddr'] ?? '지번 주소 없음'}'),
              ),
            ),
          );
        },
      );
    }
  }
}
