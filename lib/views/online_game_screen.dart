import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/online_game_controller.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';
import '../views/widgets/board_widget.dart';
import 'widgets/neon_button.dart';

class OnlineGameScreen extends StatelessWidget {
  final OnlineGameController controller;

  const OnlineGameScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final state = controller.state;
        final bool isWon = state.status == GameStatus.won;
        final bool isDraw = state.status == GameStatus.draw;
        final bool isGameOver = isWon || isDraw;

        final myColor = controller.mySymbol == Player.X
            ? const Color(0xFF00F2FE)
            : const Color(0xFFFF007F);
        final opponentColor = controller.mySymbol == Player.X
            ? const Color(0xFFFF007F)
            : const Color(0xFF00F2FE);

        return Scaffold(
          backgroundColor: const Color(0xFF070B19),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 48,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 18),
              onPressed: () async {
                final confirmed = await _confirmForfeit(context);
                if (confirmed && context.mounted) {
                  controller.forfeit();
                  Navigator.of(context).pop();
                }
              },
            ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: controller.isOpponentConnected
                  ? Text(
                      'Đang chơi với ${controller.opponentNickname}',
                      key: const ValueKey('playing'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    )
                  : Row(
                      key: const ValueKey('waiting'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Chờ đối thủ kết nối...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // Ambient glows
              Positioned(
                top: -80,
                left: -80,
                child: _ambientOrb(myColor, 200),
              ),
              Positioned(
                bottom: -60,
                right: -60,
                child: _ambientOrb(opponentColor, 200),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.transparent),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Turn + Symbol indicator
                    _buildStatusBar(state, myColor, opponentColor),
                    const SizedBox(height: 8),

                    // Board
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: BoardWidget(
                          state: state,
                          isAiThinking: false,
                          onCellTapped: (row, col) {
                            controller.makeLocalMove(row, col);
                          },
                        ),
                      ),
                    ),

                    // Game Over Section
                    if (isGameOver)
                      _buildGameOverPanel(context, state, isWon, myColor),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ambientOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatusBar(GameState state, Color myColor, Color opponentColor) {
    final isMyTurn = controller.isMyTurn;
    final mySymbolStr = controller.mySymbol.symbol;
    final opponentSymbolStr = controller.mySymbol.opponent.symbol;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // My chip
          _buildPlayerChip(
            symbol: mySymbolStr,
            label: 'Bạn',
            isActive: isMyTurn && state.status == GameStatus.playing,
            color: myColor,
          ),
          const SizedBox(width: 8),
          // VS divider
          Expanded(
            child: Center(
              child: Text(
                state.status == GameStatus.playing
                    ? (isMyTurn ? 'LƯỢT CỦA BẠN' : 'LƯỢT ĐỐI THỦ')
                    : '',
                style: TextStyle(
                  color: isMyTurn ? myColor : opponentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      color: (isMyTurn ? myColor : opponentColor)
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Opponent chip
          _buildPlayerChip(
            symbol: opponentSymbolStr,
            label: controller.opponentNickname,
            isActive: !isMyTurn && state.status == GameStatus.playing,
            color: opponentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerChip({
    required String symbol,
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.12)
            : const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : const Color(0xFF334155),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: TextStyle(
              color: isActive ? color : Colors.white30,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              shadows: isActive
                  ? [Shadow(color: color.withValues(alpha: 0.7), blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white70 : Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverPanel(
      BuildContext context, GameState state, bool isWon, Color myColor) {
    final didWin = isWon && state.winner == controller.mySymbol;
    final resultColor =
        didWin ? const Color(0xFF00F2FE) : const Color(0xFFFF007F);
    final resultText = didWin ? 'BẠN CHIẾN THẮNG! 🏆' : 'BẠN THẤT BẠI! ❌';
    final diamonds = controller.earnedDiamonds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: resultColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: resultColor.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              resultText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                      color: resultColor.withValues(alpha: 0.8), blurRadius: 16),
                ],
              ),
            ),
            if (diamonds > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond_rounded,
                      color: Color(0xFF00F2FE), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+$diamonds kim cương!',
                    style: const TextStyle(
                      color: Color(0xFF00F2FE),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            NeonButton(
              text: 'QUAY LẠI PHÒNG CHỜ',
              icon: Icons.exit_to_app_rounded,
              glowColor: resultColor,
              gradientColors: didWin
                  ? const [Color(0xFF00F2FE), Color(0xFF0072FF)]
                  : const [Color(0xFFFF007F), Color(0xFFAA076B)],
              onPressed: () => Navigator.of(context).pop(),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmForfeit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        title: const Text('Bỏ cuộc?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Nếu bạn rời phòng bây giờ, đối thủ sẽ được coi là thắng. Bạn có chắc không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ở lại', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF007F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Bỏ cuộc',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
