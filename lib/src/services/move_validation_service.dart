import 'package:chess/chess.dart' as chess_lib;

/// Service for comprehensive move validation and analysis
class MoveValidationService {
  /// Validate a move with detailed error reporting
  static MoveValidationResult validateMove(
    chess_lib.Chess chess,
    String from,
    String to, {
    String? promotion,
  }) {
    try {
      // Check square format
      if (!_isValidSquare(from) || !_isValidSquare(to)) {
        return MoveValidationResult(
          isValid: false,
          error: 'Invalid square format',
        );
      }

      // Check if same square
      if (from == to) {
        return MoveValidationResult(
          isValid: false,
          error: 'Source and destination squares must be different',
        );
      }

      // Check if there's a piece on source square
      final piece = _getPieceAt(chess, from);
      if (piece == null) {
        return MoveValidationResult(
          isValid: false,
          error: 'No piece on source square',
        );
      }

      // Check piece color matches turn
      if (piece.color != chess.turn) {
        return MoveValidationResult(
          isValid: false,
          error: 'Not your turn to move',
        );
      }

      // Validate pawn promotion
      if (piece.type == chess_lib.PieceType.pawn) {
        final destinationRank = int.parse(to[1]);
        if ((destinationRank == 8 && piece.color == chess_lib.Color.WHITE) ||
            (destinationRank == 1 && piece.color == chess_lib.Color.BLACK)) {
          if (promotion == null ||
              !['q', 'r', 'b', 'n'].contains(promotion.toLowerCase())) {
            return MoveValidationResult(
              isValid: false,
              error: 'Pawn promotion required (q/r/b/n)',
            );
          }
        }
      }

      // Check move is legal
      try {
        final move = chess_lib.Move(
          fromAlgebraic: from,
          toAlgebraic: to,
          promotion: promotion,
        );

        final legalMoves = chess.moves() as List<chess_lib.Move>;
        final isLegal = legalMoves.any((m) =>
            m.fromAlgebraic == move.fromAlgebraic &&
            m.toAlgebraic == move.toAlgebraic &&
            (promotion == null || m.promotion == promotion));

        if (!isLegal) {
          return MoveValidationResult(
            isValid: false,
            error: 'Move is not legal in this position',
          );
        }

        return MoveValidationResult(
          isValid: true,
          error: null,
        );
      } catch (e) {
        return MoveValidationResult(
          isValid: false,
          error: 'Move validation error: $e',
        );
      }
    } catch (e) {
      return MoveValidationResult(
        isValid: false,
        error: 'Validation error: $e',
      );
    }
  }

