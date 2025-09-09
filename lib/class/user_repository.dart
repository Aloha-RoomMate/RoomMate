import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:roommate/class/app_user.dart';

class UserRepository {
  final FirebaseFirestore _db;
  final auth.FirebaseAuth _auth;

  UserRepository({
    FirebaseFirestore? db,
    auth.FirebaseAuth? authInstance,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = authInstance ?? auth.FirebaseAuth.instance;

  /// 로그인 한 유저의 firestore 경로 : _meDoc()
  DocumentReference<Map<String, dynamic>> _meDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('로그인 필요: auth.currentUser가 null 입니다.');
    }
    return _db.collection('users').doc(uid);
  }

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

  Future<void> setUserTypeData({
    required String uid,
    required String type,
    required String jobKinds, // ✅ String으로 수정
    required String address,
    List<String>? searchAreas,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'userType': {
        'type': type,
        'jobKinds': jobKinds, // ✅ 문자열로 저장
        'address': address,
        'searchAreas': searchAreas,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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
      /// .set : firestore 에 병합 저장 실행
      {
        'cleaningHabit': ch.toMap(),

        /// 객체를 JSON 형태로 변환
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
