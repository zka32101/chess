import 'package:riverpod/riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/season_management_service.dart';
import '../services/battle_pass_service.dart';
import '../services/season_challenge_service.dart';
import '../services/seasonal_reward_service.dart';
import '../services/seasonal_event_service.dart';

// Parameter classes for family providers (Dart 2.17+ compatibility)
class SeasonPaginationParams {
  final int limit;
  final int offset;

  SeasonPaginationParams({required this.limit, required this.offset});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonPaginationParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => limit.hashCode ^ offset.hashCode;
}

class BattlePassRewardsParams {
  final String playerId;
  final String seasonId;
  final bool isPremium;

  BattlePassRewardsParams({
    required this.playerId,
    required this.seasonId,
    required this.isPremium,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattlePassRewardsParams &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          seasonId == other.seasonId &&
          isPremium == other.isPremium;

  @override
  int get hashCode =>
      playerId.hashCode ^ seasonId.hashCode ^ isPremium.hashCode;
}

class ChallengesParams {
  final String seasonId;
  final String? type;

  ChallengesParams({required this.seasonId, this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengesParams &&
          runtimeType == other.runtimeType &&
          seasonId == other.seasonId &&
          type == other.type;

  @override
  int get hashCode => seasonId.hashCode ^ type.hashCode;
}

class ChallengeDifficultyParams {
  final String seasonId;
  final String difficulty;

  ChallengeDifficultyParams({
    required this.seasonId,
    required this.difficulty,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeDifficultyParams &&
          runtimeType == other.runtimeType &&
          seasonId == other.seasonId &&
          difficulty == other.difficulty;

  @override
  int get hashCode => seasonId.hashCode ^ difficulty.hashCode;
}

class PlayerChallengeParams {
  final String playerId;
  final String challengeId;

  PlayerChallengeParams({
    required this.playerId,
    required this.challengeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerChallengeParams &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          challengeId == other.challengeId;

  @override
  int get hashCode => playerId.hashCode ^ challengeId.hashCode;
}

class SeasonChallengesParams {
  final String playerId;
  final String seasonId;

  SeasonChallengesParams({
    required this.playerId,
    required this.seasonId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonChallengesParams &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          seasonId == other.seasonId;

  @override
  int get hashCode => playerId.hashCode ^ seasonId.hashCode;
}

class EventLeaderboardParams {
  final String eventId;
  final int limit;

  EventLeaderboardParams({required this.eventId, required this.limit});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventLeaderboardParams &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          limit == other.limit;

  @override
  int get hashCode => eventId.hashCode ^ limit.hashCode;
}

class EventParticipationParams {
  final String playerId;
  final String eventId;

  EventParticipationParams({
    required this.playerId,
    required this.eventId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventParticipationParams &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          eventId == other.eventId;

  @override
  int get hashCode => playerId.hashCode ^ eventId.hashCode;
}

class TopEventParticipantsParams {
  final String eventId;
  final int limit;

  TopEventParticipantsParams({
    required this.eventId,
    required this.limit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopEventParticipantsParams &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          limit == other.limit;

  @override
  int get hashCode => eventId.hashCode ^ limit.hashCode;
}

class EventChallengesParams {
  final String seasonId;
  final String eventId;

  EventChallengesParams({
    required this.seasonId,
    required this.eventId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventChallengesParams &&
          runtimeType == other.runtimeType &&
          seasonId == other.seasonId &&
          eventId == other.eventId;

  @override
  int get hashCode => seasonId.hashCode ^ eventId.hashCode;
}

class RewardHistoryParams {
  final String playerId;
  final String? seasonId;
  final int limit;

  RewardHistoryParams({
    required this.playerId,
    this.seasonId,
    required this.limit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardHistoryParams &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          seasonId == other.seasonId &&
          limit == other.limit;

  @override
  int get hashCode =>
      playerId.hashCode ^ seasonId.hashCode ^ limit.hashCode;
}

class RewardCodeParams {
  final String playerId;
  final String code;

  RewardCodeParams({required this.playerId, required this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardCodeParams &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          code == other.code;

  @override
  int get hashCode => playerId.hashCode ^ code.hashCode;
}

class RewardsByTypeParams {
  final String seasonId;
  final String type;

  RewardsByTypeParams({required this.seasonId, required this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardsByTypeParams &&
          runtimeType == other.runtimeType &&
          seasonId == other.seasonId &&
          type == other.type;

  @override
  int get hashCode => seasonId.hashCode ^ type.hashCode;
}

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
    FutureProvider.family<List<Season>, SeasonPaginationParams>(
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
  SeasonChallengesParams>((ref, params) {
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
final claimedBattlePassRewardsProvider =
    FutureProvider.family<List<int>, BattlePassRewardsParams>(
  (ref, params) {
    final service = ref.watch(battlePassServiceProvider);
    return service.getClaimedRewards(
      playerId: params.playerId,
      seasonId: params.seasonId,
      isPremium: params.isPremium,
    );
  },
);

// Challenge Providers

/// Get active challenges for season
final activeChallengesProvider =
    FutureProvider.family<List<Challenge>, ChallengesParams>(
  (ref, params) {
    final service = ref.watch(seasonChallengeServiceProvider);
    return service.getChallenges(
      seasonId: params.seasonId,
      type: params.type,
    );
  },
);

/// Get challenges by difficulty
final challengesByDifficultyProvider =
    FutureProvider.family<List<Challenge>, ChallengeDifficultyParams>(
  (ref, params) {
    final service = ref.watch(seasonChallengeServiceProvider);
    return service.getChallengeTiers(
      params.seasonId,
      difficulty: params.difficulty,
    );
  },
);

/// Get player's challenge progress
final playerChallengeProgressProvider =
    FutureProvider.family<PlayerChallengeProgress?,
  PlayerChallengeParams>((ref, params) {
  final service = ref.watch(seasonChallengeServiceProvider);
  return service.getPlayerChallengeProgress(
    params.playerId,
    params.challengeId,
  );
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
final eventChallengesProvider =
    FutureProvider.family<List<Challenge>, String>((ref, seasonId) {
  // TODO: Currently only supports seasonId parameter
  // Future: update to support eventId as well
  final service = ref.watch(seasonChallengeServiceProvider);
  return service.getChallenges(seasonId: seasonId);
});

/// Get all player challenges for season
final playerSeasonChallengesProvider =
    FutureProvider.family<List<PlayerChallengeProgress>,
  SeasonChallengesParams>((ref, params) {
  final service = ref.watch(seasonChallengeServiceProvider);
  return service.getPlayerSeasonChallenges(
    params.playerId,
    params.seasonId,
  );
});

// Reward Providers

/// Get rewards by type
final rewardsByTypeProvider =
    FutureProvider.family<List<Reward>, RewardsByTypeParams>(
  (ref, params) {
    final service = ref.watch(seasonalRewardServiceProvider);
    return service.getRewardsByType(
      seasonId: params.seasonId,
      type: params.type,
    );
  },
);

/// Get player's reward history
final playerRewardHistoryProvider =
    FutureProvider.family<List<PlayerRewardHistory>,
  RewardHistoryParams>((ref, params) {
  final service = ref.watch(seasonalRewardServiceProvider);
  return service.getPlayerRewardHistory(
    playerId: params.playerId,
    seasonId: params.seasonId,
    limit: params.limit,
  );
});

/// Get season-end rewards
final seasonEndRewardsProvider =
    FutureProvider.family<List<Reward>, SeasonChallengesParams>(
  (ref, params) {
    final service = ref.watch(seasonalRewardServiceProvider);
    return service.calculateSeasonEndRewards(
      playerId: params.playerId,
      seasonId: params.seasonId,
    );
  },
);

/// Check if player has redeemed code
final playerCodeRedemptionProvider =
    FutureProvider.family<bool, RewardCodeParams>(
  (ref, params) {
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
final playerEventProgressProvider =
    FutureProvider.family<EventParticipation?,
  EventParticipationParams>((ref, params) {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getPlayerEventProgress(
    params.playerId,
    params.eventId,
  );
});

/// Get event leaderboard
final eventLeaderboardProvider =
    FutureProvider.family<List<EventLeaderboardEntry>,
  EventLeaderboardParams>((ref, params) {
  final service = ref.watch(seasonalEventServiceProvider);
  return service.getEventLeaderboard(
    params.eventId,
    limit: params.limit,
  );
});

/// Get top event participants
final topEventParticipantsProvider =
    FutureProvider.family<List<EventParticipation>,
  TopEventParticipantsParams>((ref, params) {
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
