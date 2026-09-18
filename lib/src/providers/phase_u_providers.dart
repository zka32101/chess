import 'package:riverpod/riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/season_management_service.dart';
import '../services/battle_pass_service.dart';
import '../services/season_challenge_service.dart';
import '../services/seasonal_reward_service.dart';
import '../services/seasonal_event_service.dart';

/// Phase U - Seasonal Rewards & Battle Pass Providers
/// Provides reactive access to seasonal gameplay, rewards, and events

// Service Providers

final seasonManagementServiceProvider =
    Provider<SeasonManagementService>((ref) {
  return SeasonManagementService(firestore: FirebaseFirestore.instance);
});

final battlePassServiceProvider = Provider<BattlePassService>((ref) {
  return BattlePassService(firestore: FirebaseFirestore.instance);
});

final seasonChallengeServiceProvider = Provider<SeasonChallengeService>((ref) {
  return SeasonChallengeService(firestore: FirebaseFirestore.instance);
});

final seasonalRewardServiceProvider = Provider<SeasonalRewardService>((ref) {
  return SeasonalRewardService(firestore: FirebaseFirestore.instance);
});

final seasonalEventServiceProvider = Provider<SeasonalEventService>((ref) {
  return SeasonalEventService(firestore: FirebaseFirestore.instance);
});

// Season Providers

/// Get current active season
final currentSeasonProvider = FutureProvider<Season?>((ref) {
  final service = ref.watch(seasonManagementServiceProvider);
  return service.getCurrentSeason();
});

/// Get season by ID
final seasonByIdProvider = FutureProvider.family<Season?, String>(
    (ref, seasonId) {
  final service = ref.watch(seasonManagementServiceProvider);
  return service.getSeasonById(seasonId);
});

/// Get player's seasonal progress
final playerSeasonProgressProvider =
    FutureProvider.family<PlayerSeasonProgress?, String>(
        (ref, playerId) async {
  final service = ref.watch(seasonManagementServiceProvider);
  final currentSeason = await ref.watch(currentSeasonProvider.future);

  if (currentSeason == null) {
    return null;
  }

  return service.getPlayerSeasonProgress(playerId, currentSeason.seasonId);
});

/// Get all seasons with pagination
final allSeasonsProvider =
    FutureProvider.family<List<Season>, ({int limit, int offset})>(
  (ref, params) {
    final service = ref.watch(seasonManagementServiceProvider);
    return service.getAllSeasons(limit: params.limit, offset: params.offset);
  },
);

/// Get upcoming seasons
final upcomingSeasonsProvider = FutureProvider<List<Season>>((ref) {
  final service = ref.watch(seasonManagementServiceProvider);
  return service.getUpcomingSeasons();
});

// Battle Pass Providers

/// Get battle pass for current season
final currentBattlePassProvider = FutureProvider<BattlePass?>((ref) async {
  final service = ref.watch(battlePassServiceProvider);
  final currentSeason = await ref.watch(currentSeasonProvider.future);

  if (currentSeason == null) {
    return null;
  }

  return service.getBattlePassBySeasonId(currentSeason.seasonId);
});

/// Get battle pass by ID
final battlePassProvider = FutureProvider.family<BattlePass?, String>(
    (ref, battlePassId) {
  final service = ref.watch(battlePassServiceProvider);
  return service.getBattlePass(battlePassId);
});

/// Get player's battle pass progress
final playerBattlePassProvider =
    FutureProvider.family<PlayerBattlePassProgress?,
  ({String playerId, String seasonId})>((ref, params) {
  final service = ref.watch(battlePassServiceProvider);
  return service.getPlayerBattlePassProgress(params.playerId, params.seasonId);
});

/// Get battle pass tiers
final battlePassTiersProvider =
    FutureProvider.family<List<BattlePassTier>, String>(
  (ref, battlePassId) {
    final service = ref.watch(battlePassServiceProvider);
    return service.getBattlePassTiers(battlePassId);
  },
);

