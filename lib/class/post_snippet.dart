// lib/class/post_snippet.dart
import 'package:intl/intl.dart';

/// 채팅에서 사용하는 '게시글 요약 카드' 모델
class PostSnippet {
  final String postId;
  final String title;
  final String nearLabel;
  final int? deposit; // 만원 기준
  final int? rent; // 만원 기준
  final int? manageFee; // 만원 기준
  final String? imagePath; // Supabase Storage 경로

  const PostSnippet({
    required this.postId,
    required this.title,
    required this.nearLabel,
    this.deposit,
    this.rent,
    this.manageFee,
    this.imagePath,
  });

  factory PostSnippet.fromMap(Map<String, dynamic> map) {
    return PostSnippet(
      postId: (map['postId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      nearLabel: (map['nearLabel'] ?? '').toString(),
      deposit: _asIntNullable(map['deposit']),
      rent: _asIntNullable(map['rent']),
      manageFee: _asIntNullable(map['manageFee']),
      imagePath: (map['imagePath'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() => {
    'postId': postId,
    'title': title,
    'nearLabel': nearLabel,
    'deposit': deposit,
    'rent': rent,
    'manageFee': manageFee,
    'imagePath': imagePath,
  };

  static int? _asIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      return p;
    }
    return null;
  }

  String priceLabel() {
    final f = NumberFormat.decimalPattern();
    final d = deposit ?? 0;
    final r = rent ?? 0;
    final m = manageFee ?? 0;

    final parts = <String>[];
    parts.add('보증금 ${f.format(d)}만');
    parts.add('월세 ${f.format(r)}만');
    if (m > 0) parts.add('관리비 ${f.format(m)}만');
    return parts.join(' · ');
  }
}
