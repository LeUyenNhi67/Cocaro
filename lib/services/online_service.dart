import 'package:supabase_flutter/supabase_flutter.dart';

class OnlineService {
  static final _supabase = Supabase.instance.client;

  static Future<String> createRoom({
    required int boardSize,
    required String hostSymbol,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase.from('online_rooms').insert({
      'host_id': userId,
      'board_size': boardSize,
      'host_symbol': hostSymbol,
      'status': 'waiting',
    }).select().single();

    return response['id'] as String;
  }

  static Future<void> joinRoom(String roomId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('online_rooms').update({
      'guest_id': userId,
      'status': 'playing',
    }).eq('id', roomId);
  }

  static Future<void> leaveRoom(String roomId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final room = await _supabase.from('online_rooms').select().eq('id', roomId).single();
    if (room['host_id'] == userId) {
      await _supabase.from('online_rooms').delete().eq('id', roomId);
    } else if (room['guest_id'] == userId) {
      await _supabase.from('online_rooms').update({
        'guest_id': null,
        'status': 'waiting',
      }).eq('id', roomId);
    }
  }

  static RealtimeChannel subscribeToRoom(
    String roomId, {
    required void Function(Map<String, dynamic> payload) onMove,
    required void Function(Map<String, dynamic> payload) onGameEnd,
  }) {
    final channel = _supabase.channel('room:$roomId');

    channel.onBroadcast(
      event: 'move',
      callback: (payload) => onMove(payload),
    ).onBroadcast(
      event: 'game_end',
      callback: (payload) => onGameEnd(payload),
    );

    return channel;
  }
}