/// Get claimed battle pass rewards
final claimedBattlePassRewardsProvider = FutureProvider.family<List<int>,
  ({String playerId, String seasonId, bool isPremium})>((ref, params) {
  final service = ref.watch(battlePassServiceProvider);
  return service.getClaimedRewards(
    playerId: params.playerId,
    seasonId: params.seasonId,
    isPremium: params.isPremium,
  );
});

// Challenge Providers

/// Get active challenges for season
final activeChallengesProvider = FutureProvider.family<List<Challenge>,
  ({String seasonId, String? type})>((ref, params) {
  final service = ref.watch(seasonChallengeServiceProvider);
  return service.getChallenges(seasonId: params.seasonId, type: params.type);
});

/// Get challenges by difficulty
final challengesByDifficultyProvider = FutureProvider.family<List<Challenge>,
  ({String seasonId, String difficulty})>((ref, params) {
  final service = ref.watch(seasonChallengeServiceProvider);
  return service.getChallengeTiers(params.seasonId, difficulty: params.difficulty);
});

/// Get player's challenge progress
final playerChallengeProgressProvider =
    FutureProvider.family<PlayerChallengeProgress?,
  ({String playerId, String challengeId})>((ref, params) {
  final service = ref.watch(seasonChallengeServiceProvider);
  return service.getPlayerChallengeProgress(params.playerId, params.challengeId);
});

/// Get challenge rewards
final challengeRewardsProvider =
    FutureProvider.family<List<ChallengeReward>, String>(
  (ref, challengeId) {
    final service = ref.watch(seasonChallengeServiceProvider);
    return service.getChallengeRewards(challengeId);
  },
);

/// Get event-specific challenges
final eventChallengesProvider = FutureProvider.family<List<Challenge>,
  ({String seasonId, String eventId})>((ref, params) {
  final service = ref.watch(seasonChallengeServiceProvider);
  return service.getEventChallenges(params.seasonId, eventId: params.eventId);
});

/// Get all player challenges for season
final playerSeasonChallengesProvider =
    FutureProvider.family<List<PlayerChallengeProgress>,
  ({String playerId, String seasonId})>((ref, params) {
  final service = ref.watch(seasonChallengeServiceProvider);
  return service.getPlayerSeasonChallenges(params.playerId, params.seasonId);
});

// Reward Providers

/// Get rewards by type
final rewardsByTypeProvider = FutureProvider.family<List<Reward>,
  ({String seasonId, String type})>((ref, params) {
  final service = ref.watch(seasonalRewardServiceProvider);
  return service.getRewardsByType(seasonId: params.seasonId, type: params.type);
});

/// Get player's reward history
final playerRewardHistoryProvider =
    FutureProvider.family<List<PlayerRewardHistory>,
  ({String playerId, String? seasonId, int limit})>((ref, params) {
  final service = ref.watch(seasonalRewardServiceProvider);
  return service.getPlayerRewardHistory(
    playerId: params.playerId,
    seasonId: params.seasonId,
    limit: params.limit,
  );
});

/// Get season-end rewards
final seasonEndRewardsProvider = FutureProvider.family<List<Reward>,
  ({String playerId, String seasonId})>((ref, params) {
  final service = ref.watch(seasonalRewardServiceProvider);
  return service.calculateSeasonEndRewards(
    playerId: params.playerId,
    seasonId: params.seasonId,
  );
});

/// Check if player has redeemed code
final playerCodeRedemptionProvider = FutureProvider.family<bool,
  ({String playerId, String code})>((ref, params) {
  final service = ref.watch(seasonalRewardServiceProvider);
  return service.hasPlayerRedeemedCode(
    playerId: params.playerId,
    code: params.code,
  );
});

// Event Providers

