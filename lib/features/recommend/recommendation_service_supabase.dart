// lib/features/recommend/recommendation_service_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRecommendationService {
  final _supa = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetch(String uid, {int topK = 50}) async {
    final res = await _supa.rpc(
      'recommend_rpc',
      params: {
        'p_uid': uid,
        'p_topk': topK,
      },
    );
    // res: List<Map<String, dynamic>> (uid, display_name, photo_url, score)
    return (res as List).cast<Map<String, dynamic>>();
  }
}

class RecUser {
  final String uid;
  final String name;
  final String? photoURL;
  final double score;
  const RecUser({
    required this.uid,
    required this.name,
    this.photoURL,
    required this.score,
  });
}

Future<List<RecUser>> getRecs(String myUid) async {
  final svc = SupabaseRecommendationService();
  final rows = await svc.fetch(myUid, topK: 80);
  return rows
      .map(
        (r) => RecUser(
          uid: r['uid'] as String,
          name: (r['display_name'] ?? '룸메이트') as String,
          photoURL: r['photo_url'] as String?,
          score: (r['score'] as num).toDouble(),
        ),
      )
      .toList();
}
