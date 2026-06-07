import 'package:flutter/material.dart';
import '../../models/board_position.dart';
import '../../models/game_state.dart';

class BoardWidget extends StatefulWidget {
  final GameState state;
  final bool isAiThinking;
  final Function(int row, int col) onCellTapped;
  final double cellSize;

  const BoardWidget({
    Key? key,
    required this.state,
    required this.isAiThinking,
    required this.onCellTapped,
    this.cellSize = 40.0,
  }) : super(key: key);

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double boardLength = widget.state.boardSize * widget.cellSize;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F2FE).withOpacity(0.05),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: const Color(0xFF0D1527),
            width: double.infinity,
            height: double.infinity,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(40),
              child: Center(
                child: SizedBox(
                  width: boardLength,
                  height: boardLength,
                  child: GestureDetector(
                    onTapDown: (details) {
                      if (widget.isAiThinking || widget.state.status != GameStatus.playing) return;
                      final double x = details.localPosition.dx;
                      final double y = details.localPosition.dy;
                      final int col = (x / widget.cellSize).floor();
                      final int row = (y / widget.cellSize).floor();

                      if (row >= 0 && row < widget.state.boardSize &&
                          col >= 0 && col < widget.state.boardSize) {
                        widget.onCellTapped(row, col);
                      }
                    },
                    child: Stack(
                      children: [
                        // 1. Grid Background
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPainter(
                              boardSize: widget.state.boardSize,
                              cellSize: widget.cellSize,
                            ),
                          ),
                        ),
                        
                        // 2. Winning Lines / Highlights
                        if (widget.state.status == GameStatus.won)
                          ...widget.state.winningLine.map((pos) {
                            return Positioned(
                              left: pos.col * widget.cellSize,
                              top: pos.row * widget.cellSize,
                              width: widget.cellSize,
                              height: widget.cellSize,
                              child: const WinningCellHighlight(),
                            );
                          }),

                        // Hint Highlight
                        if (widget.state.hintPosition != null)
                          Positioned(
                            left: widget.state.hintPosition!.col * widget.cellSize,
                            top: widget.state.hintPosition!.row * widget.cellSize,
                            width: widget.cellSize,
                            height: widget.cellSize,
                            child: HintCellHighlight(cellSize: widget.cellSize),
                          ),

                        // 3. Game Pieces (X and O)
                        ..._buildPieces(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPieces() {
    final pieces = <Widget>[];
    for (int r = 0; r < widget.state.boardSize; r++) {
      for (int c = 0; c < widget.state.boardSize; c++) {
        final player = widget.state.board[r][c];
        if (player != null) {
          final isWinning = widget.state.status == GameStatus.won &&
              widget.state.winningLine.contains(BoardPosition(r, c));
          
          pieces.add(
            Positioned(
              key: ValueKey('piece_${r}_${c}_$player'),
              left: c * widget.cellSize,
              top: r * widget.cellSize,
              width: widget.cellSize,
              height: widget.cellSize,
              child: AnimatedPiece(
                player: player,
                cellSize: widget.cellSize,
                isWinning: isWinning,
              ),
            ),
          );
        }
      }
    }
    return pieces;
  }
}

class GridPainter extends CustomPainter {
  final int boardSize;
  final double cellSize;

  GridPainter({required this.boardSize, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    final borderPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double maxCoord = boardSize * cellSize;

    // Draw internal grid lines
    for (int i = 1; i < boardSize; i++) {
      final double offset = i * cellSize;
      // Vertical line
      canvas.drawLine(Offset(offset, 0), Offset(offset, maxCoord), gridPaint);
      // Horizontal line
      canvas.drawLine(Offset(0, offset), Offset(maxCoord, offset), gridPaint);
    }

    // Outer border
    canvas.drawRect(Rect.fromLTWH(0, 0, maxCoord, maxCoord), borderPaint);
    
    // Draw star points (standard Gomoku/Caro board markings for larger boards)
    if (boardSize == 15) {
      final starPoints = [
        const BoardPosition(3, 3), const BoardPosition(3, 11),
        const BoardPosition(7, 7),
        const BoardPosition(11, 3), const BoardPosition(11, 11)
      ];
      final starPaint = Paint()
        ..color = const Color(0xFF475569)
        ..style = PaintingStyle.fill;
        
      for (final pt in starPoints) {
        canvas.drawCircle(
          Offset((pt.col + 0.5) * cellSize, (pt.row + 0.5) * cellSize),
          3.5,
          starPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.boardSize != boardSize || oldDelegate.cellSize != cellSize;
  }
}

class WinningCellHighlight extends StatefulWidget {
  const WinningCellHighlight({Key? key}) : super(key: key);

  @override
  State<WinningCellHighlight> createState() => _WinningCellHighlightState();
}

class _WinningCellHighlightState extends State<WinningCellHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.1 + _controller.value * 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.greenAccent.withOpacity(0.3 + _controller.value * 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.2 * _controller.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class HintCellHighlight extends StatefulWidget {
  final double cellSize;
  const HintCellHighlight({super.key, required this.cellSize});

  @override
  State<HintCellHighlight> createState() => _HintCellHighlightState();
}

class _HintCellHighlightState extends State<HintCellHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.05 + _controller.value * 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amberAccent.withOpacity(0.4 + _controller.value * 0.5),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.25 * _controller.value),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.amberAccent.withOpacity(0.3 + _controller.value * 0.7),
              size: widget.cellSize * 0.45,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedPiece extends StatefulWidget {
  final Player player;
  final double cellSize;
  final bool isWinning;

  const AnimatedPiece({
    Key? key,
    required this.player,
    required this.cellSize,
    required this.isWinning,
  }) : super(key: key);

  @override
  State<AnimatedPiece> createState() => _AnimatedPieceState();
}

class _AnimatedPieceState extends State<AnimatedPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
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
    final isX = widget.player == Player.X;
    final primaryColor = isX ? const Color(0xFF00F2FE) : const Color(0xFFFF007F);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: PiecePainter(
            player: widget.player,
            color: primaryColor,
            progress: _animation.value,
            isWinning: widget.isWinning,
          ),
        );
      },
    );
  }
}

class PiecePainter extends CustomPainter {
  final Player player;
  final Color color;
  final double progress;
  final bool isWinning;

  PiecePainter({
    required this.player,
    required this.color,
    required this.progress,
    required this.isWinning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double pad = size.width * 0.22;
    final double w = size.width;
    final double h = size.height;

    // Glowing base line paint
    final glowPaint = Paint()
      ..color = color.withOpacity(isWinning ? 0.8 : 0.4)
      ..strokeWidth = isWinning ? 7.0 : 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Sharp foreground line paint
    final sharpPaint = Paint()
      ..color = isWinning ? Colors.white : color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (player == Player.X) {
      // Draw first diagonal line: top-left to bottom-right
      if (progress < 0.5) {
        final double p1 = progress / 0.5;
        final double startX = pad;
        final double startY = pad;
        final double endX = pad + (w - 2 * pad) * p1;
        final double endY = pad + (h - 2 * pad) * p1;
        
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), glowPaint);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), sharpPaint);
      } else {
        // Complete first diagonal line
        canvas.drawLine(
          Offset(pad, pad),
          Offset(w - pad, h - pad),
          glowPaint,
        );
        canvas.drawLine(
          Offset(pad, pad),
          Offset(w - pad, h - pad),
          sharpPaint,
        );

        // Draw second diagonal line: top-right to bottom-left
        final double p2 = (progress - 0.5) / 0.5;
        final double startX = w - pad;
        final double startY = pad;
        final double endX = w - pad - (w - 2 * pad) * p2;
        final double endY = pad + (h - 2 * pad) * p2;

        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), glowPaint);
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), sharpPaint);
      }
    } else {
      // Draw O (Circle)
      final double radius = (w / 2) - pad;
      final center = Offset(w / 2, h / 2);
      final double sweepAngle = 2 * 3.14159265 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159265 / 2, // Start from the top
        sweepAngle,
        false,
        glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159265 / 2,
        sweepAngle,
        false,
        sharpPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PiecePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isWinning != isWinning ||
        oldDelegate.color != color;
  }
}
