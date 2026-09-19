import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess_tactics_master/src/services/performance_service.dart';
import 'package:chess_tactics_master/src/services/analytics_service.dart';
import 'package:chess_tactics_master/src/models/rating_progression.dart';
import 'package:chess_tactics_master/src/models/performance_stats.dart';
import 'package:chess_tactics_master/src/models/analytics_snapshot.dart';

/// Provider for performance service
final performanceServiceProvider = Provider((ref) {
  return PerformanceService();
});

/// Provider for analytics service
final analyticsServiceProvider = Provider((ref) {
  return AnalyticsService();
});

/// Provider for rating progression over a specific period
final ratingProgressionProvider = StreamProvider.family<List<RatingProgression>,
    ({String playerId, int days})>(
  (ref, params) async* {
    final service = ref.watch(performanceServiceProvider);
    yield* service.watchRatingProgression(
      params.playerId,
      days: params.days,
    );
  },
);

/// Provider for win rate
final performanceWinRateProvider = FutureProvider.family<double, String>(
  (ref, playerId) {
    final service = ref.watch(performanceServiceProvider);
    return service.getWinRate(playerId);
  },
);

/// Provider for performance by opponent rank
final performanceByRankProvider =
    FutureProvider.family<Map<String, int>, String>(
  (ref, playerId) {
    final service = ref.watch(performanceServiceProvider);
    return service.getPerformanceByRank(playerId);
  },
);

/// Provider for performance by time control
final performanceByTimeControlProvider =
    FutureProvider.family<Map<String, int>, String>(
  (ref, playerId) {
    final service = ref.watch(performanceServiceProvider);
    return service.getPerformanceByTimeControl(playerId);
  },
);

/// Provider for streak information
final streakInfoProvider = FutureProvider.family(
  (ref, String playerId) async {
    final service = ref.watch(performanceServiceProvider);
    return service.getStreakInfo(playerId);
  },
);

/// Comprehensive performance stats provider
final performanceStatsProvider =
    FutureProvider.family<PerformanceStats, String>(
  (ref, playerId) async {
    final service = ref.watch(performanceServiceProvider);

    // Fetch all performance data
    final progression30 = await service.getRatingProgression(
      playerId,
      days: 30,
    );
    final progression90 = await service.getRatingProgression(
      playerId,
      days: 90,
    );
    final byRank = await service.getPerformanceByRank(playerId);
    final byTimeControl = await service.getPerformanceByTimeControl(playerId);
    final streak = await service.getStreakInfo(playerId);

    return PerformanceStats(
      playerId: playerId,
      progressionLast30Days: progression30,
      progressionLast90Days: progression90,
      currentStreak: streak.current,
      longestWinStreak: streak.longestWin,
      longestLossStreak: streak.longestLoss,
      performanceByRank: byRank,
      performanceByTimeControl: byTimeControl,
      updatedAt: DateTime.now(),
    );
  },
);

/// Provider for monthly analytics snapshot
final monthlyAnalyticsProvider = FutureProvider.family<AnalyticsSnapshot,
    ({String playerId, int monthYear})>(
  (ref, params) {
    final service = ref.watch(analyticsServiceProvider);
    return service.getMonthlySnapshot(params.playerId, params.monthYear);
  },
);

/// Provider for analytics range
final analyticsRangeProvider = FutureProvider.family<List<AnalyticsSnapshot>,
    ({String playerId, DateTime fromDate, DateTime toDate})>(
  (ref, params) {
    final service = ref.watch(analyticsServiceProvider);
    return service.getAnalyticsRange(
      params.playerId,
      params.fromDate,
      params.toDate,
    );
  },
);

/// Provider for current month analytics stream
final currentMonthAnalyticsProvider =
    StreamProvider.family<AnalyticsSnapshot, String>(
  (ref, playerId) {
    final service = ref.watch(analyticsServiceProvider);
    return service.watchCurrentMonthAnalytics(playerId);
  },
);

/// Provider for comparing analytics between two players
final compareAnalyticsProvider = FutureProvider.family<Map<String, dynamic>,
    ({String player1Id, String player2Id})>(
  (ref, params) {
    final service = ref.watch(analyticsServiceProvider);
    return service.compareAnalytics(params.player1Id, params.player2Id);
  },
);

/// Provider for performance trends
final performanceTrendsProvider = FutureProvider.family<Map<String, dynamic>,
    ({String playerId, int months})>(
  (ref, params) {
    final service = ref.watch(analyticsServiceProvider);
    return service.getPerformanceTrends(params.playerId, params.months);
  },
);
