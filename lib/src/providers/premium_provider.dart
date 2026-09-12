import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/paywall_service.dart';
import '../services/feature_gating_service.dart';

/// User subscription state
class UserSubscription {
  final String tier; // 'free', 'pro', 'premium'
  final DateTime? expiryDate;
  final bool isActive;

  UserSubscription({
    required this.tier,
    this.expiryDate,
    required this.isActive,
  });

  bool get isPro => tier == 'pro' && isActive;
  bool get isPremium => tier == 'premium' && isActive;
  bool get isFree => !isActive || tier == 'free';
}

// Get paywall service
final paywallServiceProvider = Provider((ref) {
  return PaywallService.instance;
});

// Get user's current subscription
final userSubscriptionProvider = FutureProvider<UserSubscription>((ref) async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final user = auth.currentUser;

  if (user == null) {
    return UserSubscription(tier: 'free', isActive: false);
  }

  try {
    final doc = await firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return UserSubscription(tier: 'free', isActive: false);
    }

    final data = doc.data() as Map<String, dynamic>;
    final tier = data['subscriptionTier'] as String? ?? 'free';
    final expiryTimestamp = data['subscriptionExpiry'] as Timestamp?;
    final expiryDate = expiryTimestamp?.toDate();

    final isActive = tier != 'free' && (expiryDate?.isAfter(DateTime.now()) ?? false);

    return UserSubscription(
      tier: tier,
      expiryDate: expiryDate,
      isActive: isActive,
    );
  } catch (e) {
    print('Error fetching subscription: $e');
    return UserSubscription(tier: 'free', isActive: false);
  }
});

// Check if specific premium feature is available
final premiumFeatureProvider = FutureProvider.family<bool, String>((ref, feature) async {
  final subscription = await ref.watch(userSubscriptionProvider.future);

  final premiumFeatures = {
    'unlimited_puzzles': subscription.isPro || subscription.isPremium,
    'unlimited_games': subscription.isPro || subscription.isPremium,
    'advanced_analysis': subscription.isPro || subscription.isPremium,
    'ai_lessons': subscription.isPremium,
    'personalized_training': subscription.isPremium,
    'offline_mode': subscription.isPremium,
    'priority_support': subscription.isPremium,
  };

  return premiumFeatures[feature] ?? false;
});

// Check if user can perform action with remaining attempts
final remainingAttemptsProvider = FutureProvider.family<int, String>((ref, action) async {
  final subscription = await ref.watch(userSubscriptionProvider.future);

  if (subscription.isPro || subscription.isPremium) {
    return 999; // Unlimited
  }

  // Free tier daily limits
  final limits = {
    'daily_puzzles': 3,
    'daily_games': 2,
  };

  return limits[action] ?? 0;
});

// Trigger paywall/subscription screen
final triggerPaywallProvider = StateProvider<String?>((ref) {
  return null; // Set to reason for showing paywall
});

// Feature gating service provider
final featureGatingServiceProvider = Provider((ref) {
  return FeatureGatingService.instance;
});

// Check if user can perform action (with daily limits)
final canPerformActionProvider = FutureProvider.family<bool, String>((ref, action) async {
  final subscription = await ref.watch(userSubscriptionProvider.future);
  final featureGatingService = ref.watch(featureGatingServiceProvider);

  return featureGatingService.canPerformAction(action, subscription.tier);
});

// Get remaining daily attempts (tracks usage)
final remainingDailyUsageProvider = FutureProvider.family<int, String>((ref, action) async {
  final subscription = await ref.watch(userSubscriptionProvider.future);
  final featureGatingService = ref.watch(featureGatingServiceProvider);

  return featureGatingService.getRemainingDailyAttempts(action, subscription.tier);
});

// Track action usage
final trackActionUsageProvider = FutureProvider.family<void, String>((ref, action) async {
  final subscription = await ref.watch(userSubscriptionProvider.future);
  final featureGatingService = ref.watch(featureGatingServiceProvider);

  await featureGatingService.trackActionUsage(action, subscription.tier);
});
