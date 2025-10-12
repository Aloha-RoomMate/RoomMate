import 'package:cloud_firestore/cloud_firestore.dart';

/// 방을 구하는 사람(Searcher)의 게시글 데이터 모델
class SearcherPost {
  final String? postId;

  // 작성자/타입
  final String? authorId;
  final String? postType;
  final String? authorGender;

  // 내용
  final String? title;

  // 희망 조건
  final List<String>? wantArea;
  final List<String>? wantRoom;
  final List<String>? wantPay;

  // 금액/정보
  final int? deposit;
  final int? minRent;
  final int? maxRent;

  // 날짜/기간
  final Timestamp? movingDate;
  final int? minContract;
  final int? maxContract;

  // 설명/이미지
  final String? introduction;
  final List<String>? imageUrls;

  // 생성 시각(서버시간)
  final DateTime? createdAt;

  const SearcherPost({
    this.postId,
    this.authorId,
    this.postType = 'Searcher', // 기본값을 'Searcher'로 설정
    this.authorGender,
    this.title,
    this.wantArea,
    this.wantRoom,
    this.wantPay,
    this.deposit,
    this.minRent,
    this.maxRent,
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
      'authorGender': authorGender,
      'title': title,
      'wantArea': wantArea,
      'wantRoom': wantRoom,
      'wantPay': wantPay,
      'deposit': deposit,
      'minRent': minRent,
      'maxRent': maxRent,
      'movingDate': movingDate,
      'minContract': minContract,
      'maxContract': maxContract,
      'introduction': introduction,
      'imageUrls': imageUrls,
    };
    if (skipNulls) map.removeWhere((_, v) => v == null);
    return map;
  }

  factory SearcherPost.fromMap(String postId, Map<String, dynamic> map) {
    List<String>? toStringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return null;
    }

    return SearcherPost(
      postId: postId,
      authorId: map['authorId'] as String?,
      postType: map['postType'] as String?,
      authorGender: map['authorGender'] as String?,
      title: map['title'] as String? ?? '제목 없음',
      wantArea: toStringList(map['wantArea']),
      wantRoom: toStringList(map['wantRoom']),
      wantPay: toStringList(map['wantPay']),
      deposit: (map['deposit'] as num?)?.toInt(),
      minRent: (map['minRent'] as num?)?.toInt(),
      maxRent: (map['maxRent'] as num?)?.toInt(),
      movingDate: map['movingDate'] as Timestamp?,
      minContract: (map['minContract'] as num?)?.toInt(),
      maxContract: (map['maxContract'] as num?)?.toInt(),
      introduction: map['introduction'] as String?,
      imageUrls: toStringList(map['imageUrls']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory SearcherPost.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return SearcherPost.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }
}