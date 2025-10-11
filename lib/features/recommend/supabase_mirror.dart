import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:roommate/class/app_user.dart';
import 'package:roommate/features/recommend/compatibility.dart';
import 'package:roommate/features/recommend/intro_vector.dart';

class SupabaseMirror {
  final _supa = Supabase.instance.client;

  Future<void> upsertUserMirror(AppUser u) async {
    final vecStruct = buildStructVector(u); // 74
    final introText = (u.introduction is String)
        ? (u.introduction as String)
        : (u.introduction ?? '');
    final vecText = hashBigramVector(introText, dim: 512); // 512

    await _supa.from('users_public').upsert({
      'uid': u.uid,
      'display_name': u.displayName,
      'photo_url': u.photoURL,
      'user_type': u.userType?.type,
      'pass': u.userPass?.pass == true,
      'updated_at': DateTime.now().toIso8601String(),
      'vec_struct': vecStruct,
      'vec_text': vecText,
    });
  }
}
