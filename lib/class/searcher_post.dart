import 'package:cloud_firestore/cloud_firestore.dart';

/// 방을 구하는 사람(Searcher)의 게시글 데이터 모델
class SearcherPost {
  final String? postId;

  // 작성자/타입
  final String? authorId;
  final String? postType;

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
      // createdAt은 보통 서버에서 타임스탬프를 찍으므로 toMap에서는 제외하는 경우가 많습니다.
      // 필요하다면 'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null 추가
    };
    if (skipNulls) map.removeWhere((_, v) => v == null);
    return map;
  }

  factory SearcherPost.fromMap(String postId, Map<String, dynamic> map) {
    // List<dynamic>을 안전하게 List<String>으로 변환하는 헬퍼 함수
    List<String>? toStringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return null;
    }

    return SearcherPost(
      postId: postId,
      authorId: map['authorId'] as String?,
      postType: map['postType'] as String?,
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
