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
  final DailyRhythm? dailyRhythm; // 이후 온보딩에서 채워짐
  final String? userType; // "roomOwner" | "searcher"
  final List<String>? jobKinds; // ['회사/학교','재택',...]
  final WorkPattern? workPattern;
  final DiningHabit? diningHabit;
  final SoundProfile? soundProfile;
  final CleaningHabit? cleaningHabit;
  final EtcLife? etcLife;
  final DiseaseInfo? disease;
  final String? introduction;

  const AppUser({
    required this.uid,
    this.email,
    required this.displayName,
    this.photoURL,
    this.createdAt,
    this.updatedAt,
    this.userType,
    this.jobKinds,
    this.dailyRhythm,
    this.workPattern,
    this.diningHabit,
    this.soundProfile,
    this.cleaningHabit,
    this.etcLife,
    this.disease,
    this.introduction,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userType,
    List<String>? jobKinds,
    DailyRhythm? dailyRhythm,
    WorkPattern? workPattern,
    DiningHabit? diningHabit,
    SoundProfile? soundProfile,
    CleaningHabit? cleaningHabit,
    EtcLife? etcLife,
    DiseaseInfo? disease,
    String? introduction,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userType: userType ?? this.userType,
      jobKinds: jobKinds ?? this.jobKinds,
      dailyRhythm: dailyRhythm ?? this.dailyRhythm,
      workPattern: workPattern ?? this.workPattern,
      diningHabit: diningHabit ?? this.diningHabit,
      soundProfile: soundProfile ?? this.soundProfile,
      cleaningHabit: cleaningHabit ?? this.cleaningHabit,
      etcLife: etcLife ?? this.etcLife,
      disease: disease ?? this.disease,
      introduction: introduction ?? this.introduction,
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
      userType: map['userType'] as String?,
      jobKinds: (map['jobKinds'] as List?)?.cast<String>(),
      dailyRhythm: DailyRhythm.fromMap(
        map['dailyRhythm'] as Map<String, dynamic>?,
      ),
      workPattern: WorkPattern.fromMap(
        map['workPattern'] as Map<String, dynamic>?,
      ),
      diningHabit: DiningHabit.fromMap(
        map['diningHabit'] as Map<String, dynamic>?,
      ),
      soundProfile: SoundProfile.fromMap(
        map['soundProfile'] as Map<String, dynamic>?,
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
      if (userType != null) 'userType': userType,
      if (jobKinds != null) 'jobKinds': jobKinds,
      if (dailyRhythm != null) 'dailyRhythm': dailyRhythm!.toMap(),
      if (workPattern != null) 'workPattern': workPattern!.toMap(),
      if (diningHabit != null) 'diningHabit': diningHabit!.toMap(),
      if (soundProfile != null) 'soundProfile': soundProfile!.toMap(),
      if (cleaningHabit != null) 'cleaningHabit': cleaningHabit!.toMap(),
      if (etcLife != null) 'etcLife': etcLife!.toMap(),
      if (disease != null) 'disease': disease!.toMap(),
      if (introduction != null) 'introduction': introduction,
    };
    if (skipNulls) map.removeWhere((_, v) => v == null);
    return map;
  }
}

/// 하루 리듬(온보딩) 서브모델
class DailyRhythm {
  final List<String> workDays;
  final List<String> alarms;
  final bool isJobLess;

  final int? weekAwakeMins;
  final int? weekGoWorkMins;
  final int? weekBackHomeMins;
  final int? weekSleepMins;
  final int? weekendAwakeMins;
  final int? weekendSleepMins;

  const DailyRhythm({
    required this.workDays,
    required this.alarms,
    required this.isJobLess,
    this.weekAwakeMins,
    this.weekGoWorkMins,
    this.weekBackHomeMins,
    this.weekSleepMins,
    this.weekendAwakeMins,
    this.weekendSleepMins,
  });

  Map<String, dynamic> toMap() => {
    'workDays': workDays,
    'alarms': alarms,
    'isJobLess': isJobLess,
    'week': {
      'awakeMins': weekAwakeMins,
      'goWorkMins': weekGoWorkMins,
      'backHomeMins': weekBackHomeMins,
      'sleepMins': weekSleepMins,
    },
    'weekend': {
      'awakeMins': weekendAwakeMins,
      'sleepMins': weekendSleepMins,
    },
  };

  static DailyRhythm? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final week = (map['week'] as Map<String, dynamic>?) ?? const {};
    final weekend = (map['weekend'] as Map<String, dynamic>?) ?? const {};
    return DailyRhythm(
      workDays: List<String>.from(map['workDays'] ?? const []),
      alarms: List<String>.from(map['alarms'] ?? const []),
      isJobLess: map['isJobLess'] == true,
      weekAwakeMins: week['awakeMins'] as int?,
      weekGoWorkMins: week['goWorkMins'] as int?,
      weekBackHomeMins: week['backHomeMins'] as int?,
      weekSleepMins: week['sleepMins'] as int?,
      weekendAwakeMins: weekend['awakeMins'] as int?,
      weekendSleepMins: weekend['sleepMins'] as int?,
    );
  }
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
  final List<String> delivery;
  const DiningHabit({
    required this.weeklyCooking,
    required this.smellSense,
    required this.dishShare,
    required this.delivery,
  });
  Map<String, dynamic> toMap() => {
    'weeklyCooking': weeklyCooking,
    'smellSense': smellSense,
    'dishShare': dishShare,
    'delivery': delivery,
  };
  static DiningHabit? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return DiningHabit(
      weeklyCooking: List<String>.from(m['weeklyCooking'] ?? const []),
      smellSense: List<String>.from(m['smellSense'] ?? const []),
      dishShare: List<String>.from(m['dishShare'] ?? const []),
      delivery: List<String>.from(m['delivery'] ?? const []),
    );
  }
}

class SoundProfile {
  final List<String> sleepSound;
  final List<String> sleepHabit;
  final List<String> soundMode;
  final List<String> earPhone;
  const SoundProfile({
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
  static SoundProfile? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return SoundProfile(
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
