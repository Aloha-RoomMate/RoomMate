// lib/class/room_owner_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// 방 주인(방 제공자) 게시글 데이터 모델
class RoomOwnerPost {
  final String? postId;

  // 작성자/타입
  final String? authorId;
  final String? postType;
  final String? authorGender;
  final String? status;

  // 내용
  final String? title;

  /// 지도용 좌표
  final GeoPoint? coordinate;

  /// 도로명 주소
  final String? roadAddress;

  /// 지번 주소
  final String? jibunAddress;

  // 금액/정보
  final int? deposit;
  final int? rent;
  final int? manageFee;
  final int? corFloor;
  final int? wholeFloor;
  final int? area;
  final int? toilet;

  // 날짜/기간
  final Timestamp? movingDate; // Firestore Timestamp
  final int? minContract;
  final int? maxContract;

  // 설명/이미지
  final String? introduction;
  final List<String>? imageUrls;

  // 생성/수정 시각(서버시간 → DateTime으로 노멀라이즈)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RoomOwnerPost({
    this.postId,
    required this.authorId,
    this.postType,
    this.authorGender,
    this.status,
    this.title,
    this.coordinate,
    this.roadAddress,
    this.jibunAddress,
    this.deposit,
    this.rent,
    this.manageFee,
    this.corFloor,
    this.wholeFloor,
    this.area,
    this.toilet,
    this.movingDate,
    this.minContract,
    this.maxContract,
    this.introduction,
    this.imageUrls,
    this.createdAt,
    this.updatedAt,
  });

  // Timestamp / DateTime / int(ms) / String(ISO) → DateTime?
  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap({bool skipNulls = true}) {
    final map = <String, dynamic>{
      'authorId': authorId,
      'postType': postType,
      'authorGender': authorGender,
      'status': status ?? 'open',
      'title': title,
      'coordinate': coordinate,
      'roadAddress': roadAddress,
      'jibunAddress': jibunAddress,
      'deposit': deposit,
      'rent': rent,
      'manageFee': manageFee,
      'corFloor': corFloor,
      'wholeFloor': wholeFloor,
      'area': area,
      'toilet': toilet,
      'movingDate': movingDate,
      'minContract': minContract,
      'maxContract': maxContract,
      'introduction': introduction,
      'imageUrls': imageUrls,
      // createdAt/updatedAt은 Repository에서 serverTimestamp로 관리
    };
    if (skipNulls) map.removeWhere((_, v) => v == null);
    return map;
  }

  factory RoomOwnerPost.fromMap(String postId, Map<String, dynamic> map) {
    List<String>? toStringList(dynamic v) {
      if (v == null) return null;
      if (v is List) return v.map((e) => e.toString()).toList();
      return null;
    }

    String? safeStr(dynamic v) => v is String ? v : null;

    return RoomOwnerPost(
      postId: postId,
      authorId: safeStr(map['authorId']) ?? '',
      postType: safeStr(map['postType']),
      authorGender: safeStr(map['authorGender']),
      status: safeStr(map['status']) ?? 'open',
      title: safeStr(map['title']) ?? '제목 없음',
      coordinate: map['coordinate'] as GeoPoint?,
      roadAddress: safeStr(map['roadAddress']) ?? safeStr(map['addressLabel']),
      jibunAddress: safeStr(map['jibunAddress']),
      deposit: (map['deposit'] as num?)?.toInt(),
      rent: (map['rent'] as num?)?.toInt(),
      manageFee: (map['manageFee'] as num?)?.toInt(),
      corFloor: (map['corFloor'] as num?)?.toInt(),
      wholeFloor: (map['wholeFloor'] as num?)?.toInt(),
      area: (map['area'] as num?)?.toInt(),
      toilet: (map['toilet'] as num?)?.toInt(),
      movingDate: map['movingDate'] as Timestamp?,
      minContract: (map['minContract'] as num?)?.toInt(),
      maxContract: (map['maxContract'] as num?)?.toInt(),
      introduction: safeStr(map['introduction']),
      imageUrls: toStringList(map['imageUrls']),
      createdAt: _asDate(map['createdAt']),
      updatedAt: _asDate(map['updatedAt']),
    );
  }

  factory RoomOwnerPost.fromDoc(DocumentSnapshot doc) {
    final data =
        (doc.data() as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return RoomOwnerPost.fromMap(doc.id, data);
    // 제네릭이 Map<String,dynamic>이든 dynamic이든 안전하게 캐스팅
  }

  // 편의 getter
  bool get isOpen => (status ?? 'open') == 'open';
  bool get isClosed => (status ?? 'open') == 'closed';
  bool get isMatched => (status ?? '') == 'matched';
  bool get isCompleted => (status ?? '') == 'completed';

  /// jibunAddress를 기반으로 "XX동 부근"
  String get getAddressLabel {
    final fullAddress = jibunAddress;
    if (fullAddress == null || fullAddress.isEmpty) {
      return roadAddress ?? '주소 정보 없음';
    }

    final cleanedAddress = fullAddress.replaceAll(RegExp(r'\s*부근$'), '').trim();
    if (cleanedAddress.isEmpty) return '주소 정보 없음';

    final RegExp regExp = RegExp(r'\(([^)]+)\)');
    final match = regExp.firstMatch(cleanedAddress);
    if (match != null) {
      final dongName = match.group(1);
      if (dongName != null &&
          (dongName.endsWith('동') ||
              dongName.endsWith('읍') ||
              dongName.endsWith('면') ||
              dongName.endsWith('가'))) {
        return '$dongName 부근';
      }
    }

    final parts = cleanedAddress.split(' ');

    for (final part in parts) {
      if (part.endsWith('동') ||
          part.endsWith('읍') ||
          part.endsWith('면') ||
          part.endsWith('리') ||
          part.endsWith('가')) {
        return '$part 부근';
      }
    }

    for (final part in parts) {
      if (part.endsWith('시') || part.endsWith('구')) {
        return '$part 부근';
      }
    }

    return '위치 정보 없음';
  }
}
