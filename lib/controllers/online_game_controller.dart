import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';
import '../services/online_service.dart';
import '../services/rank_service.dart';

class OnlineGameController extends ChangeNotifier {
  final String roomId;
  final String myUserId;
  final bool isHost;
  final Player mySymbol;

  late GameState _state;
  late RealtimeChannel _channel;
  bool _isOpponentConnected = false;
  String? _opponentNickname;
  int _earnedDiamonds = 0;

  OnlineGameController({
    required this.roomId,
    required this.myUserId,
    required this.isHost,
    required int boardSize,
    required String hostSymbolStr,
  }) : mySymbol = isHost
            ? (hostSymbolStr == 'X' ? Player.X : Player.O)
            : (hostSymbolStr == 'X' ? Player.O : Player.X) {
    _state = GameState.initial(boardSize);
    _initRealtime();
  }

  GameState get state => _state;
  bool get isMyTurn =>
      _state.status == GameStatus.playing &&
      _state.currentPlayer == mySymbol;
  bool get isOpponentConnected => _isOpponentConnected;
  String get opponentNickname => _opponentNickname ?? 'Đối thủ';
  int get earnedDiamonds => _earnedDiamonds;

  void _initRealtime() {
    _channel = OnlineService.subscribeToRoom(
      roomId,
      onMove: (payload) {
        final row = payload['row'] as int;
        final col = payload['col'] as int;
        _handleOpponentMove(row, col);
      },
      onGameEnd: (payload) {
        final winnerId = payload['winner_id'] as String?;
        _finishGame(winnerId);
      },
    );

    _channel
        .onPresenceSync((_) {
          final presence = _channel.presenceState();
          _isOpponentConnected = presence
              .expand((s) => s.presences)
              .any((p) => p.presenceRef != myUserId);
          notifyListeners();
        })
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _channel.track({'user_id': myUserId});
          }
        });
  }

  bool makeLocalMove(int row, int col) {
    if (!isMyTurn) return false;
    if (_state.board[row][col] != null) return false;

    final newBoard = List.generate(
      _state.boardSize,
      (r) => List<Player?>.from(_state.board[r]),
    );
    newBoard[row][col] = mySymbol;

    final move = GameMove(mySymbol, BoardPosition(row, col));
    final newHistory = List<GameMove>.from(_state.moveHistory)..add(move);
    final winningLine = _checkWin(row, col, mySymbol, newBoard);

    if (winningLine != null) {
      _state = _state.copyWith(
        board: newBoard,
        moveHistory: newHistory,
        status: GameStatus.won,
        winner: mySymbol,
        winningLine: winningLine,
      );
      _channel.sendBroadcastMessage(
          event: 'move', payload: {'row': row, 'col': col});
      _channel.sendBroadcastMessage(
          event: 'game_end', payload: {'winner_id': myUserId});
      _rewardDiamonds('WIN');
    } else {
      _state = _state.copyWith(
        board: newBoard,
        moveHistory: newHistory,
        currentPlayer: mySymbol.opponent,
      );
      _channel.sendBroadcastMessage(
          event: 'move', payload: {'row': row, 'col': col});
    }

    notifyListeners();
    return true;
  }

  void _handleOpponentMove(int row, int col) {
    final opponentSymbol = mySymbol.opponent;
    final newBoard = List.generate(
      _state.boardSize,
      (r) => List<Player?>.from(_state.board[r]),
    );
    newBoard[row][col] = opponentSymbol;

    final move = GameMove(opponentSymbol, BoardPosition(row, col));
    final newHistory = List<GameMove>.from(_state.moveHistory)..add(move);

    final winningLine = _checkWin(row, col, opponentSymbol, newBoard);

    if (winningLine != null) {
      _state = _state.copyWith(
        board: newBoard,
        moveHistory: newHistory,
        status: GameStatus.won,
        winner: opponentSymbol,
        winningLine: winningLine,
      );
      _rewardDiamonds('LOSS');
    } else {
      _state = _state.copyWith(
        board: newBoard,
        moveHistory: newHistory,
        currentPlayer: mySymbol,
      );
    }
    notifyListeners();
  }

  void _finishGame(String? winnerId) {
    if (_state.status != GameStatus.playing) return;
    if (winnerId == myUserId) {
      _state = _state.copyWith(status: GameStatus.won, winner: mySymbol);
      _rewardDiamonds('WIN');
    } else if (winnerId != null) {
      _state = _state.copyWith(
          status: GameStatus.won, winner: mySymbol.opponent);
      _rewardDiamonds('LOSS');
    }
    notifyListeners();
  }

  void forfeit() {
    _channel.sendBroadcastMessage(
        event: 'game_end', payload: {'winner_id': 'opponent'});
    if (_state.status == GameStatus.playing) {
      _state =
          _state.copyWith(status: GameStatus.won, winner: mySymbol.opponent);
      _rewardDiamonds('LOSS');
      notifyListeners();
    }
  }

  void _rewardDiamonds(String outcome) {
    RankService.addMatchResult(
      mode: 'Chơi Online',
      result: outcome,
      isHardAi: false,
    ).then((earned) {
      _earnedDiamonds = earned;
      notifyListeners();
    });
  }

  List<BoardPosition>? _checkWin(
      int r, int c, Player player, List<List<Player?>> board) {
    final boardSize = _state.boardSize;
    final directions = [
      [const BoardPosition(0, 1), const BoardPosition(0, -1)],
      [const BoardPosition(1, 0), const BoardPosition(-1, 0)],
      [const BoardPosition(1, 1), const BoardPosition(-1, -1)],
      [const BoardPosition(1, -1), const BoardPosition(-1, 1)],
    ];

    for (final dirPair in directions) {
      final winningPositions = <BoardPosition>[BoardPosition(r, c)];
      for (final dir in dirPair) {
        int step = 1;
        while (true) {
          final nr = r + dir.row * step;
          final nc = c + dir.col * step;
          if (nr < 0 || nr >= boardSize || nc < 0 || nc >= boardSize) break;
          if (board[nr][nc] == player) {
            winningPositions.add(BoardPosition(nr, nc));
            step++;
          } else {
            break;
          }
        }
      }
      final int winLength = boardSize == 3 ? 3 : 5;
      if (winningPositions.length >= winLength) return winningPositions;
    }
    return null;
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    super.dispose();
  }
}
