// lib/data/user_repository.dart
//
// Firestore I/O for AppUser and all onboarding sections.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

// ⬇️ AppUser / DailyRhythm / WorkPattern ... 가 정의된 실제 경로로 바꿔주세요.
// 예) models 폴더면 아래 줄:
// import 'package:roommate/models/app_user.dart';
// 지금 네 코드가 class/app_user.dart 라면 그대로 두세요:
import 'package:roommate/class/app_user.dart';

class UserRepository {
  final FirebaseFirestore _db;
  final auth.FirebaseAuth _auth;

  UserRepository({
    FirebaseFirestore? db,
    auth.FirebaseAuth? authInstance,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = authInstance ?? auth.FirebaseAuth.instance;

  /// users/{uid} reference for current logged-in user.
  DocumentReference<Map<String, dynamic>> _meDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('로그인 필요: auth.currentUser가 null 입니다.');
    }
    return _db.collection('users').doc(uid);
  }

  /// Create or merge users/{uid} from FirebaseAuth user profile.
  /// - Sets createdAt only on first creation
  /// - Always updates updatedAt with server timestamp
  Future<void> upsertFromAuth() async {
    final u = _auth.currentUser;
    if (u == null) throw StateError('로그인 필요');

    final appUser = AppUser.fromAuth(u);
    final ref = _db.collection('users').doc(appUser.uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      final base = <String, dynamic>{
        ...appUser.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (snap.exists) {
        tx.set(ref, base, SetOptions(merge: true));
      } else {
        tx.set(
          ref,
          {
            ...base,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Section writers (each one merges into users/{uid} nested fields)
  // ---------------------------------------------------------------------------

  /// 1) User type & job kinds
  /// userType: "roomOwner" | "searcher"
  /// jobKinds example: ['회사/학교','재택',...]
  Future<void> setUserTypeAndJobs({
    required String userType,
    required List<String> jobKinds,
  }) async {
    await _meDoc().set(
      {
        'userType': userType,
        'jobKinds': jobKinds,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 2) Daily rhythm (nested object)
  Future<void> setDailyRhythm(DailyRhythm rhythm) async {
    await _meDoc().set(
      {
        'dailyRhythm': rhythm.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 3) Work pattern (lates/drinks)
  Future<void> setWorkPattern(WorkPattern wp) async {
    await _meDoc().set(
      {
        'workPattern': wp.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 4) Dining habit
  Future<void> setDiningHabit(DiningHabit dh) async {
    await _meDoc().set(
      {
        'diningHabit': dh.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 5) Sound profile
  Future<void> setSoundProfile(SoundProfile sp) async {
    await _meDoc().set(
      {
        'soundProfile': sp.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 6) Cleaning habit
  Future<void> setCleaningHabit(CleaningHabit ch) async {
    await _meDoc().set(
      {
        'cleaningHabit': ch.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 7) Etc life (smoking/pet/etc)
  Future<void> setEtcLife(EtcLife etc) async {
    await _meDoc().set(
      {
        'etcLife': etc.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 8) Disease info
  Future<void> setDisease(DiseaseInfo d) async {
    await _meDoc().set(
      {
        'disease': d.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 9) Introduction text
  Future<void> setIntroduction(String introduction) async {
    await _meDoc().set(
      {
        'introduction': introduction,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Optional: profile basics update (displayName/photoURL)
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    await _meDoc().set(
      {
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Readers
  // ---------------------------------------------------------------------------

  /// One-shot read of users/{uid}
  Future<AppUser?> fetchMe() async {
    final ref = _meDoc();
    final s = await ref.get();
    return s.exists ? AppUser.fromDoc(s) : null;
  }

  /// Realtime stream of users/{uid}
  Stream<AppUser?> watchMe() {
    final ref = _meDoc();
    return ref.snapshots().map(
      (s) => s.exists ? AppUser.fromDoc(s) : null,
    );
  }
}
