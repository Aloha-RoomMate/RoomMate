import 'package:cloud_firestore/cloud_firestore.dart';

class RoomOwnerPost {
  // Firestore 문서의 고유 ID
  final String? postId;

  // 유저 정보
  final String? authorId;

  // 글 정보
  final String? title;
  final GeoPoint? addr;
  final int? deposit;
  final int? rent;
  final int? manageFee;
  final int? corFloor;
  final int? wholeFloor;
  final int? area;
  final int? toilet;
  final Timestamp? movingDate;
  final int? minContract;
  final int? maxContract;
  final String? introduction;
  final DateTime? createdAt;

  const RoomOwnerPost({
    this.postId,
    required this.authorId,
    this.title,
    this.addr,
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
    this.createdAt,
  });

  RoomOwnerPost copyWith({
    String? postId,
    String? authorId,
    String? title,
    GeoPoint? addr,
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
  }) {
    return RoomOwnerPost(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      addr: addr ?? this.addr,
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
    );
  }

  Map<String, dynamic> toMap({bool skipNulls = true}) {
    final map = <String, dynamic>{
      'authorId': authorId,
      'title': title,
      'addr': addr,
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
    };

    if (skipNulls) map.removeWhere((_, value) => value == null);
    return map;
  }

  /// return을 하는 특별한 생성자 => factory
  factory RoomOwnerPost.fromMap(String postId, Map<String, dynamic> map) {
    return RoomOwnerPost(
      postId: postId,
      authorId: map['authorId'] as String? ?? '',
      title: map['title'] as String? ?? '제목 없음',
      addr: map['addr'] as GeoPoint?,
      deposit: map['deposit'] as int?,
      rent: map['rent'] as int?,
      manageFee: map['manageFee'] as int?,
      corFloor: map['corFloor'] as int?,
      wholeFloor: map['wholeFloor'] as int?,
      area: map['area'] as int?,
      toilet: map['toilet'] as int?,
      movingDate: (map['movingDate'] as Timestamp?),
      minContract: map['minContract'] as int?,
      maxContract: map['maxContract'] as int?,
      introduction: map['introduction'] as String?,
    );
  }

  /// Doc에서 map
  factory RoomOwnerPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return RoomOwnerPost.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }
}
