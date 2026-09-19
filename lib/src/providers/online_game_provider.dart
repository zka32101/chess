import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chess_tactics_master/src/models/online_game.dart';
import 'package:chess_tactics_master/src/services/matchmaking_service.dart';
import 'package:chess_tactics_master/src/services/online_game_service.dart';
import 'package:chess_tactics_master/src/services/ai_opponent_engine_enhanced.dart';

/// Provider for Firebase Auth state
final firebaseAuthProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for matchmaking service
final matchmakingServiceProvider = Provider<MatchmakingService>((ref) {
  return MatchmakingService();
});

/// Provider for online game service
final onlineGameServiceProvider = Provider<OnlineGameService>((ref) {
  return OnlineGameService();
});

/// Provider for current queue status
final queueStatusProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, queueId) async {
    final service = ref.watch(matchmakingServiceProvider);
    return service.getQueueStatus(queueId);
  },
);

/// Provider for queue statistics
final queueStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(matchmakingServiceProvider);
  return service.getQueueStats();
});

/// Provider for current user's active games
final userActiveGamesProvider = FutureProvider<List<OnlineGame>>((ref) async {
  final authState = ref.watch(firebaseAuthProvider);
  final service = ref.watch(onlineGameServiceProvider);

  final userId = authState.whenData((user) => user?.uid).value;
  if (userId == null) {
    return [];
  }

  return service.getPlayerActiveGames(userId);
});

/// Provider for current user's recent games
final userRecentGamesProvider = FutureProvider<List<OnlineGame>>((ref) async {
  final authState = ref.watch(firebaseAuthProvider);
  final service = ref.watch(onlineGameServiceProvider);

  final userId = authState.whenData((user) => user?.uid).value;
  if (userId == null) {
    return [];
  }

  return service.getPlayerRecentGames(userId, limit: 20);
});

/// Provider for specific game by ID
final onlineGameProvider = FutureProvider.family<OnlineGame?, String>(
  (ref, gameId) async {
    final service = ref.watch(onlineGameServiceProvider);
    return service.getGame(gameId);
  },
);

/// Stream provider for real-time game updates
final gameStreamProvider =
    StreamProvider.family<OnlineGame, String>((ref, gameId) {
  final service = ref.watch(onlineGameServiceProvider);
  return service.watchGame(gameId);
});

/// Provider for game moves
final gameMoveProvider =
    FutureProvider.family<List<GameMove>, String>((ref, gameId) async {
  final service = ref.watch(onlineGameServiceProvider);
  return service.getGameMoves(gameId);
});

/// Notifier for online game operations
class OnlineGameNotifier extends StateNotifier<AsyncValue<void>> {
  final OnlineGameService _service;
  final String? _userId;

  OnlineGameNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null));

  /// Create a new online game
  Future<OnlineGame> createGame({
    required String whitePlayerId,
    required String whitePlayerName,
    required int whiteRating,
    required String blackPlayerId,
    required String blackPlayerName,
    required int blackRating,
    required String gameType,
    required String timeControl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final game = await _service.createGame(
        whitePlayerId: whitePlayerId,
        whitePlayerName: whitePlayerName,
        whiteRating: whiteRating,
        blackPlayerId: blackPlayerId,
        blackPlayerName: blackPlayerName,
        blackRating: blackRating,
        gameType: gameType,
        timeControl: timeControl,
      );
      state = const AsyncValue.data(null);
      return game;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Start a game
  Future<void> startGame(String gameId) async {
    state = const AsyncValue.loading();
    try {
      await _service.startGame(gameId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Record a move
  Future<void> recordMove({
    required String gameId,
    required int moveNumber,
    required String from,
    required String to,
    String? promotion,
    required String playerId,
    required String updatedFen,
    required String updatedPgn,
  }) async {
    try {
      await _service.recordMove(
        gameId: gameId,
        moveNumber: moveNumber,
        from: from,
        to: to,
        promotion: promotion,
        playerId: playerId,
        updatedFen: updatedFen,
        updatedPgn: updatedPgn,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update time remaining
  Future<void> updateTimeRemaining({
    required String gameId,
    required int whiteTimeMs,
    required int blackTimeMs,
  }) async {
    try {
      await _service.updateTimeRemaining(
        gameId: gameId,
        whiteTimeMs: whiteTimeMs,
        blackTimeMs: blackTimeMs,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Record player activity
  Future<void> recordActivity(String gameId, String playerId) async {
    try {
      await _service.recordActivity(gameId, playerId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Resign from game
  Future<void> resign(String gameId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.resignGame(gameId, _userId!);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Abandon game
  Future<void> abandon(String gameId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _service.abandonGame(gameId, _userId!);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// State notifier provider for online game operations
final onlineGameNotifierProvider =
    StateNotifierProvider<OnlineGameNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(onlineGameServiceProvider);
  final authState = ref.watch(firebaseAuthProvider);
  final userId = authState.whenData((user) => user?.uid).value;

  return OnlineGameNotifier(service, userId);
});

/// Notifier for matchmaking operations
class MatchmakingNotifier extends StateNotifier<AsyncValue<void>> {
  final MatchmakingService _service;

  MatchmakingNotifier(this._service) : super(const AsyncValue.data(null));

  /// Join matchmaking queue
  Future<MatchmakingQueueEntry> joinQueue({
    required String playerId,
    required String playerName,
    required int currentRating,
    required String timeControlType,
    required String color,
  }) async {
    state = const AsyncValue.loading();
    try {
      final entry = await _service.joinQueue(
        playerId: playerId,
        playerName: playerName,
        currentRating: currentRating,
        timeControlType: timeControlType,
        color: color,
      );
      state = const AsyncValue.data(null);
      return entry;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Leave matchmaking queue
  Future<void> leaveQueue(String queueId) async {
    state = const AsyncValue.loading();
    try {
      await _service.leaveQueue(queueId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// State notifier provider for matchmaking operations
final matchmakingNotifierProvider =
    StateNotifierProvider<MatchmakingNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(matchmakingServiceProvider);
  return MatchmakingNotifier(service);
});