  /// Get all legal moves from a square
  static List<LegalMove> getLegalMovesFromSquare(
    chess_lib.Chess chess,
    String fromSquare,
  ) {
    try {
      if (!_isValidSquare(fromSquare)) {
        return [];
      }

      final legalMoves = chess.moves() as List<chess_lib.Move>;
      final movesFromSquare = legalMoves
          .where((move) => move.fromAlgebraic == fromSquare)
          .toList();

      return movesFromSquare.map((move) {
        // Check if move gives check
        chess.move(move);
        final givesCheck = chess.in_check();
        final gameEnds = chess.game_over();
        chess.undo_move();

        return LegalMove(
          from: move.fromAlgebraic,
          to: move.toAlgebraic,
          promotion: move.promotion,
          isCheck: givesCheck,
          isCheckmate: gameEnds && chess.in_checkmate(),
          isCapture: move.flags.contains('c'),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Analyze a position for tactical patterns
  static PositionAnalysis analyzePosition(chess_lib.Chess chess) {
    try {
      final legalMoves = chess.moves() as List<chess_lib.Move>;
      var checkMovesCount = 0;
      var captureMovesCount = 0;
      var checkMateMovesCount = 0;

      for (final move in legalMoves) {
        chess.move(move);

        if (chess.in_checkmate()) {
          checkMateMovesCount++;
        } else if (chess.in_check()) {
          checkMovesCount++;
        }

        chess.undo_move();

        // Count captures
        if (move.flags.contains('c')) {
          captureMovesCount++;
        }
      }

      final material = _calculateMaterial(chess);
      final isEndgame = material['white']! < 400 && material['black']! < 400;

      return PositionAnalysis(
        legalMovesCount: legalMoves.length,
        checkMovesAvailable: checkMovesCount > 0,
        captureMovesAvailable: captureMovesCount > 0,
        checkMateMovesAvailable: checkMateMovesCount > 0,
        isCheck: chess.in_check(),
        isStalemate: chess.in_stalemate(),
        isCheckmate: chess.in_checkmate(),
        isEndgame: isEndgame,
        whiteMaterial: material['white']!,
        blackMaterial: material['black']!,
      );
    } catch (e) {
      return PositionAnalysis(
        legalMovesCount: 0,
        checkMovesAvailable: false,
        captureMovesAvailable: false,
        checkMateMovesAvailable: false,
        isCheck: false,
        isStalemate: false,
        isCheckmate: false,
        isEndgame: false,
        whiteMaterial: 0,
        blackMaterial: 0,
      );
    }
  }

  /// Helper: Check if square is valid
  static bool _isValidSquare(String square) {
    if (square.length != 2) return false;
    final file = square.codeUnitAt(0);
    final rank = int.tryParse(square[1]);
    return file >= 'a'.codeUnitAt(0) &&
        file <= 'h'.codeUnitAt(0) &&
        rank != null &&
        rank >= 1 &&
        rank <= 8;
  }

  /// Helper: Get piece at square
  static chess_lib.Piece? _getPieceAt(chess_lib.Chess chess, String square) {
    try {
      final rank = 8 - int.parse(square[1]);
      final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
      return chess.board[rank][file];
    } catch (e) {
      return null;
    }
  }

  /// Helper: Calculate material value
  static Map<String, int> _calculateMaterial(chess_lib.Chess chess) {
    const pieceValues = {
      'p': 1,
      'n': 3,
      'b': 3,
      'r': 5,
      'q': 9,
      'k': 0,
    };

    var whiteMaterial = 0;
    var blackMaterial = 0;

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final piece = chess.board[rank][file];
        if (piece != null) {
          final value = pieceValues[piece.type.name] ?? 0;
          if (piece.color == chess_lib.Color.WHITE) {
            whiteMaterial += value;
          } else {
            blackMaterial += value;
          }
        }
      }
    }

    return {
      'white': whiteMaterial,
      'black': blackMaterial,
    };
  }
}

/// Result of move validation
class MoveValidationResult {
  final bool isValid;
  final String? error;

  MoveValidationResult({
    required this.isValid,
    this.error,
  });
}

/// Information about a legal move
class LegalMove {
  final String from;
  final String to;
  final String? promotion;
  final bool isCheck;
  final bool isCheckmate;
  final bool isCapture;

  LegalMove({
    required this.from,
    required this.to,
    this.promotion,
    required this.isCheck,
    required this.isCheckmate,
    required this.isCapture,
  });
}

/// Analysis of current position
class PositionAnalysis {
  final int legalMovesCount;
  final bool checkMovesAvailable;
  final bool captureMovesAvailable;
  final bool checkMateMovesAvailable;
  final bool isCheck;
  final bool isStalemate;
  final bool isCheckmate;
  final bool isEndgame;
  final int whiteMaterial;
  final int blackMaterial;

  PositionAnalysis({
    required this.legalMovesCount,
    required this.checkMovesAvailable,
    required this.captureMovesAvailable,
    required this.checkMateMovesAvailable,
    required this.isCheck,
    required this.isStalemate,
    required this.isCheckmate,
    required this.isEndgame,
    required this.whiteMaterial,
    required this.blackMaterial,
  });

  int get materialAdvantage => whiteMaterial - blackMaterial;

  bool get whiteAhead => materialAdvantage > 0;

  bool get blackAhead => materialAdvantage < 0;

  bool get equal => materialAdvantage == 0;
}
