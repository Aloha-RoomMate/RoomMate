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

  DocumentReference<Map<String, dynamic>> _meDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('로그인 필요: auth.currentUser가 null 입니다.');
    }
    return _db.collection('users').doc(uid);
  }

  // ---------------------------------------------------------------------------
  // 기본 upsert
  // ---------------------------------------------------------------------------

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
            // 최초 생성 시 pass 기본 false로 초기화(없으면 fromMap에서 false 처리되긴 함)
            'userPass': {'pass': false},
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // userPass 집계/판정 로직 (상위 필드만 보고 판단)
  // ---------------------------------------------------------------------------

  bool _calcPass(Map<String, dynamic> data) {
    final dr = data['dailyRhythm'];
    final cl = data['coliving'];
    final ds = data['disease'];

    // introduction은 string 또는 { introduction: string } 모두 허용
    final introAny = data['introduction'];
    final introText = (introAny is Map)
        ? (introAny['introduction']?.toString() ?? '')
        : (introAny is String ? introAny : '');

    final hasDR = dr is Map && dr.isNotEmpty;
    final hasCL = cl is Map && cl.isNotEmpty;
    final hasDS = ds is Map && ds.isNotEmpty;
    final hasIntro = introText.length >= 50;

    return hasDR && hasCL && hasDS && hasIntro;
  }

  Future<void> _recomputeAndSetPass() async {
    final ref = _meDoc();
    final snap = await ref.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final pass = _calcPass(data);

    await ref.set(
      {
        'userPass': {'pass': pass}, // ✅ pass만 유지
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> getUserPassStatus() async {
    final s = await _meDoc().get();
    final data = s.data() ?? const <String, dynamic>{};
    return _calcPass(data);
  }

  Stream<bool> watchUserPassStatus() {
    return _meDoc().snapshots().map((s) {
      final data = s.data() ?? const <String, dynamic>{};
      return _calcPass(data);
    });
  }

  // ---------------------------------------------------------------------------
  // Writers (상위 필드 저장 + pass만 재계산)
  // ---------------------------------------------------------------------------

  Future<void> setDailyRhythm(DailyRhythm rhythm) async {
    final ref = _meDoc();
    await ref.set(
      {
        'dailyRhythm': rhythm.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _recomputeAndSetPass();
  }

  Future<void> setUserTypeData({
    required String uid,
    required String type,
    required String jobKinds, // 문자열 유지
    required String address,
    List<String>? searchAreas,
  }) async {
    await _db.collection('users').doc(uid).set({
      'userType': {
        'type': type,
        'jobKinds': jobKinds,
        'address': address,
        'searchAreas': searchAreas,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setColiving(Coliving cl) async {
    final ref = _meDoc();
    await ref.set(
      {
        'coliving': cl.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _recomputeAndSetPass();
  }

  Future<void> setDisease(DiseaseInfo d) async {
    final ref = _meDoc();
    await ref.set(
      {
        'disease': d.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _recomputeAndSetPass();
  }

  Future<void> setIntroduction(Introduction introduction) async {
    final ref = _meDoc();
    final map = introduction.toMap(); // { introduction: ... }
    await ref.set(
      {
        'introduction': map, // 상위 필드에도 동일 포맷
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _recomputeAndSetPass();
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? gender,
  }) async {
    await _meDoc().set(
      {
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        if (gender != null) 'gender': gender,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setHobby(Hobby hobby) async {
    // ✅ 취미는 UserLike 로만 저장 (중복 저장 방지)
    await _meDoc().set(
      {
        'UserLike': hobby.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    // pass 기준에는 포함하지 않으므로 재계산 생략(정책에 따라 넣고 싶으면 호출)
    // await _recomputeAndSetPass();
  }

  // ---------------------------------------------------------------------------
  // Readers
  // ---------------------------------------------------------------------------

  Future<AppUser?> fetchMe() async {
    final ref = _meDoc();
    final s = await ref.get();
    return s.exists ? AppUser.fromDoc(s) : null;
  }

  Stream<AppUser?> watchMe() {
    final ref = _meDoc();
    return ref.snapshots().map(
      (s) => s.exists ? AppUser.fromDoc(s) : null,
    );
  }

  Future<AppUser?> fetchUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromDoc(doc);
    }
    return null;
  }
}
