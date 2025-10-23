import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roommate/constants/gaps.dart';
import 'package:roommate/constants/responsive_sizes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  // ✅ 수정: 생성자에서 required 파라미터를 제거하여 범용 선택기로 사용
  const SearcherScreen({super.key});
  @override
  State<SearcherScreen> createState() => _SearcherScreenState();
}

class _SearcherScreenState extends State<SearcherScreen> {
  final String _apiKey = dotenv.env['JUSO_API_KEY']!;
  final Map<String, List<String>> _dongCache = {};
  bool _isLoadingDongs = false;
  String _errorMessage = '';

  final Set<String> _fav = {}; // "구/동" 형식으로 저장
  late final List<String> _guList = (kSeoulGu.toList()..sort());
  String? _selectedGu;

  bool get _isNextEnabled => _fav.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_guList.isNotEmpty) {
      _selectedGu = _guList.first;
      _fetchDongsForGu(_selectedGu!);
    }
  }

  Future<void> _fetchDongsForGu(String gu) async {
    if (_dongCache.containsKey(gu)) return;

    setState(() {
      _isLoadingDongs = true;
      _errorMessage = '';
    });

    try {
      const int maxPages = 5;
      const int countPerPage = 20;

      final Set<String> emdSet = {};
      for (int page = 1; page <= maxPages; page++) {
        final uri = Uri.https(
          'www.juso.go.kr',
          '/addrlink/addrLinkApi.do',
          {
            'confmKey': _apiKey,
            'currentPage': page.toString(),
            'countPerPage': countPerPage.toString(),
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
          final msg = common?['errorMessage'] ?? '알 수 없는 오류';
          throw Exception('API 오류: $msg');
        }

        final List<dynamic>? juso = results['juso'];
        if (juso == null || juso.isEmpty) break;

        for (final item in juso) {
          final si = item['siNm'] as String?;
          final sgg = item['sggNm'] as String?;
          final emd = item['emdNm'] as String?;

          if (si == '서울특별시' &&
              sgg == gu &&
              emd != null &&
              emd.trim().isNotEmpty) {
            emdSet.add(emd.trim());
          }
        }
        if (juso.length < countPerPage) break;
      }

      final list = emdSet.toList()..sort();
      setState(() => _dongCache[gu] = list);
    } catch (e) {
      setState(() => _errorMessage = '동 목록을 불러오지 못했습니다: $e');
    } finally {
      setState(() => _isLoadingDongs = false);
    }
  }

  void _toggleFav(String gu, String dong) {
    final key = '$gu $dong'; // "강남구 역삼동" 형식으로 저장
    setState(() {
      if (_fav.contains(key)) {
        _fav.remove(key);
      } else {
        if (_fav.length < 5) {
          // 최대 3개까지만 선택 가능
          _fav.add(key);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('희망 위치는 최대 5개까지 선택할 수 있습니다.')),
          );
        }
      }
    });
  }

  // ✅ _onNextTap 함수를 수정하여 선택된 지역 리스트를 반환합니다.
  void _onNextTap() {
    if (!_isNextEnabled) return;
    // 이전 화면으로 선택된 지역 리스트를 가지고 돌아갑니다.
    Navigator.of(context).pop(_fav.toList());
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final dongs = _selectedGu == null
        ? <String>[]
        : (_dongCache[_selectedGu!] ?? <String>[]);

    return Scaffold(
      appBar: AppBar(title: const Text('희망 위치 선택')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSizes.p(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '거주를 희망하는 자치구와 동을\n최대 5개까지 선택하세요.',
                style: TextStyle(
                  fontSize: ResponsiveSizes.f(context, 24),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gaps.v16(context),
              const Divider(height: 1, color: Colors.black12),
              Gaps.v16(context),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black38),
                          borderRadius: BorderRadius.circular(
                            ResponsiveSizes.p(context, 12),
                          ),
                        ),
                        child: ListView.separated(
                          itemCount: _guList.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Colors.black38),
                          itemBuilder: (context, index) {
                            final gu = _guList[index];
                            final selected = gu == _selectedGu;
                            return Material(
                              color: selected
                                  ? primary.withAlpha(50)
                                  : Colors.transparent,
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  gu,
                                  style: TextStyle(
                                    fontSize: ResponsiveSizes.f(context, 14),
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected ? primary : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                onTap: () {
                                  setState(() => _selectedGu = gu);
                                  _fetchDongsForGu(gu);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Gaps.h12(context),
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black38),
                          borderRadius: BorderRadius.circular(
                            ResponsiveSizes.p(context, 12),
                          ),
                        ),
                        child: _selectedGu == null
                            ? const Center(child: Text('좌측에서 자치구를 선택하세요'))
                            : Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveSizes.height(
                                        context,
                                        10 / 800,
                                      ),
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _selectedGu!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: ResponsiveSizes.f(
                                              context,
                                              16,
                                            ),
                                          ),
                                        ),
                                        Gaps.h8(context),
                                        if (_isLoadingDongs)
                                          const Text('(로딩 중...)')
                                        else
                                          Text('(${dongs.length}개 동)'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: _isLoadingDongs
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : _errorMessage.isNotEmpty
                                        ? Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                ResponsiveSizes.p(context, 16),
                                              ),
                                              child: Text(
                                                _errorMessage,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            padding: EdgeInsets.symmetric(
                                              vertical: ResponsiveSizes.height(
                                                context,
                                                4 / 800,
                                              ),
                                            ),
                                            itemCount: dongs.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(
                                                  height: 1,
                                                  color: Colors.black26,
                                                ),
                                            itemBuilder: (context, idx) {
                                              final dong = dongs[idx];
                                              final key = '$_selectedGu $dong';
                                              final selected = _fav.contains(
                                                key,
                                              );
                                              return ListTile(
                                                dense: true,
                                                title: Text(dong),
                                                trailing: Icon(
                                                  selected
                                                      ? Icons.check_circle
                                                      : Icons
                                                            .add_circle_outline,
                                                  color: selected
                                                      ? primary
                                                      : Colors.grey.shade500,
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
              Gaps.v16(context),
              if (_fav.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(ResponsiveSizes.p(context, 12)),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(
                      ResponsiveSizes.p(context, 12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '선택된 지역',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Gaps.v8(context),
                      Wrap(
                        spacing: ResponsiveSizes.p(context, 8),
                        runSpacing: ResponsiveSizes.p(context, 8),
                        children: _fav
                            .map(
                              (favItem) => Chip(
                                label: Text(favItem),
                                onDeleted: () =>
                                    setState(() => _fav.remove(favItem)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              Gaps.v16(context),
              GestureDetector(
                onTap: _isNextEnabled ? _onNextTap : null,
                child: Container(
                  height: ResponsiveSizes.height(context, 48 / 800),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isNextEnabled ? primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(
                      ResponsiveSizes.p(context, 8),
                    ),
                  ),
                  child: Text(
                    '선택 완료',
                    style: TextStyle(
                      color: _isNextEnabled ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
