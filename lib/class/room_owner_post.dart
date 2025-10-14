import 'package:cloud_firestore/cloud_firestore.dart';

/// 방 주인(방 제공자) 게시글 데이터 모델
class RoomOwnerPost {
  final String? postId;

  // 작성자/타입
  final String? authorId;
  final String? postType;
  final String? authorGender;

  // 내용
  final String? title;

  /// 지도용 좌표
  final GeoPoint? coordinate;

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
    this.coordinate,
    this.authorGender,
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

  Map<String, dynamic> toMap({bool skipNulls = true}) {
    final map = <String, dynamic>{
      'authorId': authorId,
      'postType': postType,
      'title': title,
      'authorGender': authorGender,
      'coordinate': coordinate, // GeoPoint
      'addressLabel': addressLabel, // 사람이 읽는 주소(뷰에서 사용)
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

    return RoomOwnerPost(
      postId: postId,
      authorId: map['authorId'] as String? ?? '',
      postType: map['postType'] as String?,
      title: map['title'] as String? ?? '제목 없음',
      authorGender: map['authorGender'] as String?,
      coordinate: map['coordinate'] as GeoPoint?,
      addressLabel: map['addressLabel'] as String?,
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

  factory RoomOwnerPost.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return RoomOwnerPost.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  /// addressLabel을 기반으로 "XX동 부근"
  String get getAddressLabel {
    final fullAddress = addressLabel;
    if (fullAddress == null || fullAddress.isEmpty) {
      return '주소 정보 없음';
    }

    // 1. 괄호 안의 동/읍/면 이름 추출
    final RegExp regExp = RegExp(r'\(([^)]+)\)');
    final match = regExp.firstMatch(fullAddress);
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

    // 2. 괄호가 없는 경우, 공백으로 분리하여 동/읍/면 찾기
    List<String> parts = fullAddress.split(' ');
    for (String part in parts) {
      if (part.endsWith('동') ||
          part.endsWith('읍') ||
          part.endsWith('면') ||
          part.endsWith('가')) {
        // '시'나 '구'로 끝나는 경우는 제외 (e.g. '강남구')
        if (!part.endsWith('시') && !part.endsWith('구')) {
          return '$part 부근';
        }
      }
    }

    // 3. 못 찾았을 경우, 두 번째 조각(보통 '시' 또는 '구') 사용
    if (parts.length > 1) {
      return '${parts[1]} 부근';
    }

    return '위치 정보 없음';
  }
}
