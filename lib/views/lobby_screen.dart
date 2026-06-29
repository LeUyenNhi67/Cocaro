import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/online_game_controller.dart';
import '../services/online_service.dart';
import 'online_game_screen.dart';
import 'widgets/neon_button.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<dynamic> _rooms = [];
  bool _isLoading = false;
  bool _isCreating = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _fetchRooms();
    _subscribeToRoomChanges();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _subscribeToRoomChanges() {
    _supabase
        .channel('lobby_rooms')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'online_rooms',
          callback: (_) => _fetchRooms(),
        )
        .subscribe();
  }

  Future<void> _fetchRooms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('online_rooms')
          .select()
          .eq('status', 'waiting')
          .order('created_at', ascending: false);
      if (mounted) setState(() => _rooms = data);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createRoom() async {
    setState(() => _isCreating = true);
    try {
      final roomId =
          await OnlineService.createRoom(boardSize: 15, hostSymbol: 'X');
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OnlineGameScreen(
            controller: OnlineGameController(
              roomId: roomId,
              myUserId: _supabase.auth.currentUser!.id,
              isHost: true,
              boardSize: 15,
              hostSymbolStr: 'X',
            ),
          ),
        ),
      );
      _fetchRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tạo phòng: $e'),
            backgroundColor: const Color(0xFFFF007F),
          ),
        );
      }
    }
    if (mounted) setState(() => _isCreating = false);
  }

  Future<void> _joinRoom(Map<String, dynamic> room) async {
    final roomId = room['id'] as String;
    try {
      await OnlineService.joinRoom(roomId);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OnlineGameScreen(
            controller: OnlineGameController(
              roomId: roomId,
              myUserId: _supabase.auth.currentUser!.id,
              isHost: false,
              boardSize: room['board_size'] as int,
              hostSymbolStr: room['host_symbol'] as String,
            ),
          ),
        ),
      );
      _fetchRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể vào phòng: $e'),
            backgroundColor: const Color(0xFFFF007F),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'PHÒNG CHỜ ONLINE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white54, size: 20),
            onPressed: _fetchRooms,
            tooltip: 'Làm mới danh sách',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient orbs
          Positioned(
            top: -100,
            right: -100,
            child: _ambientOrb(const Color(0xFF00F2FE), 240),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _ambientOrb(const Color(0xFFFF007F), 220),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Create Room CTA
                  _buildCreateRoomCard(),
                  const SizedBox(height: 24),

                  // Section header
                  Row(
                    children: [
                      const Text(
                        'PHÒNG CHỜ HIỆN CÓ',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_isLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF00F2FE),
                          ),
                        )
                      else
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (_, __) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(
                                  alpha: 0.4 + 0.6 * _pulseAnimation.value),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withValues(
                                      alpha: 0.5 * _pulseAnimation.value),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${_rooms.length} phòng',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rooms list
                  Expanded(
                    child: _rooms.isEmpty && !_isLoading
                        ? _buildEmptyState()
                        : ListView.separated(
                            itemCount: _rooms.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _buildRoomCard(_rooms[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCreateRoomCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FE).withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF00F2FE),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo Phòng Mới',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bàn cờ 15×15 • Quân X đi trước',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NeonButton(
            text: _isCreating ? 'ĐANG TẠO PHÒNG...' : 'TẠO PHÒNG',
            icon: Icons.language_rounded,
            glowColor: const Color(0xFF00F2FE),
            gradientColors: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
            onPressed: _isCreating ? null : _createRoom,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final shortId = (room['id'] as String).substring(0, 8).toUpperCase();
    final boardSize = room['board_size'] as int;
    final hostSymbol = room['host_symbol'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Room icon + info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF007F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.meeting_room_rounded,
              color: Color(0xFFFF007F),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Phòng #$shortId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: room['id'] as String));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép ID phòng'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy_rounded,
                          color: Colors.white24, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${boardSize}×$boardSize • Host dùng quân $hostSymbol',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF007F),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => _joinRoom(room),
            child: const Text(
              'Vào Chơi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_esports_rounded,
            color: Colors.white12,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có phòng nào đang chờ',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy tạo phòng mới để bắt đầu trận đấu!',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
