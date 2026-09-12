import 'package:chess/chess.dart' as chess_lib;

/// Service for calculating and managing FEN strings
class FenCalculatorService {
  /// Calculate new FEN after a move
  static String calculateNewFen(
    String currentFen,
    String fromSquare,
    String toSquare, {
    String? promotion,
  }) {
    try {
      final chess = chess_lib.Chess.fromFEN(currentFen);

      final move = chess_lib.Move(
        fromAlgebraic: fromSquare,
        toAlgebraic: toSquare,
        promotion: promotion,
      );

      // Validate move is legal
      if (!_isLegalMove(chess, move)) {
        throw Exception('Illegal move: $fromSquare to $toSquare');
      }

      // Make the move
      chess.move(move);

      // Return new FEN
      return chess.fen;
    } catch (e) {
      throw Exception('Failed to calculate FEN: $e');
    }
  }

  /// Calculate FEN from list of moves (replay position)
  static String calculateFenFromMoves(
    List<Map<String, dynamic>> moves, {
    String startingFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  }) {
    try {
      var chess = chess_lib.Chess.fromFEN(startingFen);

      for (final moveData in moves) {
        final from = moveData['from'] as String;
        final to = moveData['to'] as String;
        final promotion = moveData['promotion'] as String?;

        final move = chess_lib.Move(
          fromAlgebraic: from,
          toAlgebraic: to,
          promotion: promotion,
        );

        if (!chess.move(move)) {
          throw Exception('Invalid move in sequence: $from to $to');
        }
      }

      return chess.fen;
    } catch (e) {
      throw Exception('Failed to calculate FEN from moves: $e');
    }
  }

  /// Validate if a FEN string is legal
  static bool isValidFen(String fen) {
    try {
      chess_lib.Chess.fromFEN(fen);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extract piece placement from FEN
  static String getPiecePlacement(String fen) {
    return fen.split(' ')[0];
  }

  /// Extract active color from FEN
  static String getActiveColor(String fen) {
    return fen.split(' ')[1];
  }

  /// Extract castling rights from FEN
  static String getCastlingRights(String fen) {
    return fen.split(' ')[2];
  }

  /// Extract en passant target square from FEN
  static String getEnPassantTarget(String fen) {
    return fen.split(' ')[3];
  }

  /// Extract halfmove clock from FEN
  static int getHalfmoveClock(String fen) {
    try {
      return int.parse(fen.split(' ')[4]);
    } catch (e) {
      return 0;
    }
  }

  /// Extract fullmove number from FEN
  static int getFullmoveNumber(String fen) {
    try {
      return int.parse(fen.split(' ')[5]);
    } catch (e) {
      return 1;
    }
  }

  /// Helper to validate move legality
  static bool _isLegalMove(chess_lib.Chess chess, chess_lib.Move move) {
    try {
      final legalMoves = chess.moves() as List<chess_lib.Move>;
      return legalMoves.any((m) =>
          m.fromAlgebraic == move.fromAlgebraic &&
          m.toAlgebraic == move.toAlgebraic &&
          (move.promotion == null || m.promotion == move.promotion));
    } catch (e) {
      return false;
    }
  }
}
