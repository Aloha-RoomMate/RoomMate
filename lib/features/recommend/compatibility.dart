// lib/features/recommend/compatibility.dart
import 'dart:math';
import 'package:roommate/class/app_user.dart';

/// Hobbies 카테고리 (온보딩 UI와 동일)
const List<String> kFoods = [
  "피자",
  "치킨",
  "삼겹살",
  "라면",
  "불고기",
  "김치찌개",
  "된장찌개",
  "비빔밥",
  "칼국수",
  "떡볶이",
  "순대국",
  "갈비탕",
  "돈까스",
  "초밥",
  "회",
  "족발",
  "보쌈",
  "쌀국수",
  "버거",
  "파스타",
];
const List<String> kSports = [
  "농구",
  "러닝",
  "무술",
  "배드민턴",
  "사이클링",
  "산책",
  "클라이밍",
  "테니스",
  "필라테스",
  "스키",
  "스케이트",
  "테니스",
  "탁구",
  "당구",
  "헬스장",
  "해변 스포츠",
  "폴 댄스",
  "축구",
  "E-스포츠",
];
const List<String> kInterests = [
  "아이돌",
  "키링",
  "전시회",
  "애니메이션",
  "IT",
  "부동산",
  "주식",
  "독서",
  "영화감상",
  "음악듣기",
  "공연",
  "넷플릭스",
  "맛집",
  "기후변화",
  "방탈출",
  "클러빙",
  "다꾸",
];

const List<String> kDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

// 파일 상단 import/const 아래 아무 곳에 추가
enum MbtiCompat { none, red, yellow, green, blue }

const Map<MbtiCompat, double> _mbtiBoostByTier = {
  MbtiCompat.none: 0.00,
  MbtiCompat.red: 0.00, // 페널티는 주지 않음(요청 취지상 +보너스만)
  MbtiCompat.yellow: 0.01, // 살짝 보너스
  MbtiCompat.green: 0.03, // 좋은 관계
  MbtiCompat.blue: 0.06, // 천생연분
};

MbtiCompat _mbtiCompatTier(String? a, String? b) {
  if (a == null || b == null) return MbtiCompat.none;
  final A = a.toUpperCase();
  final B = b.toUpperCase();
  if (A.length != 4 || B.length != 4) return MbtiCompat.none;
  if (A == '모름' || B == '모름') return MbtiCompat.none;

  // 각 글자 일치 여부
  final sameE = A[0] == B[0];
  final sameN = A[1] == B[1];
  final sameT = A[2] == B[2];
  final sameJ = A[3] == B[3];
  final cnt = [sameE, sameN, sameT, sameJ].where((x) => x).length;

  // "천생연분" 휴리스틱:
  //  - 가운데 두 글자(N/S, T/F)는 같고
  //  - 바깥(E/I, J/P)은 서로 반대  → 예: INFJ ↔ ENFP, INTJ ↔ ENTP
  final middleSame = sameN && sameT;
  final outerOpp = !sameE && !sameJ;
  if (middleSame && outerOpp) return MbtiCompat.blue;

  // "좋은 관계" 휴리스틱:
  //  - 3글자 이상 동일(매우 유사)  또는
  //  - 가운데 두 글자는 같고 바깥 중 하나만 다름(준보완)
  if (cnt >= 3 || (middleSame && (sameE != sameJ))) {
    return MbtiCompat.green;
  }

  // "보통"
  if (cnt == 2) return MbtiCompat.yellow;

  // "다시 생각"
  return MbtiCompat.red;
}

List<double> buildStructVector(AppUser u) {
  final v = <double>[];

  // dailyRhythm
  final dr = u.dailyRhythm;
  final workDays = dr?.workDays ?? const <String>[];
  for (final d in kDays) {
    v.add(workDays.contains(d) ? 1.0 : 0.0);
  }
  v.add(dr?.isJobLess == true ? 1.0 : 0.0);

  // awake/sleep to sin/cos
  final awake = dr?.weekAwakeMins ?? 8 * 60;
  final sleep = dr?.weekSleepMins ?? 24 * 60;
  void pushSinCos(int mins) {
    final t = (mins / (24 * 60)) * 2 * pi;
    v.add(sin(t));
    v.add(cos(t));
  }

  pushSinCos(awake);
  pushSinCos(sleep);

  // coliving
  final cl = u.coliving;
  v.add(cl?.smoking == true ? 1.0 : 0.0);

  final mbti = (cl?.mbti ?? '').toUpperCase();
  v.add(mbti.startsWith('I') ? 1.0 : 0.0);
  v.add(mbti.contains('N') ? 1.0 : 0.0);
  v.add(mbti.contains('T') ? 1.0 : 0.0);
  v.add(mbti.endsWith('J') ? 1.0 : 0.0);

  final petList = cl?.pet ?? const <String>[];
  v.add(petList.isNotEmpty ? 1.0 : 0.0);

  // hobby (레거시 UserLike 호환)
  final hb = u.hobby;
  final food = (hb?.foodLike ?? const <dynamic>[]).cast<String>();
  final sport = (hb?.sportLike ?? const <dynamic>[]).cast<String>();
  final interest = (hb?.interestLike ?? const <dynamic>[]).cast<String>();

  for (final x in kFoods) v.add(food.contains(x) ? 1.0 : 0.0);
  for (final x in kSports) v.add(sport.contains(x) ? 1.0 : 0.0);
  for (final x in kInterests) v.add(interest.contains(x) ? 1.0 : 0.0);

  // L2 normalize
  final norm = sqrt(v.fold<double>(0, (s, x) => s + x * x));
  if (norm > 0) {
    for (var i = 0; i < v.length; i++) v[i] = v[i] / norm;
  }
  return v;
}

