import 'package:flutter/material.dart';
// 프로젝트에 맞게 경로 조정
import 'package:roommate/constants/sizes.dart';
import 'package:roommate/features/authentication/signup/welcome_screen.dart';
import 'package:roommate/features/authentication/widgets/form_button.dart';
import 'package:roommate/features/category/daily_rythm_screen.dart';

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
  // … 나머지 25개 자치구를 같은 방식으로 추가 …
};

class RoomownerScreen extends StatefulWidget {
  const RoomownerScreen({super.key});

  @override
  State<RoomownerScreen> createState() => _RoomownerScreenState();
}

class _RoomownerScreenState extends State<RoomownerScreen> {
  String? _selectedGu;
  String? _selectedDong;

  List<String> get _guList => kSeoulGuDong.keys.toList()..sort();
  List<String> get _dongList =>
      _selectedGu == null ? [] : (kSeoulGuDong[_selectedGu!] ?? []);

  bool get _isNextEnabled => _selectedGu != null && _selectedDong != null;

  void _onGuChanged(String? gu) {
    setState(() {
      _selectedGu = gu;
      _selectedDong = null; // 구 변경 시 동 초기화
    });
  }

  void _onDongChanged(String? dong) {
    setState(() => _selectedDong = dong);
  }

  void _onNextTap() {
    if (!_isNextEnabled) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DailyRythmScreen(),
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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

                  // 자치구 드롭다운
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGu,
                    decoration: const InputDecoration(
                      labelText: '자치구',
                      border: OutlineInputBorder(),
                    ),
                    items: _guList
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: _onGuChanged,
                    validator: (v) => v == null ? '자치구를 선택하세요' : null,
                  ),

                  const SizedBox(height: 12),

                  // 동 드롭다운
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDong,
                    decoration: const InputDecoration(
                      labelText: '동',
                      border: OutlineInputBorder(),
                    ),
                    items: _dongList
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: _dongList.isEmpty ? null : _onDongChanged,
                    validator: (v) => v == null ? '동을 선택하세요' : null,
                  ),

                  const Spacer(),

                  // 다음 버튼 (FormButton 버전에 맞춰 enabled/disabled 선택)
                  GestureDetector(
                    onTap: _isNextEnabled ? _onNextTap : null,
                    child: FormButton(
                      disabled: !_isNextEnabled, // disabled 프로퍼티면 반대로 바꾸세요
                      text: "다음",
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
