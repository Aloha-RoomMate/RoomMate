import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class AppUser {
  final String uid;
  final String? email;
  final String displayName;
  final String? photoURL;
  final String? gender;
  final int? birthYear;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DailyRhythm? dailyRhythm;
  final Coliving? coliving;
  final DiseaseInfo? disease;
  final String? introduction;
  final UserType? userType;
  final Hobby? hobby; // ← 읽을 때 UserLike도 폴백
  final UserPass? userPass; // ← pass: bool 만

  const AppUser({
    required this.uid,
    this.email,
    required this.displayName,
    this.photoURL,
    this.createdAt,
    this.updatedAt,
    this.dailyRhythm,
    this.coliving,
    this.disease,
    this.introduction,
    this.gender,
    this.birthYear,
    this.userType,
    this.hobby,
    this.userPass,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? gender,
    int? birthYear,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserType? userType, // ✅ 타입 수정
    DailyRhythm? dailyRhythm,
    Coliving? coliving,
    DiseaseInfo? disease,
    String? introduction,
    UserPass? userPass,
    Hobby? hobby,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dailyRhythm: dailyRhythm ?? this.dailyRhythm,
      coliving: coliving ?? this.coliving,
      disease: disease ?? this.disease,
      introduction: introduction ?? this.introduction,
      hobby: hobby ?? this.hobby,
      userType: userType ?? this.userType,
      userPass: userPass ?? this.userPass,
    );
  }

  factory AppUser.fromAuth(auth.User u) {
    final dn = (u.displayName ?? '').trim();
    final name = dn.isNotEmpty ? dn : (u.email?.split('@').first ?? '룸메이트');
    return AppUser(
      uid: u.uid,
      email: u.email,
      displayName: name,
      photoURL: u.photoURL,
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String?,
      displayName: (map['displayName'] as String? ?? '룸메이트'),
      photoURL: map['photoURL'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      birthYear: map['birthYear'] as int?,

      dailyRhythm: DailyRhythm.fromMap(
        map['dailyRhythm'] as Map<String, dynamic>?,
      ),
      userType: UserType.fromMap(map['userType'] as Map<String, dynamic>?),
      coliving: Coliving.fromMap(map['coliving'] as Map<String, dynamic>?),
      disease: DiseaseInfo.fromMap(map['disease'] as Map<String, dynamic>?),
      gender: map['gender'] as String?,
      introduction: (map['introduction'] is String)
          ? map['introduction'] as String
          : ((map['introduction'] is Map<String, dynamic>)
                ? (map['introduction'] as Map<String, dynamic>)['introduction']
                      as String?
                : null),

      // ✅ 저장은 UserLike 로만 하지만, 읽기 시 hobby 또는 UserLike 모두 허용
      hobby: Hobby.fromMap(
        (map['hobby'] as Map<String, dynamic>?) ??
            (map['UserLike'] as Map<String, dynamic>?),
      ),

      userPass: UserPass.fromMap(map['userPass'] as Map<String, dynamic>?),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Map<String, dynamic> toMap({bool skipNulls = true}) {
    final map = <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'gender': gender,
      'birthYear': birthYear,
      if (dailyRhythm != null) 'dailyRhythm': dailyRhythm!.toMap(),
      if (userType != null) 'userType': userType!.toMap(),
      if (coliving != null) 'coliving': coliving!.toMap(),
      if (disease != null) 'disease': disease!.toMap(),
      if (introduction != null) 'introduction': introduction,
      if (userPass != null) 'userPass': userPass!.toMap(), // pass만 직렬화
      // 취미는 upsertFromAuth에서는 보통 null이라 생략됨. 실제 저장은 setHobby 사용.
    };
    if (skipNulls) map.removeWhere((_, v) => v == null);
    return map;
  }
}

class UserPass {
  final bool pass;
  const UserPass({required this.pass});

  factory UserPass.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPass(pass: false);
    return UserPass(pass: map['pass'] == true);
  }

  Map<String, dynamic> toMap() => {'pass': pass};
}

/// 하루 리듬(온보딩)
class DailyRhythm {
  final List<String> workDays;
  final bool isJobLess;
  final int? weekAwakeMins;
  final int? weekSleepMins;

  const DailyRhythm({
    required this.workDays,
    required this.isJobLess,
    this.weekAwakeMins,
    this.weekSleepMins,
  });

  Map<String, dynamic> toMap() => {
    'workDays': workDays,
    'isJobLess': isJobLess,
    'week': {
      'awakeMins': weekAwakeMins,
      'sleepMins': weekSleepMins,
    },
  };

  static DailyRhythm? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final week = (map['week'] as Map<String, dynamic>?) ?? const {};
    return DailyRhythm(
      workDays: List<String>.from(map['workDays'] ?? const []),
      isJobLess: map['isJobLess'] == true,
      weekAwakeMins: week['awakeMins'] as int?,
      weekSleepMins: week['sleepMins'] as int?,
    );
  }
}

