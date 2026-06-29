import 'package:flutter/foundation.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';
import '../models/badge_model.dart';
import '../services/rank_service.dart';
import '../utils/sound_manager.dart';
import 'ai_controller.dart';

enum GameMode { passAndPlay, vsAI }

class GameController extends ChangeNotifier {
  late GameState _state;
  GameMode _gameMode;
  Player _aiPlayer;
  AiDifficulty _aiDifficulty;
  bool _isAiThinking = false;
  final HeuristicAI _ai = const HeuristicAI();

  int _xScore = 0;
  int _oScore = 0;
  int _drawScore = 0;

  // Global static badges list to persist across landing transitions
  static final Set<String> _globalUnlockedBadges = {};
  BadgeModel? _lastUnlockedBadge;

  GameController({
    int boardSize = 15,
    GameMode gameMode = GameMode.vsAI,
    Player aiPlayer = Player.O,
    AiDifficulty aiDifficulty = AiDifficulty.hard,
  }) : _gameMode = gameMode,
       _aiPlayer = aiPlayer,
       _aiDifficulty = aiDifficulty {
    _state = GameState.initial(boardSize);
  }

  GameState get state => _state;
  GameMode get gameMode => _gameMode;
  Player get aiPlayer => _aiPlayer;
  AiDifficulty get aiDifficulty => _aiDifficulty;
  String get aiDifficultyLabel {
    switch (_aiDifficulty) {
      case AiDifficulty.easy:
        return 'Dễ';
      case AiDifficulty.medium:
        return 'Vừa';
      case AiDifficulty.hard:
        return 'Khó';
    }
  }

  bool get isAiThinking => _isAiThinking;
  int get xScore => _xScore;
  int get oScore => _oScore;
  int get drawScore => _drawScore;
  Set<String> get unlockedBadges => _globalUnlockedBadges;
  BadgeModel? get lastUnlockedBadge => _lastUnlockedBadge;

  static Set<String> getGlobalUnlockedBadges() => _globalUnlockedBadges;

  void clearLastUnlockedBadge() {
    _lastUnlockedBadge = null;
    notifyListeners();
  }

  void resetScores() {
    _xScore = 0;
    _oScore = 0;
    _drawScore = 0;
    notifyListeners();
  }

  void setGameMode(GameMode mode) {
    if (_gameMode != mode) {
      _gameMode = mode;
      resetScores();
      reset();
    }
  }

  void setAiPlayer(Player player) {
    if (_aiPlayer != player) {
      _aiPlayer = player;
      reset();
    }
  }

  void setAiDifficulty(AiDifficulty difficulty) {
    if (_aiDifficulty != difficulty) {
      _aiDifficulty = difficulty;
      reset();
    }
  }

  void setBoardSize(int size) {
    if (_state.boardSize != size) {
      _state = GameState.initial(size);
      notifyListeners();

      // If AI goes first
      if (_gameMode == GameMode.vsAI && _state.currentPlayer == _aiPlayer) {
        _triggerAiMove();
      }
    }
  }

  void reset() {
    _state = GameState.initial(_state.boardSize);
    _isAiThinking = false;
    notifyListeners();

    // If AI goes first
    if (_gameMode == GameMode.vsAI && _state.currentPlayer == _aiPlayer) {
      _triggerAiMove();
    }
  }

