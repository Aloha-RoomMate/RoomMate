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
  final WorkPattern? workPattern;
  final DiningHabit? diningHabit;
  final SoundScreen? soundScreen;
  final CleaningHabit? cleaningHabit;
  final EtcLife? etcLife;
  final DiseaseInfo? disease;
  final String? introduction;
  final UserType? userType;

  const AppUser({
    required this.uid,
    this.email,
    required this.displayName,
    this.photoURL,
    this.createdAt,
    this.updatedAt,
    this.dailyRhythm,
    this.workPattern,
    this.diningHabit,
    this.soundScreen,
    this.cleaningHabit,
    this.etcLife,
    this.disease,
    this.introduction,
    this.userType,
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
    WorkPattern? workPattern,
    DiningHabit? diningHabit,
    SoundScreen? soundScreen,
    CleaningHabit? cleaningHabit,
    EtcLife? etcLife,
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
      workPattern: workPattern ?? this.workPattern,
      diningHabit: diningHabit ?? this.diningHabit,
      soundScreen: soundScreen ?? this.soundScreen,
      cleaningHabit: cleaningHabit ?? this.cleaningHabit,
      etcLife: etcLife ?? this.etcLife,
      disease: disease ?? this.disease,
      introduction: introduction ?? this.introduction,
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
      workPattern: WorkPattern.fromMap(
        map['workPattern'] as Map<String, dynamic>?,
      ),
      diningHabit: DiningHabit.fromMap(
        map['diningHabit'] as Map<String, dynamic>?,
      ),
      soundScreen: SoundScreen.fromMap(
        map['soundScreen'] as Map<String, dynamic>?,
      ),
      cleaningHabit: CleaningHabit.fromMap(
        map['cleaningHabit'] as Map<String, dynamic>?,
      ),
      etcLife: EtcLife.fromMap(map['etcLife'] as Map<String, dynamic>?),
      disease: DiseaseInfo.fromMap(map['disease'] as Map<String, dynamic>?),
      introduction: map['introduction'] as String?,
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
      if (workPattern != null) 'workPattern': workPattern!.toMap(),
      if (diningHabit != null) 'diningHabit': diningHabit!.toMap(),
      if (soundScreen != null) 'soundScreen': soundScreen!.toMap(),
      if (cleaningHabit != null) 'cleaningHabit': cleaningHabit!.toMap(),
      if (etcLife != null) 'etcLife': etcLife!.toMap(),
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
    final weekend = (map['weekend'] as Map<String, dynamic>?) ?? const {};
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

class WorkPattern {
  final List<String> lates; // 늦은 귀가 빈도
  final List<String> drinks; // 주 음주 횟수
  const WorkPattern({required this.lates, required this.drinks});
  Map<String, dynamic> toMap() => {'lates': lates, 'drinks': drinks};
  static WorkPattern? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return WorkPattern(
      lates: List<String>.from(m['lates'] ?? const []),
      drinks: List<String>.from(m['drinks'] ?? const []),
    );
  }
}

class DiningHabit {
  final List<String> weeklyCooking;
  final List<String> smellSense;
  final List<String> dishShare;
  const DiningHabit({
    required this.weeklyCooking,
    required this.smellSense,
    required this.dishShare,
  });
  Map<String, dynamic> toMap() => {
    'weeklyCooking': weeklyCooking,
    'smellSense': smellSense,
    'dishShare': dishShare,
  };
  static DiningHabit? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return DiningHabit(
      weeklyCooking: List<String>.from(m['weeklyCooking'] ?? const []),
      smellSense: List<String>.from(m['smellSense'] ?? const []),
      dishShare: List<String>.from(m['dishShare'] ?? const []),
    );
  }
}

class SoundScreen {
  final List<String> sleepSound;
  final List<String> sleepHabit;
  final List<String> soundMode;
  final List<String> earPhone;
  const SoundScreen({
    required this.sleepSound,
    required this.sleepHabit,
    required this.soundMode,
    required this.earPhone,
  });
  Map<String, dynamic> toMap() => {
    'sleepSound': sleepSound,
    'sleepHabit': sleepHabit,
    'soundMode': soundMode,
    'earPhone': earPhone,
  };
  static SoundScreen? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return SoundScreen(
      sleepSound: List<String>.from(m['sleepSound'] ?? const []),
      sleepHabit: List<String>.from(m['sleepHabit'] ?? const []),
      soundMode: List<String>.from(m['soundMode'] ?? const []),
      earPhone: List<String>.from(m['earPhone'] ?? const []),
    );
  }
}

class CleaningHabit {
  final List<String> roomClean;
  final List<String> bathroomClean;
  final List<String> cleaningLevel;
  const CleaningHabit({
    required this.roomClean,
    required this.bathroomClean,
    required this.cleaningLevel,
  });
  Map<String, dynamic> toMap() => {
    'roomClean': roomClean,
    'bathroomClean': bathroomClean,
    'cleaningLevel': cleaningLevel,
  };
  static CleaningHabit? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return CleaningHabit(
      roomClean: List<String>.from(m['roomClean'] ?? const []),
      bathroomClean: List<String>.from(m['bathroomClean'] ?? const []),
      cleaningLevel: List<String>.from(m['cleaningLevel'] ?? const []),
    );
  }
}

class EtcLife {
  final List<String> smoking;
  final List<String> insideSmoking;
  final List<String> pet;
  const EtcLife({
    required this.smoking,
    required this.insideSmoking,
    required this.pet,
  });
  Map<String, dynamic> toMap() => {
    'smoking': smoking,
    'insideSmoking': insideSmoking,
    'pet': pet,
  };
  static EtcLife? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return EtcLife(
      smoking: List<String>.from(m['smoking'] ?? const []),
      insideSmoking: List<String>.from(m['insideSmoking'] ?? const []),
      pet: List<String>.from(m['pet'] ?? const []),
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
