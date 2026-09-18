import 'package:riverpod/riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/player_connection_service.dart';
import '../services/leaderboard_service.dart';
import '../services/achievement_service.dart';

/// Phase T - Social & Community Features Providers
/// Provides reactive access to social connections, leaderboards, and achievements

// Service Providers

final playerConnectionServiceProvider =
    Provider<PlayerConnectionService>((ref) {
  return PlayerConnectionService(firestore: FirebaseFirestore.instance);
});

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService(firestore: FirebaseFirestore.instance);
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(firestore: FirebaseFirestore.instance);
});

// Connection Providers

/// Get player's friend list
final playerFriendsProvider =
    FutureProvider.family<List<PlayerConnection>, String>((ref, playerId) {
  final service = ref.watch(playerConnectionServiceProvider);
  return service.getFriendsList(playerId);
});

/// Get pending friend requests (incoming)
final pendingFriendRequestsProvider =
    FutureProvider.family<List<FriendRequest>, String>((ref, playerId) {
  final service = ref.watch(playerConnectionServiceProvider);
  return service.getPendingRequests(playerId);
});

/// Get sent friend requests (outgoing)
final sentFriendRequestsProvider =
    FutureProvider.family<List<FriendRequest>, String>((ref, playerId) {
  final service = ref.watch(playerConnectionServiceProvider);
  return service.getSentRequests(playerId);
});

/// Check friendship status between two players
final friendshipStatusProvider = FutureProvider.family<
    FriendshipStatus,
    ({
      String playerId,
      String otherPlayerId,
    })>((ref, params) {
  final service = ref.watch(playerConnectionServiceProvider);
  return service.isPlayerFriend(params.playerId, params.otherPlayerId);
});

// Leaderboard Providers

/// Get global leaderboard
final globalLeaderboardProvider = FutureProvider.family<
    List<LeaderboardEntry>,
    ({
      int page,
      int limit,
    })>((ref, params) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getGlobalLeaderboard(
    page: params.page,
    limit: params.limit,
  );
});

/// Get seasonal leaderboard
final seasonalLeaderboardProvider = FutureProvider.family<
    List<LeaderboardEntry>,
    ({
      String season,
      int page,
      int limit,
    })>((ref, params) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getSeasonalLeaderboard(
    season: params.season,
    page: params.page,
    limit: params.limit,
  );
});

/// Get player's leaderboard position
final playerLeaderboardPositionProvider =
    FutureProvider.family<LeaderboardRanking?, String>((ref, playerId) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getLeaderboardPosition(playerId);
});

/// Get rating tiers
final ratingTiersProvider = FutureProvider<List<RatingTier>>((ref) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getRatingTiers();
});

/// Get win streak leaderboard
final streakLeaderboardProvider = FutureProvider.family<
    List<LeaderboardEntry>,
    ({
      int page,
      int limit,
    })>((ref, params) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getStreakLeaderboard(
    page: params.page,
    limit: params.limit,
  );
});

/// Get progress leaderboard (ranked by recent rating change)
final progressLeaderboardProvider = FutureProvider.family<
    List<LeaderboardEntry>,
    ({
      int page,
      int limit,
    })>((ref, params) {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getProgressLeaderboard(
    page: params.page,
    limit: params.limit,
  );
});

// Achievement Providers

/// Get all available achievements
final allAchievementsProvider = FutureProvider<List<Achievement>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.getAchievements();
});

/// Get player's earned achievements
final playerAchievementsProvider =
    FutureProvider.family<List<PlayerAchievement>, String>((ref, playerId) {
  final service = ref.watch(achievementServiceProvider);
  return service.getPlayerAchievements(playerId);
});

/// Check progress toward achievement
final achievementProgressProvider = FutureProvider.family<
    AchievementProgress,
    ({
      String playerId,
      String achievementId,
    })>((ref, params) {
  final service = ref.watch(achievementServiceProvider);
  return service.checkAchievementProgress(params.playerId, params.achievementId);
});

