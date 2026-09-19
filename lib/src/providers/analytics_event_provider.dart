import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_event_tracker.dart';
import '../services/revenue_tracking_service.dart';

/// Analytics event tracker provider
final analyticsEventTrackerProvider = Provider((ref) {
  return AnalyticsEventTracker();
});

/// Revenue tracking service provider
final revenueTrackingProvider = Provider((ref) {
  return RevenueTrackingService();
});

/// Tracked events provider
final trackedEventsProvider = Provider((ref) {
  final tracker = ref.watch(analyticsEventTrackerProvider);
  return tracker.getTrackedEvents();
});

/// Total revenue provider
final totalRevenueProvider = Provider((ref) {
  final revenueService = ref.watch(revenueTrackingProvider);
  return revenueService.getTotalRevenue();
});

/// Total transactions provider
final totalTransactionsProvider = Provider((ref) {
  final revenueService = ref.watch(revenueTrackingProvider);
  return revenueService.getTransactionCount();
});

/// Average transaction value provider
final averageTransactionValueProvider = Provider((ref) {
  final revenueService = ref.watch(revenueTrackingProvider);
  return revenueService.getAverageTransactionValue();
});

/// Revenue by segment provider
final revenueBySegmentProvider =
    Provider.family<double, String>((ref, segment) {
  final revenueService = ref.watch(revenueTrackingProvider);
  return revenueService.getSegmentRevenue(segment);
});

/// All revenue segments provider
final allRevenueSegmentsProvider = Provider((ref) {
  final revenueService = ref.watch(revenueTrackingProvider);
  return revenueService.getAllSegments();
});

/// Purchase tracking notifier
class PurchaseTracker extends StateNotifier<bool> {
  final _tracker = AnalyticsEventTracker();

  PurchaseTracker() : super(false);

  Future<void> trackPurchase({
    required String itemId,
    required double price,
    required String currency,
    required String type,
  }) async {
    state = true;
    try {
      await _tracker.trackPurchase(
        itemId: itemId,
        price: price,
        currency: currency,
        type: type,
      );
    } finally {
      state = false;
    }
  }
}

/// Purchase tracking provider
final purchaseTrackingProvider =
    StateNotifierProvider<PurchaseTracker, bool>((ref) {
  return PurchaseTracker();
});

/// Feature usage tracking notifier
class FeatureUsageTracker extends StateNotifier<Map<String, int>> {
  final _tracker = AnalyticsEventTracker();

  FeatureUsageTracker() : super({});

  Future<void> trackFeatureUsage(String featureId) async {
    await _tracker.trackFeatureUsage(featureId);
    state = {...state, featureId: (state[featureId] ?? 0) + 1};
  }
}

/// Feature usage tracking provider
final featureUsageTrackingProvider =
    StateNotifierProvider<FeatureUsageTracker, Map<String, int>>((ref) {
  return FeatureUsageTracker();
});

/// Game completion tracking notifier
class GameCompletionTracker extends StateNotifier<int> {
  final _tracker = AnalyticsEventTracker();

  GameCompletionTracker() : super(0);

  Future<void> trackGameCompletion({
    required String gameType,
    required String result,
    required int durationSeconds,
  }) async {
    await _tracker.trackGameCompletion(
      gameType: gameType,
      result: result,
      durationSeconds: durationSeconds,
    );
    state = state + 1;
  }
}

/// Game completion tracking provider
final gameCompletionTrackingProvider =
    StateNotifierProvider<GameCompletionTracker, int>((ref) {
  return GameCompletionTracker();
});
