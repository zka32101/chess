import 'package:chess/chess.dart' as chess_lib;
import 'package:chess_tactics_master/src/services/ai_opponent_engine.dart';

/// State of a CPU game
class CpuGameState {
  final chess_lib.Chess gameState;
  final AIDifficulty difficulty;
  final List<chess_lib.Move> moves;
  final bool isGameOver;
  final String? result; // 'white_win', 'black_win', 'draw'
  final String? endReason; // 'checkmate', 'resignation', 'stalemate'
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAIThinking;
  final bool playerIsWhite;

  CpuGameState({
    required this.gameState,
    required this.difficulty,
    this.moves = const [],
    this.isGameOver = false,
    this.result,
    this.endReason,
    required this.startTime,
    this.endTime,
    this.isAIThinking = false,
    this.playerIsWhite = true,
  });

  /// Get the current turn (true = white, false = black)
  bool get isWhiteTurn => gameState.turn == chess_lib.Color.WHITE;

  /// Check if it's the player's turn
  bool get isPlayerTurn {
    if (playerIsWhite) {
      return isWhiteTurn;
    } else {
      return !isWhiteTurn;
    }
  }

  /// Get game duration
  Duration get gameDuration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Create a copy with updated fields
  CpuGameState copyWith({
    chess_lib.Chess? gameState,
    AIDifficulty? difficulty,
    List<chess_lib.Move>? moves,
    bool? isGameOver,
    String? result,
    String? endReason,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAIThinking,
    bool? playerIsWhite,
  }) {
    return CpuGameState(
      gameState: gameState ?? this.gameState,
      difficulty: difficulty ?? this.difficulty,
      moves: moves ?? this.moves,
      isGameOver: isGameOver ?? this.isGameOver,
      result: result ?? this.result,
      endReason: endReason ?? this.endReason,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAIThinking: isAIThinking ?? this.isAIThinking,
      playerIsWhite: playerIsWhite ?? this.playerIsWhite,
    );
  }
}
