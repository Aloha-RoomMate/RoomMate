import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';

/// 기존 kSeoulGuDong은 제거하고, [kSeoulGu]만 사용합니다.
/// (동 데이터는 API에서 동적으로 로딩)
const List<String> kSeoulGu = [
  '강남구',
  '강동구',
  '강북구',
  '강서구',
  '관악구',
  '광진구',
  '구로구',
  '금천구',
  '노원구',
  '도봉구',
  '동대문구',
  '동작구',
  '마포구',
  '서대문구',
  '서초구',
  '성동구',
  '성북구',
  '송파구',
  '양천구',
  '영등포구',
  '용산구',
  '은평구',
  '종로구',
  '중구',
  '중랑구',
];

class SearcherScreen extends StatefulWidget {
  const SearcherScreen({super.key});
  @override
  State<SearcherScreen> createState() => _SearcherScreenState();
}

class _SearcherScreenState extends State<SearcherScreen> {
  // ---- 새로 추가된 상태들 ----
  final String _apiKey = 'devU01TX0FVVEgyMDI1MDkwMjIxNTIzOTExNjEzOTc=';
  final Map<String, List<String>> _dongCache = {}; // 구별 동 목록 캐시
  bool _isLoadingDongs = false;
  String _errorMessage = '';

  // ---- 기존 상태들 ----
  final Set<String> _fav = {}; // "구/동" 저장
  late final List<String> _guList = (kSeoulGu.toList()..sort());
  String? _selectedGu;

