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
      final snap = await tx.get(ref); // 문서를 트랜잭션 단위로 읽어서 저장

      final base = <String, dynamic>{
        ...appUser.toMap(), // 기존 appUser Map을 그대로 펼침 -> 알맹이만 꺼냄.
        'updatedAt': FieldValue.serverTimestamp(), // 이 줄 추가해서 새로 저장.
      };

      // 기존 회원이면
      if (snap.exists) {
        tx.set(ref, base, SetOptions(merge: true));
      } else {
        // 신규 회원이면
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
      SetOptions(merge: true), // 덮지 말고 합쳐주세요.
    );
  }

  Future<void> setUserJOb(DailyRhythm rhythm) async {
    await _meDoc().set(
      {
        'dailyRhythm': rhythm.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true), // 덮지 말고 합쳐주세요.
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

  /// 3) Coliving
  Future<void> setColiving(Coliving cl) async {
    await _meDoc().set(
      {
        'coliving': cl.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 4) Disease info
  Future<void> setDisease(DiseaseInfo d) async {
    await _meDoc().set(
      {
        'disease': d.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 5) Introduction text
  Future<void> setIntroduction(String introduction) async {
    await _meDoc().set(
      {
        'introduction': introduction,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setHobby(Hobby hobby) async {
    await _meDoc().set(
      {
        'UserLike': hobby.toMap(),

        'updatdAt': FieldValue.serverTimestamp(),
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