/// Get rarest achievements
final rarestAchievementsProvider =
    FutureProvider<List<Achievement>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.getRarestAchievements();
});

/// Get achievements by category
final achievementsByCategoryProvider =
    FutureProvider.family<List<Achievement>, String>((ref, category) {
  final service = ref.watch(achievementServiceProvider);
  return service.getAchievementsByCategory(category);
});

/// Get achievement statistics
final achievementStatsProvider =
    FutureProvider<List<AchievementStatistic>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.getAchievementStats();
});

// State Management Providers

/// State notifier for friend request operations
final friendRequestNotifierProvider = StateNotifierProvider<
    FriendRequestNotifier,
    FriendRequestState>((ref) {
  final service = ref.watch(playerConnectionServiceProvider);
  return FriendRequestNotifier(service);
});

/// State notifier for achievement unlocks
final achievementUnlockNotifierProvider = StateNotifierProvider<
    AchievementUnlockNotifier,
    AchievementUnlockState>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return AchievementUnlockNotifier(service);
});

// Notifier Implementations

class FriendRequestNotifier extends StateNotifier<FriendRequestState> {
  final PlayerConnectionService _service;

  FriendRequestNotifier(this._service)
      : super(const FriendRequestState());

  Future<void> sendFriendRequest({
    required String fromPlayerId,
    required String toPlayerId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.sendFriendRequest(
        fromPlayerId: fromPlayerId,
        toPlayerId: toPlayerId,
      );

      state = state.copyWith(
        isLoading: false,
        lastAction: 'request_sent',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> acceptFriendRequest({
    required String playerId,
    required String requestId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.acceptFriendRequest(
        playerId: playerId,
        requestId: requestId,
      );

      state = state.copyWith(
        isLoading: false,
        lastAction: 'request_accepted',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> declineFriendRequest({
    required String playerId,
    required String requestId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.declineFriendRequest(
        playerId: playerId,
        requestId: requestId,
      );

      state = state.copyWith(
        isLoading: false,
        lastAction: 'request_declined',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> removeFriend({
    required String playerId,
    required String friendId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.removeFriend(
        playerId: playerId,
        friendId: friendId,
      );

      state = state.copyWith(
        isLoading: false,
        lastAction: 'friend_removed',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

class AchievementUnlockNotifier extends StateNotifier<AchievementUnlockState> {
  final AchievementService _service;

  AchievementUnlockNotifier(this._service)
      : super(const AchievementUnlockState());

  Future<void> awardAchievement({
    required String playerId,
    required String achievementId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.awardAchievement(
        playerId: playerId,
        achievementId: achievementId,
      );

      state = state.copyWith(
        isLoading: false,
        lastUnlockedId: achievementId,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// State Classes

class FriendRequestState {
  final bool isLoading;
  final String? lastAction;
  final String? error;

  const FriendRequestState({
    this.isLoading = false,
    this.lastAction,
    this.error,
  });

  FriendRequestState copyWith({
    bool? isLoading,
    String? lastAction,
    String? error,
  }) {
    return FriendRequestState(
      isLoading: isLoading ?? this.isLoading,
      lastAction: lastAction ?? this.lastAction,
      error: error ?? this.error,
    );
  }
}

class AchievementUnlockState {
  final bool isLoading;
  final String? lastUnlockedId;
  final String? error;

  const AchievementUnlockState({
    this.isLoading = false,
    this.lastUnlockedId,
    this.error,
  });

  AchievementUnlockState copyWith({
    bool? isLoading,
    String? lastUnlockedId,
    String? error,
  }) {
    return AchievementUnlockState(
      isLoading: isLoading ?? this.isLoading,
      lastUnlockedId: lastUnlockedId ?? this.lastUnlockedId,
      error: error ?? this.error,
    );
  }
}