/// Get active events for season
final activeEventsProvider = FutureProvider.family<List<SeasonalEvent>, String>(
  (ref, seasonId) {
    final service = ref.watch(seasonalEventServiceProvider);
    return service.getActiveEvents(seasonId: seasonId);
  },
);

/// Get event details
final eventDetailsProvider = FutureProvider.family<SeasonalEvent?, String>(
  (ref, eventId) {
    final service = ref.watch(seasonalEventServiceProvider);
    return service.getEventDetails(eventId);
  },
);

/// Get player's event participation
final playerEventProgressProvider = FutureProvider.family<EventParticipation?,
  ({String playerId, String eventId})>((ref, params) {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getPlayerEventProgress(params.playerId, params.eventId);
});

/// Get event leaderboard
final eventLeaderboardProvider =
    FutureProvider.family<List<EventLeaderboardEntry>,
  ({String eventId, int limit})>((ref, params) {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getEventLeaderboard(params.eventId, limit: params.limit);
});

/// Get top event participants
final topEventParticipantsProvider =
    FutureProvider.family<List<EventParticipation>,
  ({String eventId, int limit})>((ref, params) {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getTopEventParticipants(params.eventId, limit: params.limit);
});

/// Get event rewards
final eventRewardsProvider = FutureProvider.family<List<EventReward>, String>(
  (ref, eventId) {
    final service = ref.watch(seasonalEventServiceProvider);
    return service.getEventRewards(eventId);
  },
);

// State Management Providers

/// State notifier for battle pass reward claiming
final battlePassClaimNotifierProvider = StateNotifierProvider<
    BattlePassClaimNotifier,
    BattlePassClaimState>((ref) {
  final service = ref.watch(battlePassServiceProvider);
  return BattlePassClaimNotifier(service);
});

/// State notifier for challenge completion
final challengeCompleteNotifierProvider = StateNotifierProvider<
    ChallengeCompleteNotifier,
    ChallengeCompleteState>((ref) {
  final service = ref.watch(seasonChallengeServiceProvider);
  return ChallengeCompleteNotifier(service);
});

/// State notifier for event participation
final eventParticipationNotifierProvider = StateNotifierProvider<
    EventParticipationNotifier,
    EventParticipationState>((ref) {
  final service = ref.watch(seasonalEventServiceProvider);
  return EventParticipationNotifier(service);
});

/// State notifier for reward claiming
final rewardClaimNotifierProvider = StateNotifierProvider<
    RewardClaimNotifier,
    RewardClaimState>((ref) {
  final service = ref.watch(seasonalRewardServiceProvider);
  return RewardClaimNotifier(service);
});

// Notifier Implementations

class BattlePassClaimNotifier extends StateNotifier<BattlePassClaimState> {
  final BattlePassService _service;

  BattlePassClaimNotifier(this._service)
      : super(const BattlePassClaimState());

