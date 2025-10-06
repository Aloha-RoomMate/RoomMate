import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 방 주인(방 제공자) 게시글 데이터 모델
class RoomOwnerPost {
  // 문서 ID
  final String? postId;

  // 작성자/타입
  final String? authorId;
  final String? postType;

  // 내용
  final String? title;

  /// 좌표(지도/검색용)
  final GeoPoint? addr;

  /// 표시용 주소 라벨(예: "강북구 송중동 부근")
  final String? addressLabel;

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

  // 생성 시각(서버시간)
  final DateTime? createdAt;

  const RoomOwnerPost({
    this.postId,
    required this.authorId,
    this.postType,
    this.title,
    this.addr,
    this.addressLabel,
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
  });

  RoomOwnerPost copyWith({
    String? postId,
    String? authorId,
    String? postType,
    String? title,
    GeoPoint? addr,
    String? addressLabel,
    int? deposit,
    int? rent,
    int? manageFee,
    int? corFloor,
    int? wholeFloor,
    int? area,
    int? toilet,
    Timestamp? movingDate,
    int? minContract,
    int? maxContract,
    String? introduction,
    List<String>? imageUrls,
    DateTime? createdAt,
  }) {
    return RoomOwnerPost(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      postType: postType ?? this.postType,
      title: title ?? this.title,
      addr: addr ?? this.addr,
      addressLabel: addressLabel ?? this.addressLabel,
      deposit: deposit ?? this.deposit,
      rent: rent ?? this.rent,
      manageFee: manageFee ?? this.manageFee,
      corFloor: corFloor ?? this.corFloor,
      wholeFloor: wholeFloor ?? this.wholeFloor,
      area: area ?? this.area,
      toilet: toilet ?? this.toilet,
      movingDate: movingDate ?? this.movingDate,
      minContract: minContract ?? this.minContract,
      maxContract: maxContract ?? this.maxContract,
      introduction: introduction ?? this.introduction,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Firestore 업로드용 맵
  Map<String, dynamic> toMap({bool skipNulls = true}) {
    final map = <String, dynamic>{
      'authorId': authorId,
      'postType': postType,
      'title': title,
      'addr': addr, // GeoPoint
      'addressLabel': addressLabel, // 사람이 읽는 주소
      'deposit': deposit,
      'rent': rent,
      'manageFee': manageFee,
      'corFloor': corFloor,
      'wholeFloor': wholeFloor,
      'area': area,
      'toilet': toilet,
      'movingDate': movingDate, // Timestamp
      'minContract': minContract,
      'maxContract': maxContract,
      'introduction': introduction,
      'imageUrls': imageUrls,
      // createdAt은 레포지토리에서 serverTimestamp로 넣음
    };

    if (skipNulls) {
      map.removeWhere((_, v) => v == null);
    }
    return map;
  }

  /// Map → 모델
  factory RoomOwnerPost.fromMap(String postId, Map<String, dynamic> map) {
    // imageUrls가 dynamic 리스트로 올 수 있으니 캐스팅 안전 처리
    List<String>? toStringList(dynamic v) {
      if (v == null) return null;
      if (v is List) return v.map((e) => e.toString()).toList();
      return null;
    }

    return RoomOwnerPost(
      postId: postId,
      authorId: map['authorId'] as String? ?? '',
      postType: map['postType'] as String?,
      title: map['title'] as String? ?? '제목 없음',
      addr: map['addr'] as GeoPoint?,
      addressLabel: map['addressLabel'] as String?, // ✅ 추가
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
      introduction: map['introduction'] as String?,
      imageUrls: toStringList(map['imageUrls']),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Doc → 모델
  factory RoomOwnerPost.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return RoomOwnerPost.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }
}
