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
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // userPass 집계/판정 로직
  // ---------------------------------------------------------------------------

  /// 현재 문서를 읽어 userPass.pass 조건을 계산한다.
  bool _calcPass(Map<String, dynamic> data) {
    final up =
        (data['userPass'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    final hasDR =
        up['dailyRhythm'] is Map && (up['dailyRhythm'] as Map).isNotEmpty;
    final hasCL = up['coliving'] is Map && (up['coliving'] as Map).isNotEmpty;
    final hasDS = up['disease'] is Map && (up['disease'] as Map).isNotEmpty;

    // introduction은 현재 { introduction: String } 형태로 저장되는 경우 지원
    final introAny = up['introduction'];
    final introText = (introAny is Map)
        ? (introAny['introduction']?.toString() ?? '')
        : (introAny is String ? introAny : '');
    final hasIntro = introText.length >= 50;

    return hasDR && hasCL && hasDS && hasIntro;
  }

  /// userPass.pass를 재계산해서 저장 (userPass 부분이 변경될 때마다 호출)
  Future<void> _recomputeAndSetPass() async {
    final ref = _meDoc();
    final snap = await ref.get();
    final data = snap.data() ?? const <String, dynamic>{};
    final pass = _calcPass(data);

    await ref.set(
      {
        'userPass': {'pass': pass},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 런타임 계산 버전(저장 안 해도 바로 락 상태 확인 가능)
  Future<bool> getUserPassStatus() async {
    final s = await _meDoc().get();
    final data = s.data() ?? const <String, dynamic>{};
    return _calcPass(data);
  }

  /// 실시간 계산(마이페이지에서 오버레이 락에 쓰면 즉시 반영)
  Stream<bool> watchUserPassStatus() {
    return _meDoc().snapshots().map((s) {
      final data = s.data() ?? const <String, dynamic>{};
      return _calcPass(data);
    });
  }

  // ---------------------------------------------------------------------------
  // Writers (상위 필드 + userPass.* 함께 세팅)
  // ---------------------------------------------------------------------------

  Future<void> setDailyRhythm(DailyRhythm rhythm) async {
    final ref = _meDoc();
    await ref.set(
      {
        'dailyRhythm': rhythm.toMap(),
        'userPass': {
          'dailyRhythm': rhythm.toMap(),
        },
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
    final map = cl.toMap();
    await ref.set(
      {
        'coliving': map,
        'userPass': {
          'coliving': map,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _recomputeAndSetPass();
  }

  Future<void> setDisease(DiseaseInfo d) async {
    final ref = _meDoc();
    final map = d.toMap();
    await ref.set(
      {
        'disease': map,
        'userPass': {
          'disease': map,
        },
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
        'userPass': {
          'introduction': map,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _recomputeAndSetPass();
  }

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

  Future<void> setHobby(Hobby hobby) async {
    await _meDoc().set(
      {
        // 과거 'UserLike' 키도 유지한다면 아래 라인 그대로,
        // 새로 'hobby'로만 쓰려면 'hobby': hobby.toMap() 로 변경.
        'UserLike': hobby.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
