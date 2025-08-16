import 'package:flutter/material.dart';
// 프로젝트에 맞게 경로 조정
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/signup/welcome_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';

const Map<String, List<String>> kSeoulGuDong = {
  '종로구': [
    '청운동',
    '신교동',
    '궁정동',
    '효자동',
    '통의동',
    '적선동',
    '통인동',
    '누상동',
    '누하동',
    '옥인동',
    '체부동',
    '필운동',
    '내자동',
    '사직동',
    '도렴동',
    '당주동',
    '내수동',
    '세종로',
    '신문로1가',
    '신문로2가',
    '청진동',
    '서린동',
    '수송동',
    '중학동',
    '종로1가',
    '공평동',
    '관훈동',
    '견지동',
    '와룡동',
    '권농동',
    '운니동',
    '익선동',
    '경운동',
    '관철동',
    '인사동',
    '종로2가',
    '팔판동',
    '삼청동',
    '안국동',
    '소격동',
    '화동',
    '사간동',
    '송현동',
    '익정동',
    '계동',
    '운현동',
    '윤보선길 일대',
    '가회동',
    '재동',
    '종로3가',
    '인의동',
    '예지동',
    '원남동',
    '훈정동',
    '묘동',
    '봉익동',
    '돈의동',
    '종로4가',
    '효제동',
    '종로5가',
    '연지동',
    '종로6가',
    '이화동',
    '연건동',
    '충신동',
    '동숭동',
    '혜화동',
    '명륜1가',
    '명륜2가',
    '명륜4가',
    '창신1동',
    '창신2동',
    '창신3동',
    '숭인1동',
    '숭인2동',
  ],
  '중구': [
    '소공동',
    '회현동',
    '명동',
    '충무로1가',
    '충무로2가',
    '저동2가',
    '남대문로1가',
    '남대문로2가',
    '남대문로3가',
    '남대문로4가',
    '남대문로5가',
    '삼각동',
    '수하동',
    '장교동',
    '관수동',
    '을지로1가',
    '을지로2가',
    '을지로3가',
    '을지로4가',
    '을지로5가',
    '을지로6가',
    '필동1가',
    '필동2가',
    '필동3가',
    '남학동',
    '주자동',
    '예장동',
    '장충동1가',
    '장충동2가',
    '광희동1가',
    '광희동2가',
    '쌍림동',
    '신당동',
    '흥인동',
    '무학동',
    '황학동',
    '중림동',
  ],
  '용산구': [
    '후암동',
    '용산동2가',
    '용산동5가',
    '갈월동',
    '남영동',
    '청파동1가',
    '청파동2가',
    '청파동3가',
    '원효로1가',
    '원효로2가',
    '신계동',
    '산천동',
    '청암동',
    '원효로3가',
    '원효로4가',
    '효창동',
    '도원동',
    '용문동',
    '문배동',
    '신창동',
    '한강로1가',
    '한강로2가',
    '한강로3가',
    '이촌동',
    '이태원동',
    '한남동',
    '서빙고동',
    '보광동',
    '동빙고동',
    '주성동',
  ],
  '성동구': [
    '왕십리도선동',
    '왕십리제2동',
    '마장동',
    '사근동',
    '행당1동',
    '행당2동',
    '응봉동',
    '금호1가동',
    '금호2·3가동',
    '금호4가동',
    '옥수동',
    '성수1가1동',
    '성수1가2동',
    '성수2가1동',
    '성수2가3동',
    '송정동',
    '용답동',
  ],
  '광진구': [
    '중곡1동',
    '중곡2동',
    '중곡3동',
    '중곡4동',
    '능동',
    '구의1동',
    '구의2동',
    '구의3동',
    '광장동',
    '자양1동',
    '자양2동',
    '자양3동',
    '자양4동',
    '화양동',
    '군자동',
  ],
  '동대문구': [
    '용신동',
    '제기동',
    '전농1동',
    '전농2동',
    '답십리1동',
    '답십리2동',
    '장안1동',
    '장안2동',
    '청량리동',
    '회기동',
    '휘경1동',
    '휘경2동',
    '이문1동',
    '이문2동',
  ],
  '중랑구': [
    '면목본동',
    '면목2동',
    '면목3·8동',
    '면목4동',
    '면목5동',
    '면목7동',
    '상봉1동',
    '상봉2동',
    '중화1동',
    '중화2동',
    '묵1동',
    '묵2동',
    '망우본동',
    '망우3동',
    '신내1동',
    '신내2동',
  ],
  '성북구': [
    '성북동',
    '삼선동',
    '동선동',
    '돈암1동',
    '돈암2동',
    '안암동',
    '보문동',
    '정릉1동',
    '정릉2동',
    '정릉3동',
    '정릉4동',
    '길음1동',
    '길음2동',
    '종암동',
    '월곡1동',
    '월곡2동',
    '장위1동',
    '장위2동',
    '장위3동',
    '석관동',
  ],
  '강남구': [
    '신사동',
    '논현1동',
    '논현2동',
    '압구정동',
    '청담동',
    '삼성1동',
    '삼성2동',
    '대치1동',
    '대치2동',
    '대치4동',
    '역삼1동',
    '역삼2동',
    '도곡1동',
    '도곡2동',
    '개포1동',
    '개포2동',
    '개포4동',
    '세곡동',
    '일원본동',
    '일원1동',
    '일원2동',
    '수서동',
  ],
  // … 나머지 자치구 추가 …
};

class SearcherScreen extends StatefulWidget {
  const SearcherScreen({super.key});
  @override
  State<SearcherScreen> createState() => _SearcherScreenState();
}

class _SearcherScreenState extends State<SearcherScreen> {
  final Set<String> _fav = {}; // "구/동" 저장
  late final List<String> _guList = (kSeoulGuDong.keys.toList()..sort());
  String? _selectedGu;

  bool get _isNextEnabled => _fav.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // 최초 선택값(없으면 null 유지)
    if (_guList.isNotEmpty) _selectedGu = _guList.first;
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
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
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
        : (kSeoulGuDong[_selectedGu!] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text('희망 거주지역 선택')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900), // 넓은 화면에서도 정돈
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

                  // 상단 컨텐트: 좌(구) 1 : 우(동) 3
                  Expanded(
                    child: Row(
                      children: [
                        // 좌측: 자치구 목록 (1)
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
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  0,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,

                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                ),
                                                child: Text(
                                                  '$favCount',
                                                  style: TextStyle(
                                                    color: primary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                    onTap: () =>
                                        setState(() => _selectedGu = gu),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 우측: 선택한 자치구의 동 목록 (3)
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
                                            Text('(${dongs.length}개 동)'),
                                          ],
                                        ),
                                      ),

                                      // 동 리스트
                                      Expanded(
                                        child: ListView.separated(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          itemCount: dongs.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: Colors.grey.shade200,
                                          ),
                                          itemBuilder: (context, idx) {
                                            final dong = dongs[idx];
                                            final key = '$_selectedGu/$dong';
                                            final selected = _fav.contains(key);
                                            return ListTile(
                                              dense: true,
                                              title: Text(dong),
                                              trailing: IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ), // 터치 영역 확보
                                                iconSize: 25,
                                                icon: Icon(
                                                  selected
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 25,
                                                  color: selected
                                                      ? primary
                                                      : Colors.grey.shade500,
                                                ),
                                                onPressed: () => _toggleFav(
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

                  // 하단: 찜한 항목 Chips + 다음 버튼
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
                            height: 40, // 칩 높이에 맞게 조정
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
                          child: FormButton(
                            disabled: !_isNextEnabled,
                            text: "다음",
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
