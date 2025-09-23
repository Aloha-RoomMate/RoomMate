// lib/class/user_repository.dart
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

  /// UserType
  Future<void> setUserTypeData({
    required String uid,
    required String type,
    required String jobKinds,
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

  /// Hobby
  Future<void> setHobby(Hobby hobby) async {
    await _meDoc().set(
      {
        'hobby': hobby.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// ✅ UserPass 저장/업데이트 (dailyRhythm 포함)
  Future<void> setUserPass({
    DailyRhythm? dailyRhythm,
    Coliving? coliving,
    DiseaseInfo? disease,
    Introduction? introduction,
  }) async {
    final docRef = _meDoc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final current = (snap.data()?['userPass'] as Map<String, dynamic>?) ?? {};

      // 기존 + 이번 입력 병합
      final merged = <String, dynamic>{
        ...current,
        if (dailyRhythm != null) 'dailyRhythm': dailyRhythm.toMap(),
        if (coliving != null) 'coliving': coliving.toMap(),
        if (disease != null) 'disease': disease.toMap(),
        if (introduction != null) 'introduction': introduction.toMap(),
      };

      // ✅ “섹션 맵 존재 여부”만으로 판정 (내부 값 null이어도 OK)
      final hasDaily = merged['dailyRhythm'] != null;
      final hasColiving = merged['coliving'] != null;
      final hasDisease = merged['disease'] != null;
      final hasIntroduction = merged['introduction'] != null;

      final isPass = hasDaily && hasColiving && hasDisease && hasIntroduction;

      tx.set(
        docRef,
        {
          'userPass': {
            ...merged,
            'pass': isPass,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<Map<String, dynamic>?> fetchUserPass() async {
    final snap = await _meDoc().get();
    if (!snap.exists) return null;
    return snap.data()?['userPass'] as Map<String, dynamic>?;
  }

  Stream<Map<String, dynamic>?> watchUserPass() {
    return _meDoc().snapshots().map((s) {
      if (!s.exists) return null;
      return s.data()?['userPass'] as Map<String, dynamic>?;
    });
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

  Future<AppUser?> fetchMe() async {
    final s = await _meDoc().get();
    return s.exists ? AppUser.fromDoc(s) : null;
  }

  Stream<AppUser?> watchMe() {
    return _meDoc().snapshots().map(
      (s) => s.exists ? AppUser.fromDoc(s) : null,
    );
  }
}
