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
  final UserType? userType;
  final Hobby? hobby;
  final UserPass? userPass; // ✅ 묶음 객체

  const AppUser({
    required this.uid,
    this.email,
    required this.displayName,
    this.photoURL,
    this.createdAt,
    this.updatedAt,
    this.userType,
    this.hobby,
    this.userPass,
  });

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
      displayName: map['displayName'] as String? ?? '룸메이트',
      photoURL: map['photoURL'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      userType: UserType.fromMap(map['userType'] as Map<String, dynamic>?),
      hobby: Hobby.fromMap(map['hobby'] as Map<String, dynamic>?),
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
      if (userType != null) 'userType': userType!.toMap(),
      if (hobby != null) 'hobby': hobby!.toMap(),
      if (userPass != null) 'userPass': userPass!.toMap(),
    };
    if (skipNulls) map.removeWhere((_, v) => v == null);
    return map;
  }
}

/// ------------------------------------------------------------
/// UserPass 묶음 모델
/// ------------------------------------------------------------
class UserPass {
  final DailyRhythm? dailyRhythm;
  final Coliving? coliving;
  final DiseaseInfo? disease;
  final Introduction? introduction;
  final bool pass;

  const UserPass({
    this.dailyRhythm,
    this.coliving,
    this.disease,
    this.introduction,
    required this.pass,
  });

  factory UserPass.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPass(pass: false);
    return UserPass(
      dailyRhythm: DailyRhythm.fromMap(
        map['dailyRhythm'] as Map<String, dynamic>?,
      ),
      coliving: Coliving.fromMap(map['coliving'] as Map<String, dynamic>?),
      disease: DiseaseInfo.fromMap(map['disease'] as Map<String, dynamic>?),
      introduction: Introduction.fromMap(
        map['introduction'] as Map<String, dynamic>?,
      ),
      pass: map['pass'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (dailyRhythm != null) 'dailyRhythm': dailyRhythm!.toMap(),
      if (coliving != null) 'coliving': coliving!.toMap(),
      if (disease != null) 'disease': disease!.toMap(),
      if (introduction != null) 'introduction': introduction!.toMap(),
      'pass': pass,
    };
  }
}

/// ------------------------------------------------------------
/// DailyRhythm, UserType, Coliving, DiseaseInfo, Introduction, Hobby
/// ------------------------------------------------------------
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
  final String type;
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
      jobKinds: map['jobKinds'] ?? "",
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
    'pet': pet,
    'mbti': mbti,
  };

  static Coliving? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
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
  final bool? isHealthy;
  final String? diseases;
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
  final List<String> interestLike;
  final List<String> sportLike;

  const Hobby({
    required this.foodLike,
    required this.interestLike,
    required this.sportLike,
  });

  Map<String, dynamic> toMap() => {
    'foodLike': foodLike,
    'interestLike': interestLike,
    'sportLike': sportLike,
  };

  static Hobby? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return Hobby(
      foodLike: List<String>.from(map['foodLike'] ?? const []),
      interestLike: List<String>.from(map['interestLike'] ?? const []),
      sportLike: List<String>.from(map['sportLike'] ?? const []),
    );
  }
}
