// lib/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class AppUser {
  final String uid;
  final String? email;
  final String displayName;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DailyRhythm? dailyRhythm;
  final Coliving? coliving;
  final DiseaseInfo? disease;
  final String? introduction;
  final UserType? userType;
  final Hobby? hobby;

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
    this.userType,
    this.hobby,
  });

  // named와 null 허용 "두 기능 모두"가 있기 때문에
  // 외부에서 하나의 매개변수만 넘겨줘도 문제가 안 생김.
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userType,
    DailyRhythm? dailyRhythm,
    Coliving? coliving,
    DiseaseInfo? disease,
    String? introduction,
  }) {
    return AppUser(
      // 새로운 값이 오면 그걸로 교체, 아니면 기존의 값.
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dailyRhythm: dailyRhythm ?? this.dailyRhythm,
      coliving: coliving ?? this.coliving,
      disease: disease ?? this.disease,
      introduction: introduction ?? this.introduction,
      hobby: hobby ?? this.hobby,
    );
  }

  factory AppUser.fromAuth(auth.User u) {
    // Auth 성공 시 User 객체 받음.
    final dn = (u.displayName ?? '').trim(); // null -> ''로

    final name = dn.isNotEmpty ? dn : (u.email?.split('@').first ?? '룸메이트');
    return AppUser(
      // 최초의 AppUser 객체 생성
      uid: u.uid,
      email: u.email,
      displayName: name,
      photoURL: u.photoURL,
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    // Map from Firestore
    return AppUser(
      uid: uid,
      // as ~? 로 지정해주는 이유: map 의 value (key:value) 가 dynamic 이므로.
      email: map['email'] as String?,
      displayName: (map['displayName'] as String? ?? '룸메이트'),
      photoURL: map['photoURL'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)
          ?.toDate(), // 메소드 앞에 ? : null이면 null 반환.
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      dailyRhythm: DailyRhythm.fromMap(
        map['dailyRhythm'] as Map<String, dynamic>?, // null safety
      ),
      userType: UserType.fromMap(
        map['userType'] as Map<String, dynamic>?,
      ),
      coliving: Coliving.fromMap(
        map['coliving'] as Map<String, dynamic>?,
      ),
      disease: DiseaseInfo.fromMap(map['disease'] as Map<String, dynamic>?),
      introduction: map['introduction'] as String?,
      hobby: Hobby.fromMap(
        map['hobby'] as Map<String, dynamic>?,
      ),
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
      if (dailyRhythm != null) 'dailyRhythm': dailyRhythm!.toMap(),
      if (userType != null) 'userType': userType!.toMap(),
      if (coliving != null) 'coliving': coliving!.toMap(),
      if (disease != null) 'disease': disease!.toMap(),
      if (introduction != null) 'introduction': introduction,
    };
    if (skipNulls) map.removeWhere((_, v) => v == null);
    // key와 관계 없이 value가 null이면 제거한다.
    return map;
  }
}

/// 하루 리듬(온보딩) 서브모델
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
      // <String>으로 하면 dynamic인 map value들로부터 보호 가능
      workDays: List<String>.from(map['workDays'] ?? const []),
      isJobLess: map['isJobLess'] == true,
      weekAwakeMins: week['awakeMins'] as int?,
      weekSleepMins: week['sleepMins'] as int?,
    );
  }
}

class UserType {
  final String type; // 'roomOwner' or 'searcher'
  final String jobKinds;
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
    return UserType(
      type: map['type'] ?? 'searcher',
      jobKinds: map['jobKinds'] ?? [],
      address: map['address'],
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
  final bool smoking;
  final List<String> pet;
  final String mbti;

  const Coliving({
    required this.coSpace,
    required this.interaction,
    required this.bathroom,
    required this.smoking,
    required this.pet,
    required this.mbti,
  });

  Map<String, dynamic> toMap() => {
    'coSpace': coSpace,
    'interaction': interaction,
    'bathroom': bathroom,
    'smoking': smoking,
    "pet": pet,
    'mbti': mbti,
  };

  static Coliving? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null; // 없으면
    return Coliving(
      coSpace: map['coSpace'],
      interaction: map['interaction'],
      bathroom: map['bathroom'],
      smoking: map['smoking'],
      pet: List<String>.from(map['pet'] ?? const []),
      mbti: map['mbti'],
    );
  }
}

class DiseaseInfo {
  final bool? isHealthy; // true면 diseases는 무시
  final String? diseases; // 콤마 없는 free-text
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
  final List foodLike;
  final List interestLike;
  final List sportLike;

  const Hobby({
    required this.foodLike,
    required this.interestLike,
    required this.sportLike,
  });

  Map<String, dynamic> toMap() => {
    'foodLike': foodLike,
    'interstLike': interestLike,
    'sportLike': sportLike,
  };
  static Hobby? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null; // 없으면
    return Hobby(
      foodLike: List<String>.from(map['foodLike'] ?? const []),
      interestLike: List<String>.from(map['interstLike'] ?? const []),
      sportLike: List<String>.from(map['sportLike'] ?? const []),
    );
  }
}

/// 이구조임당
// users (컬렉션)
//   └─ {uid} (문서)
//        ├─ email: string
//        ├─ displayName: string
//        ├─ photoURL: string
//        ├─ createdAt: Timestamp
//        ├─ updatedAt: Timestamp
//        └─ dailyRhythm: {               ← 서브컬렉션이 아니고 문서안의 필드
//             workDays: [ ... ],
//             alarms: [ ... ],
//             isJobLess: bool,
//             week: {
//               awakeMins: int?,
//               goWorkMins: int?,
//               backHomeMins: int?,
//               sleepMins: int?
//             },
//             weekend: {
//               awakeMins: int?,
//               sleepMins: int?
//             }
//           }
