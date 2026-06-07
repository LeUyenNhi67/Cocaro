import 'dart:math';
import '../models/board_position.dart';

enum AiDifficulty { easy, medium, hard }

class HeuristicAI {
  const HeuristicAI();

  /// Finds the best move on the board for the [aiPlayer].
  /// Returns `null` if the board is full.
  BoardPosition? findBestMove(
    List<List<Player?>> board,
    int boardSize,
    Player aiPlayer, {
    AiDifficulty difficulty = AiDifficulty.hard,
  }) {
    final availableMoves = _availableMoves(board, boardSize);
    if (availableMoves.isEmpty) return null;

    switch (difficulty) {
      case AiDifficulty.easy:
        return _findEasyMove(board, boardSize, availableMoves);
      case AiDifficulty.medium:
        return _findMediumMove(board, boardSize, aiPlayer, availableMoves);
      case AiDifficulty.hard:
        return _findHardMove(board, boardSize, aiPlayer, availableMoves);
    }
  }

  BoardPosition? _findHardMove(
    List<List<Player?>> board,
    int boardSize,
    Player aiPlayer,
    List<BoardPosition> availableMoves,
  ) {
    int bestScore = -1;
    List<BoardPosition> bestMoves = [];

    // If board is empty, pick the center
    bool isEmpty = true;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] != null) {
          isEmpty = false;
          break;
        }
      }
      if (!isEmpty) break;
    }

    if (isEmpty) {
      return BoardPosition(boardSize ~/ 2, boardSize ~/ 2);
    }

    for (final move in availableMoves) {
      final score = _evaluateCell(
        move.row,
        move.col,
        board,
        boardSize,
        aiPlayer,
      );
      if (score > bestScore) {
        bestScore = score;
        bestMoves = [move];
      } else if (score == bestScore) {
        bestMoves.add(move);
      }
    }

    if (bestMoves.isEmpty) return null;

    // Pick a random move from the best ones to make the AI less predictable
    final random = Random();
    return bestMoves[random.nextInt(bestMoves.length)];
  }

  BoardPosition? _findMediumMove(
    List<List<Player?>> board,
    int boardSize,
    Player aiPlayer,
    List<BoardPosition> availableMoves,
  ) {
    final random = Random();

    if (_isBoardEmpty(board, boardSize)) {
      return BoardPosition(boardSize ~/ 2, boardSize ~/ 2);
    }

    final winningMove = _findImmediateMove(board, boardSize, aiPlayer);
    if (winningMove != null) return winningMove;

    final blockingMove = _findImmediateMove(
      board,
      boardSize,
      aiPlayer.opponent,
    );
    if (blockingMove != null && random.nextDouble() < 0.7) {
      return blockingMove;
    }

    final scoredMoves =
        availableMoves
            .map(
              (move) => _ScoredMove(
                move,
                _evaluateCell(move.row, move.col, board, boardSize, aiPlayer),
              ),
            )
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    final candidateCount = min(
      max(3, scoredMoves.length ~/ 6),
      scoredMoves.length,
    );
    final candidates = scoredMoves.take(candidateCount).toList();
    return candidates[random.nextInt(candidates.length)].position;
  }

  BoardPosition? _findEasyMove(
    List<List<Player?>> board,
    int boardSize,
    List<BoardPosition> availableMoves,
  ) {
    final random = Random();

    if (_isBoardEmpty(board, boardSize)) {
      final center = boardSize ~/ 2;
      final offsets = [
        const BoardPosition(0, 0),
        const BoardPosition(0, 1),
        const BoardPosition(1, 0),
        const BoardPosition(1, 1),
      ];
      final validCenters = offsets
          .map(
            (offset) => BoardPosition(center + offset.row, center + offset.col),
          )
          .where((move) => _isInside(move.row, move.col, boardSize))
          .toList();
      return validCenters[random.nextInt(validCenters.length)];
    }

    final nearbyMoves = availableMoves
        .where((move) => _hasNeighbor(move.row, move.col, board, boardSize))
        .toList();
    final candidates = nearbyMoves.isEmpty ? availableMoves : nearbyMoves;
    return candidates[random.nextInt(candidates.length)];
  }

  List<BoardPosition> _availableMoves(
    List<List<Player?>> board,
    int boardSize,
  ) {
    final moves = <BoardPosition>[];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] == null) {
          moves.add(BoardPosition(r, c));
        }
      }
    }
    return moves;
  }

  bool _isBoardEmpty(List<List<Player?>> board, int boardSize) {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c] != null) return false;
      }
    }
    return true;
  }

  bool _hasNeighbor(int r, int c, List<List<Player?>> board, int boardSize) {
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (_isInside(nr, nc, boardSize) && board[nr][nc] != null) {
          return true;
        }
      }
    }
    return false;
  }

  BoardPosition? _findImmediateMove(
    List<List<Player?>> board,
    int boardSize,
    Player player,
  ) {
    for (final move in _availableMoves(board, boardSize)) {
      final testBoard = List.generate(
        boardSize,
        (r) => List<Player?>.from(board[r]),
      );
      testBoard[move.row][move.col] = player;
      if (_createsWin(move.row, move.col, testBoard, boardSize, player)) {
        return move;
      }
    }
    return null;
  }

  bool _createsWin(
    int r,
    int c,
    List<List<Player?>> board,
    int boardSize,
    Player player,
  ) {
    final winLength = boardSize == 3 ? 3 : 5;
    final directions = [
      const BoardPosition(0, 1),
      const BoardPosition(1, 0),
      const BoardPosition(1, 1),
      const BoardPosition(1, -1),
    ];

    for (final dir in directions) {
      int count = 1;
      count += _countDirection(
        r,
        c,
        dir.row,
        dir.col,
        board,
        boardSize,
        player,
      );
      count += _countDirection(
        r,
        c,
        -dir.row,
        -dir.col,
        board,
        boardSize,
        player,
      );
      if (count >= winLength) return true;
    }
    return false;
  }

  int _countDirection(
    int r,
    int c,
    int dr,
    int dc,
    List<List<Player?>> board,
    int boardSize,
    Player player,
  ) {
    int count = 0;
    int nr = r + dr;
    int nc = c + dc;

    while (_isInside(nr, nc, boardSize) && board[nr][nc] == player) {
      count++;
      nr += dr;
      nc += dc;
    }

    return count;
  }

  bool _isInside(int r, int c, int boardSize) {
    return r >= 0 && r < boardSize && c >= 0 && c < boardSize;
  }

  int _evaluateCell(
    int r,
    int c,
    List<List<Player?>> board,
    int boardSize,
    Player aiPlayer,
  ) {
    final opponent = aiPlayer.opponent;
    int totalScore = 0;

    final int winLength = boardSize == 3 ? 3 : 5;

    final directions = [
      const BoardPosition(0, 1), // Horizontal
      const BoardPosition(1, 0), // Vertical
      const BoardPosition(1, 1), // Diagonal \
      const BoardPosition(1, -1), // Diagonal /
    ];

    for (final dir in directions) {
      // Check winLength possible windows of size winLength containing (r, c) in this direction
      for (int i = 0; i < winLength; i++) {
        final startR = r - i * dir.row;
        final startC = c - i * dir.col;

        final endR = startR + (winLength - 1) * dir.row;
        final endC = startC + (winLength - 1) * dir.col;

        // Check if the window is within boundaries
        if (startR < 0 ||
            startR >= boardSize ||
            startC < 0 ||
            startC >= boardSize ||
            endR < 0 ||
            endR >= boardSize ||
            endC < 0 ||
            endC >= boardSize) {
          continue;
        }

        int aiCount = 0;
        int opponentCount = 0;

        for (int step = 0; step < winLength; step++) {
          final currR = startR + step * dir.row;
          final currC = startC + step * dir.col;

          if (currR == r && currC == c) continue;

          final val = board[currR][currC];
          if (val == aiPlayer) {
            aiCount++;
          } else if (val == opponent) {
            opponentCount++;
          }
        }

        // Score assignment based on pieces configuration
        if (aiCount > 0 && opponentCount > 0) {
          // Blocked window (contains both X and O), useless for making a line
          continue;
        } else if (aiCount > 0) {
          // AI pieces only (Offensive score)
          if (winLength == 3) {
            switch (aiCount) {
              case 2:
                totalScore += 10000;
                break; // Immediate win opportunity
              case 1:
                totalScore += 100;
                break;
            }
          } else {
            switch (aiCount) {
              case 4:
                totalScore += 100000;
                break; // Immediate win opportunity
              case 3:
                totalScore += 2500;
                break; // Create open 4
              case 2:
                totalScore += 300;
                break;
              case 1:
                totalScore += 20;
                break;
            }
          }
        } else if (opponentCount > 0) {
          // Opponent pieces only (Defensive score)
          if (winLength == 3) {
            switch (opponentCount) {
              case 2:
                totalScore += 3000;
                break; // Immediate blocking required
              case 1:
                totalScore += 50;
                break;
            }
          } else {
            switch (opponentCount) {
              case 4:
                totalScore += 35000;
                break; // Immediate blocking required
              case 3:
                totalScore += 1500;
                break; // Block a growing 3
              case 2:
                totalScore += 150;
                break;
              case 1:
                totalScore += 10;
                break;
            }
          }
        } else {
          // Empty window
          totalScore += 2;
        }
      }
    }

    // Add a small center-proximity bonus to favor playing near the center
    final center = boardSize / 2.0;
    final distanceFromCenter = (r - center).abs() + (c - center).abs();
    final centerBonus = (boardSize - distanceFromCenter) * 0.5;
    totalScore += centerBonus.toInt();

    return totalScore;
  }
}

class _ScoredMove {
  final BoardPosition position;
  final int score;

  const _ScoredMove(this.position, this.score);
}
