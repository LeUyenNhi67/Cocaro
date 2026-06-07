import 'board_position.dart';

enum GameStatus { playing, won, draw }

class GameMove {
  final Player player;
  final BoardPosition position;

  const GameMove(this.player, this.position);
}

class GameState {
  final int boardSize;
  final List<List<Player?>> board;
  final Player currentPlayer;
  final List<GameMove> moveHistory;
  final GameStatus status;
  final Player? winner;
  final List<BoardPosition> winningLine;
  final BoardPosition? hintPosition;

  GameState({
    required this.boardSize,
    required this.board,
    required this.currentPlayer,
    required this.moveHistory,
    required this.status,
    this.winner,
    required this.winningLine,
    this.hintPosition,
  });

  factory GameState.initial(int boardSize) {
    return GameState(
      boardSize: boardSize,
      board: List.generate(boardSize, (_) => List.filled(boardSize, null)),
      currentPlayer: Player.X,
      moveHistory: const [],
      status: GameStatus.playing,
      winner: null,
      winningLine: const [],
      hintPosition: null,
    );
  }

  GameState copyWith({
    int? boardSize,
    List<List<Player?>>? board,
    Player? currentPlayer,
    List<GameMove>? moveHistory,
    GameStatus? status,
    Player? winner,
    bool clearWinner = false,
    List<BoardPosition>? winningLine,
    BoardPosition? hintPosition,
    bool clearHint = false,
  }) {
    return GameState(
      boardSize: boardSize ?? this.boardSize,
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      moveHistory: moveHistory ?? this.moveHistory,
      status: status ?? this.status,
      winner: clearWinner ? null : (winner ?? this.winner),
      winningLine: winningLine ?? this.winningLine,
      hintPosition: clearHint ? null : (hintPosition ?? this.hintPosition),
    );
  }
}