  bool makeMove(int row, int col) {
    if (_state.status != GameStatus.playing || _isAiThinking) return false;
    if (row < 0 ||
        row >= _state.boardSize ||
        col < 0 ||
        col >= _state.boardSize)
      return false;
    if (_state.board[row][col] != null) return false;

    // Create a new board copy
    final newBoard = List.generate(
      _state.boardSize,
      (r) => List<Player?>.from(_state.board[r]),
    );
    newBoard[row][col] = _state.currentPlayer;

    final move = GameMove(_state.currentPlayer, BoardPosition(row, col));
    final newHistory = List<GameMove>.from(_state.moveHistory)..add(move);

    // Check for win
    final winningLine = _checkWin(row, col, _state.currentPlayer, newBoard);

    GameState newState;
    if (winningLine != null) {
      newState = _state.copyWith(
        board: newBoard,
        moveHistory: newHistory,
        status: GameStatus.won,
        winner: _state.currentPlayer,
        winningLine: winningLine,
        clearHint: true,
      );

      // Update scoreboard
      if (_state.currentPlayer == Player.X) {
        _xScore++;
      } else {
        _oScore++;
      }

      // Check for badge achievements
      _checkForNewBadges(_state.currentPlayer, false, _state.boardSize);

      // Record rank match result
      final String resultStr =
          (_gameMode == GameMode.vsAI && _state.currentPlayer == _aiPlayer)
              ? 'LOSS'
              : 'WIN';
      RankService.addMatchResult(
        mode: _gameMode == GameMode.vsAI ? 'Đấu với Máy' : '2 Người chơi',
        result: resultStr,
        isHardAi: _gameMode == GameMode.vsAI && _aiDifficulty == AiDifficulty.hard,
      );

      // Play synthesized audio
      if (_gameMode == GameMode.vsAI && _state.currentPlayer == _aiPlayer) {
        SoundManager.playLose();
      } else {
        SoundManager.playWin();
      }
    } else if (_checkDraw(newBoard)) {
      newState = _state.copyWith(
        board: newBoard,
        moveHistory: newHistory,
        status: GameStatus.draw,
        clearHint: true,
      );

      // Update scoreboard
      _drawScore++;

      // Check for badge achievements
      _checkForNewBadges(null, true, _state.boardSize);

      // Record rank match result
      RankService.addMatchResult(
        mode: _gameMode == GameMode.vsAI ? 'Đấu với Máy' : '2 Người chơi',
        result: 'DRAW',
        isHardAi: _gameMode == GameMode.vsAI && _aiDifficulty == AiDifficulty.hard,
      );

      // Play synthesized audio
      SoundManager.playDraw();
    } else {
      newState = _state.copyWith(
        board: newBoard,
        moveHistory: newHistory,
        currentPlayer: _state.currentPlayer.opponent,
        clearHint: true,
      );
    }

    _state = newState;
    notifyListeners();

    // If it's AI mode, check if we need to trigger AI
    if (_state.status == GameStatus.playing &&
        _gameMode == GameMode.vsAI &&
        _state.currentPlayer == _aiPlayer) {
      _triggerAiMove();
    }

    return true;
  }

  void undo() {
    if (_state.moveHistory.isEmpty || _isAiThinking) return;

    final countToUndo =
        (_gameMode == GameMode.vsAI && _state.moveHistory.length >= 2) ? 2 : 1;

    // Perform undo
    var newHistory = List<GameMove>.from(_state.moveHistory);
    final newBoard = List.generate(
      _state.boardSize,
      (r) => List<Player?>.from(_state.board[r]),
    );

    for (int i = 0; i < countToUndo; i++) {
      if (newHistory.isEmpty) break;
      final lastMove = newHistory.removeLast();
      newBoard[lastMove.position.row][lastMove.position.col] = null;
    }

    final nextPlayer = newHistory.isEmpty
        ? Player.X
        : newHistory.last.player.opponent;

    _state = GameState(
      boardSize: _state.boardSize,
      board: newBoard,
      currentPlayer: nextPlayer,
      moveHistory: newHistory,
      status: GameStatus.playing,
      winner: null,
      winningLine: const [],
      hintPosition: null,
    );

    notifyListeners();
  }

  void showHint() {
    if (_state.status != GameStatus.playing || _isAiThinking) return;

    final hint = _ai.findBestMove(
      _state.board,
      _state.boardSize,
      _state.currentPlayer,
    );
    if (hint != null) {
      _state = _state.copyWith(hintPosition: hint);
      notifyListeners();
    }
  }