  Future<void> claimReward({
    required String playerId,
    required String seasonId,
    required int level,
    required bool isPremium,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.claimBattlePassReward(
        playerId: playerId,
        seasonId: seasonId,
        level: level,
        isPremium: isPremium,
      );

      state = state.copyWith(
        isLoading: false,
        lastClaimedLevel: level,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> upgradeToPremium({
    required String playerId,
    required String seasonId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.upgradeToPremiumPass(
        playerId: playerId,
        seasonId: seasonId,
      );

      state = state.copyWith(
        isLoading: false,
        isPremiumUpgraded: true,
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

class ChallengeCompleteNotifier extends StateNotifier<ChallengeCompleteState> {
  final SeasonChallengeService _service;

  ChallengeCompleteNotifier(this._service)
      : super(const ChallengeCompleteState());

  Future<void> completeChallenge({
    required String playerId,
    required String challengeId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.completeChallenge(
        playerId: playerId,
        challengeId: challengeId,
      );

      state = state.copyWith(
        isLoading: false,
        lastCompletedId: challengeId,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProgress({
    required String playerId,
    required String challengeId,
    required int progressAmount,
  }) async {
    try {
      await _service.updateChallengeProgress(
        playerId: playerId,
        challengeId: challengeId,
        progressAmount: progressAmount,
      );

      state = state.copyWith(error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

class EventParticipationNotifier extends StateNotifier<EventParticipationState> {
  final SeasonalEventService _service;

  EventParticipationNotifier(this._service)
      : super(const EventParticipationState());

  Future<void> joinEvent({
    required String playerId,
    required String eventId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.participateInEvent(
        playerId: playerId,
        eventId: eventId,
      );

      state = state.copyWith(
        isLoading: false,
        joinedEventIds: [...state.joinedEventIds, eventId],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> withdrawFromEvent({
    required String playerId,
    required String eventId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.withdrawFromEvent(
        playerId: playerId,
        eventId: eventId,
      );

      final updated = state.joinedEventIds.where((id) => id != eventId).toList();
      state = state.copyWith(
        isLoading: false,
        joinedEventIds: updated,
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

class RewardClaimNotifier extends StateNotifier<RewardClaimState> {
  final SeasonalRewardService _service;

  RewardClaimNotifier(this._service)
      : super(const RewardClaimState());

  Future<bool> redeemCode({
    required String playerId,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final success = await _service.redeemRewardCode(
        playerId: playerId,
        code: code,
      );

      state = state.copyWith(
        isLoading: false,
        lastRedeemedCode: success ? code : null,
        error: null,
      );

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

// State Classes

class BattlePassClaimState {
  final bool isLoading;
  final int? lastClaimedLevel;
  final bool isPremiumUpgraded;
  final String? error;

  const BattlePassClaimState({
    this.isLoading = false,
    this.lastClaimedLevel,
    this.isPremiumUpgraded = false,
    this.error,
  });

  BattlePassClaimState copyWith({
    bool? isLoading,
    int? lastClaimedLevel,
    bool? isPremiumUpgraded,
    String? error,
  }) {
    return BattlePassClaimState(
      isLoading: isLoading ?? this.isLoading,
      lastClaimedLevel: lastClaimedLevel ?? this.lastClaimedLevel,
      isPremiumUpgraded: isPremiumUpgraded ?? this.isPremiumUpgraded,
      error: error ?? this.error,
    );
  }
}

class ChallengeCompleteState {
  final bool isLoading;
  final String? lastCompletedId;
  final String? error;

  const ChallengeCompleteState({
    this.isLoading = false,
    this.lastCompletedId,
    this.error,
  });

  ChallengeCompleteState copyWith({
    bool? isLoading,
    String? lastCompletedId,
    String? error,
  }) {
    return ChallengeCompleteState(
      isLoading: isLoading ?? this.isLoading,
      lastCompletedId: lastCompletedId ?? this.lastCompletedId,
      error: error ?? this.error,
    );
  }
}

class EventParticipationState {
  final bool isLoading;
  final List<String> joinedEventIds;
  final String? error;

  const EventParticipationState({
    this.isLoading = false,
    this.joinedEventIds = const [],
    this.error,
  });

  EventParticipationState copyWith({
    bool? isLoading,
    List<String>? joinedEventIds,
    String? error,
  }) {
    return EventParticipationState(
      isLoading: isLoading ?? this.isLoading,
      joinedEventIds: joinedEventIds ?? this.joinedEventIds,
      error: error ?? this.error,
    );
  }
}

class RewardClaimState {
  final bool isLoading;
  final String? lastRedeemedCode;
  final String? error;

  const RewardClaimState({
    this.isLoading = false,
    this.lastRedeemedCode,
    this.error,
  });

  RewardClaimState copyWith({
    bool? isLoading,
    String? lastRedeemedCode,
    String? error,
  }) {
    return RewardClaimState(
      isLoading: isLoading ?? this.isLoading,
      lastRedeemedCode: lastRedeemedCode ?? this.lastRedeemedCode,
      error: error ?? this.error,
    );
  }
}