double cosineSim(List<double> a, List<double> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final n = min(a.length, b.length);
  double dot = 0, na = 0, nb = 0;
  for (var i = 0; i < n; i++) {
    final x = a[i], y = b[i];
    dot += x * y;
    na += x * x;
    nb += y * y;
  }
  final denom = sqrt(na) * sqrt(nb);
  return denom > 0 ? dot / denom : 0;
}

double jaccardSim(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 0;
  final inter = a.intersection(b).length;
  final uni = a.union(b).length;
  return uni == 0 ? 0 : inter / uni;
}

/// 간단 문자 2-gram 기반 텍스트 유사도(한국어/영어 모두 동작)
double charBigramCosine(String? s1, String? s2) {
  final a = _ngrams(s1 ?? '', 2);
  final b = _ngrams(s2 ?? '', 2);
  if (a.isEmpty || b.isEmpty) return 0;
  // 빈도 벡터 -> 코사인
  final all = <String>{...a.keys, ...b.keys}.toList();
  final va = all.map((k) => (a[k] ?? 0).toDouble()).toList();
  final vb = all.map((k) => (b[k] ?? 0).toDouble()).toList();
  return cosineSim(va, vb);
}

Map<String, int> _ngrams(String s, int n) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  final m = <String, int>{};
  for (var i = 0; i <= t.length - n; i++) {
    final g = t.substring(i, i + n);
    m[g] = (m[g] ?? 0) + 1;
  }
  return m;
}

/// ─────────────────────────────────────────
/// 연령대(10년 단위) 버킷 & 보너스
/// ─────────────────────────────────────────
int? _ageDecadeFromBirthYear(int? birthYear, {DateTime? now}) {
  if (birthYear == null || birthYear <= 0) return null;
  final y = (now ?? DateTime.now()).year;
  final age = y - birthYear; // 국제식 나이
  if (age < 0 || age > 120) return null;
  return (age ~/ 10) * 10; // 23 -> 20, 31 -> 30
}

bool _isSameAgeDecade(int? by1, int? by2) {
  final d1 = _ageDecadeFromBirthYear(by1);
  final d2 = _ageDecadeFromBirthYear(by2);
  if (d1 == null || d2 == null) return false;
  return d1 == d2;
}

class Compatibility {
  final double structSim;
  final double hobbySim;
  final double textSim;
  final double score;
  final List<String> reasons;
  const Compatibility(
    this.structSim,
    this.hobbySim,
    this.textSim,
    this.score,
    this.reasons,
  );
}

Compatibility scoreUsers(AppUser me, AppUser other) {
  const wStruct = 0.70, wHobby = 0.25, wText = 0.05;

  final vMe = buildStructVector(me);
  final vOt = buildStructVector(other);

  final struct = cosineSim(vMe, vOt);

  final myH = <String>{
    ...((me.hobby?.foodLike ?? const <dynamic>[])).cast<String>(),
    ...((me.hobby?.sportLike ?? const <dynamic>[])).cast<String>(),
    ...((me.hobby?.interestLike ?? const <dynamic>[])).cast<String>(),
  };
  final otH = <String>{
    ...((other.hobby?.foodLike ?? const <dynamic>[])).cast<String>(),
    ...((other.hobby?.sportLike ?? const <dynamic>[])).cast<String>(),
    ...((other.hobby?.interestLike ?? const <dynamic>[])).cast<String>(),
  };
  final hobby = jaccardSim(myH, otH);

  final introMe = me.introduction is String
      ? me.introduction as String
      : (me.introduction ?? '');
  final introOt = other.introduction is String
      ? other.introduction as String
      : (other.introduction ?? '');
  final text = charBigramCosine(introMe, introOt);

  // 기본 점수
  double score = wStruct * struct + wHobby * hobby + wText * text;

  // ===== MBTI 보너스 추가 =====
  final mbtiA = me.coliving?.mbti;
  final mbtiB = other.coliving?.mbti;
  final tier = _mbtiCompatTier(mbtiA, mbtiB);
  final mbtiBonus = _mbtiBoostByTier[tier]!;
  score = (score + mbtiBonus).clamp(0.0, 1.0);

  final reasons = <String>[];
  if (_isSameAgeDecade(me.birthYear, other.birthYear)) {
    score = (score + 0.05).clamp(0.0, 1.0); // 동연령대 보너스(기존)
    reasons.add("동연령대");
  }

  // 기존 사유
  if (other.coliving?.smoking == false && me.coliving?.smoking == false) {
    reasons.add("비흡연 선호 일치");
  }
  if (hobby >= 0.2) reasons.add("취미 겹침");
  if (struct >= 0.75) reasons.add("생활 패턴 유사");
  if (text >= 0.5) reasons.add("자기소개 톤 유사");

  // MBTI 사유(좋음 이상일 때 노출)
  switch (tier) {
    case MbtiCompat.blue:
      reasons.add("MBTI 천생연분");
      break;
    case MbtiCompat.green:
      reasons.add("MBTI 궁합 좋음");
      break;
    default:
      break;
  }

  return Compatibility(struct, hobby, text, score, reasons.take(3).toList());
}

String explainCompatibility(Compatibility c) {
  // 가중치와 부분 점수를 보기 좋게 표시
  final s = (c.structSim * 100).toStringAsFixed(1);
  final h = (c.hobbySim * 100).toStringAsFixed(1);
  final t = (c.textSim * 100).toStringAsFixed(1);
  final total = (c.score * 100).toStringAsFixed(0);

  // NOTE: 동연령대 보너스(+5%)는 총점에만 반영됩니다.
  return [
    '총점: $total%',
    '· 생활 패턴(70%): $s%',
    '· 취미 겹침(25%): $h%',
    '· 소개글 톤(5%): $t%',
  ].join('\n');
}
