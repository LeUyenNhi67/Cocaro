class BoardPosition {
  final int row;
  final int col;

  const BoardPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';
}

enum Player { X, O }

extension PlayerExtension on Player {
  Player get opponent => this == Player.X ? Player.O : Player.X;
  String get symbol => this == Player.X ? 'X' : 'O';
}
