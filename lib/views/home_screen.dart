import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/ai_controller.dart';
import '../controllers/game_controller.dart';
import '../models/board_position.dart';
import '../models/badge_model.dart';

import '../services/rank_service.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';
import 'profile_screen.dart';
import 'widgets/leaderboard_modal.dart';
import 'widgets/neon_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get _isLoggedIn =>
      Supabase.instance.client.auth.currentUser != null;

  GameMode _selectedMode = GameMode.passAndPlay;
  int _selectedSize = 20;
  Player _userSymbol =
      Player.X; // In VS AI, which symbol user plays. Opponent is AI.
  AiDifficulty _selectedDifficulty = AiDifficulty.medium;



  Widget _buildProfileHeaderAction() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final metadata = user.userMetadata;
    final nickname =
        metadata?['nickname'] as String? ?? user.email?.split('@').first ?? 'Người chơi';
    final avatarBase64 = metadata?['avatar_base64'] as String?;

    ImageProvider? imageProvider;
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(avatarBase64));
      } catch (_) {}
    }

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        if (mounted) {
          setState(() {}); // Refresh avatar and nickname when returning
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00F2FE).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F2FE).withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: imageProvider != null
                    ? Image(image: imageProvider, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFF00F2FE).withOpacity(0.2),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF00F2FE),
                          size: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              nickname,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard(BuildContext context) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    final rank = RankService.getUserRank();
    final diamonds = RankService.getUserDiamonds();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const LeaderboardModal(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rank.color.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: rank.color.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(rank.icon, color: rank.color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BẢNG XẾP HẠNG & RANK',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  rank.title,
                  style: TextStyle(
                    color: rank.color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.diamond_rounded, color: Color(0xFF00F2FE), size: 18),
                const SizedBox(width: 4),
                Text(
                  '$diamonds',
                  style: const TextStyle(
                    color: Color(0xFF00F2FE),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        actions: [
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(child: _buildProfileHeaderAction()),
            ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Ambient Background Glowing Spheres
          Positioned(
            top: -100,
            left: -100,
            child: _buildAmbientOrb(const Color(0xFF00F2FE), 250),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: _buildAmbientOrb(const Color(0xFFFF007F), 250),
          ),
          // Glassmorphic overlay filter
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 2. Main Menu Contents
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    // Header Logo & Title
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildRankCard(context),
                    const SizedBox(height: 32),

                    // Game Mode Selection Cards
                    _buildSectionHeader('CHỌN CHẾ ĐỘ CHƠI'),
                    const SizedBox(height: 12),
                    _buildModeSelector(),
                    const SizedBox(height: 28),

                    // Conditional AI settings (Symbol selection)
                    if (_selectedMode == GameMode.vsAI) ...[
                      _buildSectionHeader('CHƠI VỚI QUÂN'),
                      const SizedBox(height: 12),
                      _buildSymbolSelector(),
                      const SizedBox(height: 28),
                      _buildSectionHeader('ĐỘ KHÓ CỦA MÁY'),
                      const SizedBox(height: 12),
                      _buildDifficultySelector(),
                      const SizedBox(height: 28),
                    ],

                    // Board Size selector
                    _buildSectionHeader('KÍCH THƯỚC BÀN CỜ'),
                    const SizedBox(height: 12),
                    _buildSizeSelector(),
                    const SizedBox(height: 40),

                    // Play Button
                    _buildStartButton(context),
                    const SizedBox(height: 16),

                    // Online Play Button
                    if (_isLoggedIn)
                      NeonButton(
                        text: 'CHƠI ONLINE',
                        icon: Icons.language_rounded,
                        glowColor: const Color(0xFFFF007F),
                        gradientColors: const [
                          Color(0xFFFF007F),
                          Color(0xFFAA076B),
                        ],
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LobbyScreen(),
                            ),
                          );
                        },
                        width: double.infinity,
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Glowing Text Title
        Text(
          'CỜ CARO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            shadows: [
              Shadow(
                color: const Color(0xFF00F2FE).withOpacity(0.8),
                blurRadius: 20,
              ),
              Shadow(
                color: const Color(0xFFFF007F).withOpacity(0.6),
                blurRadius: 30,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'THỬ THÁCH CARO CỔ ĐIỂN',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildBadgeCollectionButton(context),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: [
        _buildModeCard(
          mode: GameMode.vsAI,
          title: 'Chơi Với Máy',
          subtitle: 'Thách đấu với Bot AI thông minh',
          icon: Icons.smart_toy_outlined,
          color: const Color(0xFF00F2FE),
        ),
        const SizedBox(height: 12),
        _buildModeCard(
          mode: GameMode.passAndPlay,
          title: 'Hai Người Chơi',
          subtitle: 'Chơi cùng bạn bè trên cùng thiết bị',
          icon: Icons.people_outline,
          color: const Color(0xFFFF007F),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required GameMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : const Color(0xFF0F172A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF1E293B),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 16)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.12)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.white60,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white60 : Colors.white30,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSymbolButton(
            player: Player.X,
            color: const Color(0xFF00F2FE),
            label: 'Quân X (Đi trước)',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSymbolButton(
            player: Player.O,
            color: const Color(0xFFFF007F),
            label: 'Quân O (Máy đi trước)',
          ),
        ),
      ],
    );
  }

  Widget _buildSymbolButton({
    required Player player,
    required Color color,
    required String label,
  }) {
    final isSelected = _userSymbol == player;

    return GestureDetector(
      onTap: () => setState(() => _userSymbol = player),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : const Color(0xFF0F172A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF1E293B),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              player.symbol,
              style: TextStyle(
                color: isSelected ? color : Colors.white24,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                shadows: isSelected
                    ? [Shadow(color: color.withOpacity(0.6), blurRadius: 12)]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    final difficulties = [
      (
        AiDifficulty.easy,
        'Dễ',
        Icons.sentiment_satisfied_alt_rounded,
        const Color(0xFF22C55E),
      ),
      (
        AiDifficulty.medium,
        'Vừa',
        Icons.psychology_alt_rounded,
        const Color(0xFFF59E0B),
      ),
      (
        AiDifficulty.hard,
        'Khó',
        Icons.local_fire_department_rounded,
        const Color(0xFFEF4444),
      ),
    ];

    return Row(
      children: difficulties.map((item) {
        final difficulty = item.$1;
        final label = item.$2;
        final icon = item.$3;
        final color = item.$4;
        final isSelected = _selectedDifficulty == difficulty;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: difficulty == AiDifficulty.hard ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDifficulty = difficulty),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.1)
                      : const Color(0xFF0F172A).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFF1E293B),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? color : Colors.white30,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white38,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeSelector() {
    final sizes = [3, 5, 10, 15, 20];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: sizes.map((size) {
        final isSelected = _selectedSize == size;

        return SizedBox(
          width: 65,
          child: GestureDetector(
            onTap: () => setState(() => _selectedSize = size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00F2FE).withOpacity(0.08)
                    : const Color(0xFF0F172A).withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00F2FE)
                      : const Color(0xFF1E293B),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Text(
                '${size}x$size',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final startColor = _selectedMode == GameMode.vsAI
        ? const Color(0xFF00F2FE)
        : const Color(0xFFFF007F);
    final gradientColors = _selectedMode == GameMode.vsAI
        ? [const Color(0xFF00C6FF), const Color(0xFF0072FF)]
        : [const Color(0xFFFF007F), const Color(0xFFAA076B)];

    return NeonButton(
      text: 'BẮT ĐẦU CHƠI',
      icon: Icons.play_arrow_rounded,
      glowColor: startColor,
      gradientColors: gradientColors,
      onPressed: () {
        // Construct the controller
        final aiPlayer = _userSymbol.opponent;
        final controller = GameController(
          boardSize: _selectedSize,
          gameMode: _selectedMode,
          aiPlayer: aiPlayer,
          aiDifficulty: _selectedDifficulty,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(controller: controller),
          ),
        );
      },
    );
  }

  Widget _buildBadgeCollectionButton(BuildContext context) {
    return ActionChip(
      onPressed: () => _showBadgeCollectionDialog(context),
      backgroundColor: const Color(0xFF0F172A).withOpacity(0.6),
      side: const BorderSide(color: Color(0xFF1E293B), width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      avatar: const Icon(
        Icons.emoji_events_rounded,
        color: Colors.amber,
        size: 16,
      ),
      label: const Text(
        'BỘ SƯU TẬP HUY HIỆU',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _showBadgeCollectionDialog(BuildContext context) {
    final unlocked = GameController.getGlobalUnlockedBadges();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1527),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
        titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        title: Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Huy Hiệu Đã Thu Thập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${unlocked.length}/${allBadges.length}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: allBadges.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isUnlocked = unlocked.contains(badge.id);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? badge.color.withOpacity(0.06)
                      : const Color(0xFF0F172A).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUnlocked
                        ? badge.color.withOpacity(0.3)
                        : const Color(0xFF1E293B),
                    width: isUnlocked ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? badge.color.withOpacity(0.12)
                            : Colors.white.withOpacity(0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUnlocked ? badge.icon : Icons.lock_outline_rounded,
                        color: isUnlocked ? badge.color : Colors.white24,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            badge.title,
                            style: TextStyle(
                              color: isUnlocked ? Colors.white : Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            badge.description,
                            style: TextStyle(
                              color: isUnlocked
                                  ? Colors.white60
                                  : Colors.white12,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 20, right: 24),
        actions: [
          TextButton(
            child: const Text(
              'ĐÓNG',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