class UserType {
  final String type; // 'roomOwner' or 'searcher'
  final String jobKinds; // 문자열 고정
  final String? address;
  final List<String>? searchAreas;
  const UserType({
    required this.type,
    required this.jobKinds,
    this.address,
    this.searchAreas,
  });

  factory UserType.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserType(type: 'searcher', jobKinds: "");
    final raw = map['jobKinds'];
    final jobKinds = (raw is List)
        ? raw.whereType<String>().join(', ')
        : (raw as String? ?? "");
    return UserType(
      type: (map['type'] as String?) ?? 'searcher',
      jobKinds: jobKinds,
      address: map['address'] as String?,
      searchAreas: (map['searchAreas'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'jobKinds': jobKinds,
    'address': address,
    'searchAreas': searchAreas,
  };
}

class Coliving {
  final String coSpace;
  final String interaction;
  final String bathroom;
  final String cleanOption;
  final bool smoking;
  final List<String> pet;
  final String mbti;

  const Coliving({
    required this.coSpace,
    required this.interaction,
    required this.bathroom,
    required this.cleanOption,
    required this.smoking,
    required this.pet,
    required this.mbti,
  });

  Map<String, dynamic> toMap() => {
    'coSpace': coSpace,
    'interaction': interaction,
    'bathroom': bathroom,

    'cleanOption': cleanOption,
    'smoking': smoking,
    'pet': pet,
    'mbti': mbti,
  };

  static Coliving? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return Coliving(
      coSpace: map['coSpace'] as String? ?? "",
      interaction: map['interaction'] as String? ?? "",
      bathroom: map['bathroom'] as String? ?? "",
      cleanOption: map['cleanOption'] as String? ?? "",
      smoking: map['smoking'] == true,
      pet: List<String>.from(map['pet'] ?? const []),
      mbti: map['mbti'] as String? ?? "",
    );
  }
}

class DiseaseInfo {
  final bool? isHealthy; // true면 diseases는 무시
  final String? diseases; // free-text
  const DiseaseInfo({this.isHealthy, this.diseases});

  Map<String, dynamic> toMap() => {
    if (isHealthy != null) 'isHealthy': isHealthy,
    if (diseases != null) 'diseases': diseases,
  };

  static DiseaseInfo? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return DiseaseInfo(
      isHealthy: m['isHealthy'] as bool?,
      diseases: m['diseases'] as String?,
    );
  }
}

class Introduction {
  final String? introduction;
  const Introduction({this.introduction});
  Map<String, dynamic> toMap() => {
    if (introduction != null) 'introduction': introduction,
  };
  static Introduction? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return Introduction(
      introduction: m['introduction'] as String?,
    );
  }
}

class Hobby {
  final List<String> foodLike;
  final List<String> interestLike; // 오타(interstLike)도 읽기 허용
  final List<String> sportLike;

  const Hobby({
    required this.foodLike,
    required this.interestLike,
    required this.sportLike,
  });

  Map<String, dynamic> toMap() => {
    'foodLike': foodLike,
    'interstLike': interestLike, // ← 저장은 레거시 키 그대로(UserLike에서 사용)
    'sportLike': sportLike,
  };

  static Hobby? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final interest = map.containsKey('interestLike')
        ? map['interestLike']
        : map['interstLike'];
    return Hobby(
      foodLike: List<String>.from(map['foodLike'] ?? const []),
      interestLike: List<String>.from(interest ?? const []),
      sportLike: List<String>.from(map['sportLike'] ?? const []),
    );
  }
}
