import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/game_controller.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';
import '../models/badge_model.dart';
import '../utils/sound_manager.dart';
import 'login_screen.dart';
import 'widgets/board_widget.dart';
import 'widgets/neon_button.dart';

class GameScreen extends StatelessWidget {
  final GameController controller;

  const GameScreen({Key? key, required this.controller}) : super(key: key);

  // Lấy thông tin user trực tiếp từ Supabase session (không cần truyền tham số)
  String? get _currentUserEmail =>
      Supabase.instance.client.auth.currentUser?.email;

  bool get _isLoggedIn =>
      Supabase.instance.client.auth.currentUser != null;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final state = controller.state;
        final bool isWon = state.status == GameStatus.won;
        final bool isDraw = state.status == GameStatus.draw;

        return Scaffold(
          backgroundColor: const Color(0xFF070B19),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 44,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _screenTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
            centerTitle: true,
            actions: [
              if (_isLoggedIn)
                IconButton(
                  tooltip: 'Đăng xuất',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => _signOut(context),
                ),
              IconButton(
                tooltip: 'Đặt lại điểm số',
                icon: const Icon(
                  Icons.score_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => _confirmResetScores(context),
              ),
              IconButton(
                tooltip: 'Chơi lại ván này',
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => _confirmReset(context),
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 4),
                    // 1. Turn Indicator + Scoreboard (compact single row)
                    _buildCompactStatusBar(state),

                    // 2. AI Thinking Indicator
                    _buildAiThinkingIndicator(),

                    // 3. Interactive Game Board
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: BoardWidget(
                          state: state,
                          isAiThinking: controller.isAiThinking,
                          onCellTapped: (row, col) {
                            final didMove = controller.makeMove(row, col);
                            if (didMove) {
                              SoundManager.playMove();
                            }
                          },
                        ),
                      ),
                    ),

                    // 4. Quick Actions Footer
                    _buildFooter(context, state),
                    const SizedBox(height: 8),
                  ],
                ),

                if (_isLoggedIn) _buildUserEmailBadge(),
                // 5. Game Over Modal Overlay
                if (isWon || isDraw) _buildGameOverOverlay(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dang xuat that bai. Vui long thu lai.')),
      );
    }
  }

  String _screenTitle() {
    if (controller.gameMode == GameMode.vsAI) {
      return 'Chơi Với Máy - ${controller.aiDifficultyLabel}';
    }
    return 'Hai Người Chơi';
  }

  Widget _buildUserEmailBadge() {
    return Positioned(
      top: 6,
      right: 10,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF00F2FE),
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _currentUserEmail ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact single-row status bar combining turn indicator + scoreboard
  Widget _buildCompactStatusBar(GameState state) {
    final bool isXTurn =
        state.currentPlayer == Player.X && state.status == GameStatus.playing;
    final Color xColor = const Color(0xFF00F2FE);
    final Color oColor = const Color(0xFFFF007F);
    final String oLabel = controller.gameMode == GameMode.vsAI ? 'Máy' : 'O';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          // Player X indicator
          _buildCompactPlayerChip(
            symbol: 'X',
            label: 'X',
            isActive: isXTurn,
            color: xColor,
          ),
          const SizedBox(width: 6),
          // Score section
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactScore(controller.xScore, xColor),
                  Text(
                    '-',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                  _buildCompactScore(controller.drawScore, Colors.amber),
                  Text(
                    '-',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                  _buildCompactScore(controller.oScore, oColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Player O indicator
          _buildCompactPlayerChip(
            symbol: oLabel,
            label: 'O',
            isActive: !isXTurn && state.status == GameStatus.playing,
            color: oColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPlayerChip({
    required String symbol,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.12)
            : const Color(0xFF1E293B).withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? color : const Color(0xFF334155),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: -1,
                ),
              ]
            : null,
      ),
      child: Text(
        symbol,
        style: TextStyle(
          color: isActive ? color : Colors.white30,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          shadows: isActive
              ? [Shadow(color: color.withOpacity(0.7), blurRadius: 6)]
              : null,
        ),
      ),
    );
  }

  Widget _buildCompactScore(int score, Color color) {
    return Text(
      score.toString(),
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 6)],
      ),
    );
  }

  Widget _buildAiThinkingIndicator() {
    return AnimatedOpacity(
      opacity: controller.isAiThinking ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFFFF007F),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Máy đang tính toán...',
              style: TextStyle(
                color: Color(0xFFFF007F),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, GameState state) {
    final bool canUndo =
        state.moveHistory.isNotEmpty && !controller.isAiThinking;
    final bool canHint =
        state.status == GameStatus.playing && !controller.isAiThinking;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Undo Button
          Expanded(
            child: _buildSmallButton(
              text: 'Đi lại',
              icon: Icons.undo,
              glowColor: const Color(0xFF00F2FE),
              gradientColors: const [Color(0xFF00E5FF), Color(0xFF0083B0)],
              onPressed: canUndo ? () => controller.undo() : null,
            ),
          ),
          const SizedBox(width: 8),
          // Hint Button
          Expanded(
            child: _buildSmallButton(
              text: 'Gợi ý',
              icon: Icons.lightbulb_outline_rounded,
              glowColor: Colors.amber,
              gradientColors: const [Color(0xFFF9D423), Color(0xFFFF4E50)],
              onPressed: canHint ? () => controller.showHint() : null,
            ),
          ),
          const SizedBox(width: 8),
          // Restart Button
          Expanded(
            child: _buildSmallButton(
              text: 'Chơi lại',
              icon: Icons.restart_alt,
              glowColor: const Color(0xFFFF007F),
              gradientColors: const [Color(0xFFFF007F), Color(0xFFAA076B)],
              onPressed: () => _confirmReset(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton({
    required String text,
    required IconData icon,
    required Color glowColor,
    required List<Color> gradientColors,
    required VoidCallback? onPressed,
  }) {
    final bool isEnabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEnabled
                    ? gradientColors
                    : [Colors.grey.shade800, Colors.grey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isEnabled ? Colors.white : Colors.grey.shade500,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    text,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, GameState state) {
    return GameOverOverlay(
      state: state,
      gameMode: controller.gameMode,
      aiPlayer: controller.aiPlayer,
      lastUnlockedBadge: controller.lastUnlockedBadge,
      onPlayAgain: () {
        controller.clearLastUnlockedBadge();
        controller.reset();
      },
    );
  }

  void _confirmReset(BuildContext context) {
    if (controller.state.moveHistory.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        title: const Text(
          'Chơi lại ván mới?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa sạch bàn cờ và bắt đầu ván mới không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF007F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Chơi lại',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              controller.reset();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Kept for backward compat - no longer used in layout (replaced by _buildCompactStatusBar)
  Widget _buildScoreboardPanel() => const SizedBox.shrink();

  Widget _buildScoreItem(String label, int score, Color color) =>
      const SizedBox.shrink();

  void _confirmResetScores(BuildContext context) {
    if (controller.xScore == 0 &&
        controller.oScore == 0 &&
        controller.drawScore == 0)
      return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        title: const Text(
          'Đặt lại bảng điểm?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đặt lại điểm số của các người chơi về 0?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF007F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Đặt lại',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              controller.resetScores();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ANIMATED GAME OVER OVERLAY WIDGET
// ==========================================
class GameOverOverlay extends StatefulWidget {
  final GameState state;
  final GameMode gameMode;
  final Player aiPlayer;
  final BadgeModel? lastUnlockedBadge;
  final VoidCallback onPlayAgain;

  const GameOverOverlay({
    super.key,
    required this.state,
    required this.gameMode,
    required this.aiPlayer,
    this.lastUnlockedBadge,
    required this.onPlayAgain,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWon = widget.state.status == GameStatus.won;
    final winnerSymbol = widget.state.winner?.symbol ?? '';
    final winnerColor = widget.state.winner == Player.X
        ? const Color(0xFF00F2FE)
        : const Color(0xFFFF007F);
    final bool didLoseToAi =
        isWon &&
        widget.gameMode == GameMode.vsAI &&
        widget.state.winner == widget.aiPlayer;
    final bool shouldCelebrate = isWon && !didLoseToAi;

    String titleText = "HÒA CỜ";
    String subtitleText = "Bàn cờ đã đầy quân, hai bên bất phân thắng bại!";
    Color titleGlowColor = Colors.amber;
    IconData iconData = Icons.balance;

    if (isWon) {
      if (widget.gameMode == GameMode.vsAI) {
        if (widget.state.winner == widget.aiPlayer) {
          titleText = "THẤT BẠI";
          subtitleText =
              "Máy đã thông minh hơn ở ván này. Hãy cố gắng lên nhé!";
          titleGlowColor = const Color(0xFFFF007F);
          iconData = Icons.sentiment_very_dissatisfied_rounded;
        } else {
          titleText = "CHIẾN THẮNG";
          subtitleText = "Tuyệt vời! Bạn đã xuất sắc đánh bại Máy AI!";
          titleGlowColor = const Color(0xFF00F2FE);
          iconData = Icons.emoji_events_rounded;
        }
      } else {
        titleText = "QUÂN $winnerSymbol CHIẾN THẮNG";
        subtitleText = "Chúc mừng bạn đã giành chiến thắng thuyết phục!";
        titleGlowColor = winnerColor;
        iconData = Icons.workspace_premium_rounded;
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            color: Colors.black.withOpacity(0.85),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: shouldCelebrate
                        ? FireworksEffect(animation: _controller)
                        : didLoseToAi
                        ? SadDefeatEffect(animation: _controller)
                        : const SizedBox.shrink(),
                  ),
                ),
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: titleGlowColor.withOpacity(0.3),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: titleGlowColor.withOpacity(0.15),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated glowing header icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: titleGlowColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              color: titleGlowColor,
                              size: 64,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bouncy big glowing victory title
                          Text(
                            titleText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: titleGlowColor.withOpacity(0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Explanatory subtitle
                          Text(
                            subtitleText,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // Newly unlocked badge details
                          if (widget.lastUnlockedBadge != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.lastUnlockedBadge!.color
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.lastUnlockedBadge!.color
                                      .withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.lastUnlockedBadge!.color
                                        .withOpacity(0.08),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: widget.lastUnlockedBadge!.color
                                          .withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      widget.lastUnlockedBadge!.icon,
                                      color: widget.lastUnlockedBadge!.color,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'MỞ KHÓA HUY HIỆU MỚI!',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.lastUnlockedBadge!.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.lastUnlockedBadge!.description,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 36),

                          // Bouncy play again button
                          NeonButton(
                            text: 'CHƠI TIẾP VÁN MỚI',
                            icon: Icons.play_arrow_rounded,
                            glowColor: titleGlowColor,
                            gradientColors: isWon
                                ? (widget.state.winner == Player.X
                                      ? [
                                          const Color(0xFF00C6FF),
                                          const Color(0xFF0072FF),
                                        ]
                                      : [
                                          const Color(0xFFFF007F),
                                          const Color(0xFFAA076B),
                                        ])
                                : [
                                    const Color(0xFFF9D423),
                                    const Color(0xFFFF4E50),
                                  ],
                            onPressed: widget.onPlayAgain,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FireworksEffect extends StatelessWidget {
  final Animation<double> animation;

  const FireworksEffect({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: FireworksPainter(progress: animation.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class FireworksPainter extends CustomPainter {
  final double progress;

  const FireworksPainter({required this.progress});

  static const _bursts = [
    _BurstSeed(0.18, 0.22, Color(0xFF00F2FE), 0.00),
    _BurstSeed(0.78, 0.20, Color(0xFFFFD166), 0.12),
    _BurstSeed(0.50, 0.15, Color(0xFFFF007F), 0.22),
    _BurstSeed(0.28, 0.70, Color(0xFF22C55E), 0.34),
    _BurstSeed(0.72, 0.66, Color(0xFF8B5CF6), 0.46),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final burst in _bursts) {
      final localProgress = ((progress - burst.delay) / 0.54).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      final center = Offset(size.width * burst.x, size.height * burst.y);
      final radius = size.shortestSide * (0.07 + localProgress * 0.17);
      final opacity = math.sin(localProgress * math.pi).clamp(0.0, 1.0);

      for (var i = 0; i < 18; i++) {
        final angle = (math.pi * 2 / 18) * i;
        final start =
            center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.35;
        final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        final paint = Paint()
          ..color = burst.color.withOpacity(0.85 * opacity)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(start, end, paint);
      }

      canvas.drawCircle(
        center,
        4 + 6 * localProgress,
        Paint()..color = Colors.white.withOpacity(0.65 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FireworksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SadDefeatEffect extends StatelessWidget {
  final Animation<double> animation;

  const SadDefeatEffect({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: SadDefeatPainter(progress: animation.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class SadDefeatPainter extends CustomPainter {
  final double progress;

  const SadDefeatPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.32)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 38; i++) {
      final x = ((i * 47) % 100) / 100 * size.width;
      final speed = 0.45 + (i % 5) * 0.09;
      final y = ((progress * speed + i * 0.071) % 1.0) * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 12, y + 28), rainPaint);
    }

    final pulse = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final cloudPaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.18 + pulse * 0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.25),
        width: size.width * 0.55,
        height: 80,
      ),
      cloudPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SadDefeatPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BurstSeed {
  final double x;
  final double y;
  final Color color;
  final double delay;

  const _BurstSeed(this.x, this.y, this.color, this.delay);
}