  bool get _isNextEnabled => _fav.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_guList.isNotEmpty) {
      _selectedGu = _guList.first;
      _fetchDongsForGu(_selectedGu!); // 첫 진입 시 첫 구의 동을 불러오기
    }
  }

  // ---- JUSO API에서 동 목록 로딩 ----
  Future<void> _fetchDongsForGu(String gu) async {
    if (_dongCache.containsKey(gu)) return; // 이미 가져온 구는 캐시 사용

    setState(() {
      _isLoadingDongs = true;
      _errorMessage = '';
    });

    try {
      // 페이지네이션을 몇 페이지까지 볼지 결정 (필요 시 조정)
      // 보통 동 이름 수집 목적이라 5페이지(=100건) 정도면 충분합니다.
      const int maxPages = 5;
      const int countPerPage = 20;

      final Set<String> emdSet = {}; // 중복 제거용
      for (int page = 1; page <= maxPages; page++) {
        final uri = Uri.https(
          'www.juso.go.kr',
          '/addrlink/addrLinkApi.do',
          {
            'confmKey': _apiKey, // 정확히 confmKey
            'currentPage': '1',
            'countPerPage': '20',
            'keyword': '서울특별시 $gu',
            'resultType': 'json',
          },
        );

        final res = await http.get(uri);
        if (res.statusCode != 200) {
          throw Exception('API 서버 오류: ${res.statusCode}');
        }

        final decoded = jsonDecode(res.body);
        final results = decoded['results'];
        if (results == null) break;

        final common = results['common'];
        final errorCode = common?['errorCode'];
        if (errorCode != '0') {
          final msg = common?['errorMessage'] ?? '알 수 없는 오류가 발생했습니다.';
          throw Exception('API 오류: $msg');
        }

        final List<dynamic>? juso = results['juso'];
        if (juso == null || juso.isEmpty) {
          // 더 이상 결과 없음 → 페이지 루프 종료
          break;
        }

        // 서울특별시, 선택한 구에 해당하는 결과만 필터하고 emdNm 수집
        for (final item in juso) {
          final si = item['siNm'] as String?; // 시/도
          final sgg = item['sggNm'] as String?; // 시/군/구
          final emd = item['emdNm'] as String?; // 읍/면/동 (행정동명)

          if (si == '서울특별시' &&
              sgg == gu &&
              emd != null &&
              emd.trim().isNotEmpty) {
            // 동 이름 뒤의 '동' 포함(예: '서교동'), 필요 시 정제 가능
            emdSet.add(emd.trim());
          }
        }

        // 다음 페이지 유효성: juso 수가 countPerPage보다 적으면 마지막 페이지로 판단
        if (juso.length < countPerPage) break;
      }

      final list = emdSet.toList()..sort((a, b) => a.compareTo(b));
      if (list.isEmpty) {
        setState(() {
          _dongCache[gu] = const [];
          _errorMessage = '검색 결과가 없습니다.';
        });
      } else {
        setState(() {
          _dongCache[gu] = list;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '동 목록을 불러오지 못했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoadingDongs = false;
      });
    }
  }

  void _toggleFav(String gu, String dong) {
    final key = '$gu/$dong';
    setState(() {
      if (_fav.contains(key)) {
        _fav.remove(key);
      } else {
        _fav.add(key);
      }
    });
  }

  void _onNextTap() {
    if (!_isNextEnabled) return;
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
    final primary = Theme.of(context).primaryColor;
    final dongs = _selectedGu == null
        ? <String>[]
        : (_dongCache[_selectedGu!] ?? <String>[]);

    return Scaffold(
      appBar: AppBar(title: const Text('희망 거주지역 선택')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(Sizes.size16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '서울 자치구와 동을 선택하세요',
                    style: TextStyle(
                      fontSize: Sizes.size16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 상단 컨텐트: 좌(구) : 우(동)
                  Expanded(
                    child: Row(
                      children: [
                        // 좌측: 자치구 목록
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              itemCount: _guList.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade300,
                              ),
                              itemBuilder: (context, index) {
                                final gu = _guList[index];
                                final selected = gu == _selectedGu;
                                final favCount = _fav
                                    .where((k) => k.startsWith('$gu/'))
                                    .length;

                                return Material(
                                  color: selected
                                      ? primary.withAlpha(50)
                                      : Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      gu,
                                      style: TextStyle(
                                        fontSize: Sizes.size12,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? primary
                                            : Colors.black87,
                                      ),
                                    ),
                                    trailing: favCount > 0
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$favCount',
                                                style: TextStyle(
                                                  color: primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() => _selectedGu = gu);
                                      _fetchDongsForGu(gu); // 구 변경 시 동 목록 로딩
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 우측: 선택한 자치구의 동 목록
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _selectedGu == null
                                ? const Center(child: Text('좌측에서 자치구를 선택하세요'))
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // 우측 헤더
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              _selectedGu!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (_isLoadingDongs)
                                              const Text('(로딩 중...)')
                                            else
                                              Text('(${dongs.length}개 동)'),
                                          ],
                                        ),
                                      ),

                                      // 동 리스트
                                      Expanded(
                                        child: _isLoadingDongs
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : _errorMessage.isNotEmpty
                                            ? Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Text(
                                                    _errorMessage,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                itemCount: dongs.length,
                                                separatorBuilder: (_, __) =>
                                                    Divider(
                                                      height: 1,
                                                      color:
                                                          Colors.grey.shade200,
                                                    ),
                                                itemBuilder: (context, idx) {
                                                  final dong = dongs[idx];
                                                  final key =
                                                      '$_selectedGu/$dong';
                                                  final selected = _fav
                                                      .contains(key);
                                                  return ListTile(
                                                    dense: true,
                                                    title: Text(dong),
                                                    trailing: IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 32,
                                                            minHeight: 32,
                                                          ),
                                                      iconSize: 25,
                                                      icon: Icon(
                                                        selected
                                                            ? Icons.favorite
                                                            : Icons
                                                                  .favorite_border,
                                                        size: 25,
                                                        color: selected
                                                            ? primary
                                                            : Colors
                                                                  .grey
                                                                  .shade500,
                                                      ),
                                                      onPressed: () =>
                                                          _toggleFav(
                                                            _selectedGu!,
                                                            dong,
                                                          ),
                                                      tooltip: selected
                                                          ? '찜 해제'
                                                          : '찜하기',
                                                    ),
                                                    onTap: () => _toggleFav(
                                                      _selectedGu!,
                                                      dong,
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 하단: 찜한 항목 + 다음 버튼 (기존 그대로)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.fromLTRB(
                      Sizes.size12,
                      Sizes.size12,
                      Sizes.size12,
                      Sizes.size16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_fav.isNotEmpty) ...[
                          const Text(
                            '찜한 동',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              itemCount: _fav.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final favList = _fav.toList()..sort();
                                final key = favList[index];
                                final parts = key.split('/');
                                final label = parts.length == 2
                                    ? '${parts[0]} · ${parts[1]}'
                                    : key;

                                return Chip(
                                  label: Text(label),
                                  avatar: Icon(
                                    Icons.favorite,
                                    color: primary,
                                    size: 18,
                                  ),
                                  onDeleted: () =>
                                      setState(() => _fav.remove(key)),
                                  deleteIconColor: Colors.grey.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        GestureDetector(
                          onTap: _isNextEnabled ? _onNextTap : null,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _isNextEnabled
                                  ? primary
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '다음',
                              style: TextStyle(
                                color: _isNextEnabled
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
