import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rank_model.dart';

class RankService {
  static Future<int> addMatchResult({
    required String mode,
    required String result, // 'WIN', 'LOSS', 'DRAW'
    required bool isHardAi,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    int earned = 0;
    if (result == 'WIN') {
      earned = isHardAi ? 15 : 10;
    } else if (result == 'DRAW') {
      earned = 3;
    }

    final metadata = Map<String, dynamic>.from(user.userMetadata ?? {});
    final currentDiamonds = (metadata['diamonds'] as int?) ?? 0;
    final newDiamonds = currentDiamonds + earned;

    final List history = List.from(metadata['match_history'] ?? []);
    history.insert(0, {
      'mode': mode,
      'result': result,
      'diamonds': earned,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep last 30 matches
    if (history.length > 30) {
      history.removeRange(30, history.length);
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          'diamonds': newDiamonds,
          'match_history': history,
        }),
      );
    } catch (_) {}

    return earned;
  }

  static int getUserDiamonds() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;
    return (user.userMetadata?['diamonds'] as int?) ?? 0;
  }

  static RankModel getUserRank() {
    return RankModel.getRankFromDiamonds(getUserDiamonds());
  }

  static List<Map<String, dynamic>> getMatchHistory() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final rawList = user.userMetadata?['match_history'] as List?;
    if (rawList == null) return [];
    return rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
