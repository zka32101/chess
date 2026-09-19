import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/paywall_service.dart';

/// Current subscription provider
final currentSubscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<Subscription?>>(
        (ref) {
  return SubscriptionNotifier();
});

/// Subscription state notifier
class SubscriptionNotifier extends StateNotifier<AsyncValue<Subscription?>> {
  final _paywallService = PaywallService();

  SubscriptionNotifier() : super(const AsyncValue.loading()) {
    _initializeSubscription();
  }

  /// Initialize subscription from service
  Future<void> _initializeSubscription() async {
    try {
      state = const AsyncValue.loading();
      await _paywallService.initialize();
      final subscription = _paywallService.getCurrentSubscription();
      state = AsyncValue.data(subscription);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh subscription
  Future<void> refreshSubscription() async {
    try {
      state = const AsyncValue.loading();
      final subscription = await _paywallService.fetchSubscription();
      state = AsyncValue.data(subscription);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Purchase subscription
  Future<bool> purchaseSubscription({
    required SubscriptionType type,
    required SubscriptionPeriod period,
  }) async {
    try {
      state = const AsyncValue.loading();
      final success = await _paywallService.purchaseSubscription(
        type: type,
        period: period,
      );

      if (success) {
        final subscription = _paywallService.getCurrentSubscription();
        state = AsyncValue.data(subscription);
      } else {
        state = AsyncValue.data(_paywallService.getCurrentSubscription());
      }

      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      state = const AsyncValue.loading();
      final success = await _paywallService.cancelSubscription();

      if (success) {
        final subscription = _paywallService.getCurrentSubscription();
        state = AsyncValue.data(subscription);
      } else {
        state = AsyncValue.data(_paywallService.getCurrentSubscription());
      }

      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      state = const AsyncValue.loading();
      final success = await _paywallService.restorePurchases();

      if (success) {
        await refreshSubscription();
      }

      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Premium features provider
final premiumFeaturesProvider = Provider((ref) {
  final paywallService = PaywallService();
  return paywallService.getAllPremiumFeatures();
});

/// Feature availability provider
final featureAvailabilityProvider =
    Provider.family<bool, String>((ref, featureId) {
  final paywallService = PaywallService();
  return paywallService.isFeatureAvailable(featureId);
});

/// Subscription price provider
final subscriptionPriceProvider =
    Provider.family<double, (SubscriptionType, SubscriptionPeriod)>(
        (ref, params) {
  final paywallService = PaywallService();
  return paywallService.getPrice(params.$1, params.$2);
});

/// Features for tier provider
final featuresForTierProvider =
    Provider.family<List<PremiumFeature>, SubscriptionType>((ref, tier) {
  final paywallService = PaywallService();
  return paywallService.getFeaturesForTier(tier);
});

/// Is premium user provider
final isPremiumUserProvider = Provider((ref) {
  final subscription = ref.watch(currentSubscriptionProvider);
  return subscription.when(
    data: (sub) => sub?.isPremium ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Subscription status provider
final subscriptionStatusProvider = Provider((ref) {
  final subscription = ref.watch(currentSubscriptionProvider);
  return subscription.when(
    data: (sub) => sub?.status.toString().split('.').last ?? 'unknown',
    loading: () => 'loading',
    error: (_, __) => 'error',
  );
});