  Future<void> _triggerAiMove() async {
    _isAiThinking = true;
    notifyListeners();

    // Small delay to make the AI feel natural and prevent UI lockups
    await Future.delayed(const Duration(milliseconds: 500));

    if (_state.status != GameStatus.playing ||
        _gameMode != GameMode.vsAI ||
        _state.currentPlayer != _aiPlayer) {
      _isAiThinking = false;
      notifyListeners();
      return;
    }

    final aiMove = _ai.findBestMove(
      _state.board,
      _state.boardSize,
      _aiPlayer,
      difficulty: _aiDifficulty,
    );
    _isAiThinking = false;

    if (aiMove != null) {
      makeMove(aiMove.row, aiMove.col);
    }
  }

  List<BoardPosition>? _checkWin(
    int r,
    int c,
    Player player,
    List<List<Player?>> board,
  ) {
    final directions = [
      [const BoardPosition(0, 1), const BoardPosition(0, -1)], // Horizontal
      [const BoardPosition(1, 0), const BoardPosition(-1, 0)], // Vertical
      [const BoardPosition(1, 1), const BoardPosition(-1, -1)], // Diagonal \
      [const BoardPosition(1, -1), const BoardPosition(-1, 1)], // Diagonal /
    ];

    for (final dirPair in directions) {
      final winningPositions = <BoardPosition>[BoardPosition(r, c)];

      for (final dir in dirPair) {
        int step = 1;
        while (true) {
          final nr = r + dir.row * step;
          final nc = c + dir.col * step;
          if (nr < 0 ||
              nr >= _state.boardSize ||
              nc < 0 ||
              nc >= _state.boardSize)
            break;
          if (board[nr][nc] == player) {
            winningPositions.add(BoardPosition(nr, nc));
            step++;
          } else {
            break;
          }
        }
      }

      final int winLength = _state.boardSize == 3 ? 3 : 5;
      if (winningPositions.length >= winLength) {
        winningPositions.sort((a, b) {
          if (a.row != b.row) return a.row.compareTo(b.row);
          return a.col.compareTo(b.col);
        });
        return winningPositions;
      }
    }
    return null;
  }

  bool _checkDraw(List<List<Player?>> board) {
    for (int r = 0; r < _state.boardSize; r++) {
      for (int c = 0; c < _state.boardSize; c++) {
        if (board[r][c] == null) return false;
      }
    }
    return true;
  }

  void _checkForNewBadges(Player? winner, bool isDraw, int boardSize) {
    _lastUnlockedBadge = null;
    final List<String> newlyUnlocked = [];

    if (winner != null) {
      // 1. First Win
      if (!_globalUnlockedBadges.contains('first_win')) {
        newlyUnlocked.add('first_win');
      }

      // 2. Win on 3x3
      if (boardSize == 3 && !_globalUnlockedBadges.contains('win_3x3')) {
        newlyUnlocked.add('win_3x3');
      }

      // 3. Win on 20x20
      if (boardSize == 20 && !_globalUnlockedBadges.contains('win_20x20')) {
        newlyUnlocked.add('win_20x20');
      }

      // 4. Beat AI
      if (_gameMode == GameMode.vsAI &&
          winner != _aiPlayer &&
          !_globalUnlockedBadges.contains('beat_ai')) {
        newlyUnlocked.add('beat_ai');
      }

      // 5. Grandmaster (5 wins)
      final int wins = winner == Player.X ? _xScore : _oScore;
      if (wins >= 5 && !_globalUnlockedBadges.contains('grandmaster')) {
        newlyUnlocked.add('grandmaster');
      }
    }

    if (isDraw) {
      // 6. Draw Game
      if (!_globalUnlockedBadges.contains('draw_game')) {
        newlyUnlocked.add('draw_game');
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _globalUnlockedBadges.addAll(newlyUnlocked);
      final lastId = newlyUnlocked.last;
      _lastUnlockedBadge = allBadges.firstWhere((b) => b.id == lastId);
    }
  }
}
