import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_lesson_generation_service.dart';

// ========== Service Provider ==========

final aiLessonGenerationServiceProvider = Provider((ref) {
  return AILessonGenerationService.instance;
});

// ========== Game Analysis Providers ==========

/// Analyze single game with AI evaluation
final gameAnalysisProvider = FutureProvider.family<GameAnalysis, String>((ref, gameId) async {
  final service = ref.watch(aiLessonGenerationServiceProvider);
  return service.analyzeGame(gameId);
});

/// Get opening recommendations based on play style
final openingRecommendationsProvider = FutureProvider<List<AIOpeningRecommendation>>((ref) async {
  final service = ref.watch(aiLessonGenerationServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  
  if (userId == null) return [];
  
  return service.generateOpeningRecommendations(userId);
});

/// Get personalized improvement path
final improvementPathProvider = FutureProvider<ImprovementPath>((ref) async {
  final service = ref.watch(aiLessonGenerationServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  
  if (userId == null) throw Exception('Not authenticated');
  
  return service.generateImprovementPath(userId);
});

// ========== AI Lesson Providers ==========

/// Get AI-generated lessons by type and difficulty
final aiGeneratedLessonsProvider = FutureProvider.family<
  List<AIGeneratedLesson>,
  (String, int)
>((ref, args) async {
  final service = ref.watch(aiLessonGenerationServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  
  if (userId == null) return [];
  
  return service.getAIGeneratedLessons(userId, args.$1, args.$2);
});

/// Get comprehensive player profile
final playerProfileProvider = FutureProvider<PlayerProfile>((ref) async {
  final service = ref.watch(aiLessonGenerationServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  
  if (userId == null) throw Exception('Not authenticated');
  
  return service.generatePlayerProfile(userId);
});

/// Get endgame-specific insights
final endgameInsightsProvider = FutureProvider<List<EndgameInsight>>((ref) async {
  final service = ref.watch(aiLessonGenerationServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  
  if (userId == null) return [];
  
  return service.analyzeEndgameWeaknesses(userId);
});

/// Get recent AI insights
final recentAIInsightsProvider = FutureProvider<List<AIInsight>>((ref) async {
  final service = ref.watch(aiLessonGenerationServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  
  if (userId == null) return [];
  
  return service.getRecentInsights(userId);
});

// ========== Analytics Providers ==========

/// Get performance progress analytics
final performanceProgressProvider = FutureProvider.family<
  PerformanceProgressAnalytics,
  Duration
>((ref, period) async {
  final service = ref.watch(aiLessonGenerationServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;
  
  if (userId == null) throw Exception('Not authenticated');
  
  return service.getPerformanceProgressAnalytics(userId, period);
});

/// Get 30-day performance analytics
final monthlyPerformanceProvider = FutureProvider<PerformanceProgressAnalytics>((ref) async {
  return ref.watch(performanceProgressProvider(const Duration(days: 30)).future);
});

// ========== State Management Providers ==========

/// Track active game analysis
final activeGameAnalysisProvider = StateProvider<String?>((ref) {
  return null;
});

/// Track lesson recommendations interaction
final lessonInteractionProvider = StateNotifierProvider<
  LessonInteractionNotifier,
  LessonInteractionState
>((ref) {
  return LessonInteractionNotifier();
});

/// Track viewed insights
final viewedInsightsProvider = StateProvider<Set<String>>((ref) {
  return {};
});

// ========== Computed Providers ==========

/// Check if player profile is available
final hasPlayerProfileProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(playerProfileProvider.future);
  return profile.totalGamesAnalyzed > 0;
});

/// Get player's play style
final playStyleProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(playerProfileProvider.future);
  return profile.playStyle;
});

/// Get recommended focus areas
final recommendedFocusProvider = FutureProvider<List<String>>((ref) async {
  final profile = await ref.watch(playerProfileProvider.future);
  return profile.recommendedFocus;
});

/// Get strength metrics summary
final strengthMetricsSummaryProvider = FutureProvider<StrengthMetricsSummary>((ref) async {
  final profile = await ref.watch(playerProfileProvider.future);
  
  return StrengthMetricsSummary(
    tacticalStrength: profile.tacticalStrength,
    strategicStrength: profile.strategicStrength,
    endgameStrength: profile.endgameStrength,
    averageAccuracy: profile.averageAccuracy,
    playStyle: profile.playStyle,
  );
});

/// Get improvement priority ranking
final improvementPriorityProvider = FutureProvider<List<String>>((ref) async {
  final path = await ref.watch(improvementPathProvider.future);
  return path.priorityAreas;
});

/// Get estimated rating gain
final estimatedRatingGainProvider = FutureProvider<double>((ref) async {
  final path = await ref.watch(improvementPathProvider.future);
  return path.expectedRatingGain;
});

/// Get AI insights count
final aiInsightsCountProvider = FutureProvider<int>((ref) async {
  final insights = await ref.watch(recentAIInsightsProvider.future);
  return insights.length;
});

/// Filter unread AI insights
final unreadInsightsProvider = FutureProvider<List<AIInsight>>((ref) async {
  final insights = await ref.watch(recentAIInsightsProvider.future);
  return insights.where((i) => !i.isRead).toList();
});

// ========== Notifiers & State Classes ==========

class LessonInteractionNotifier extends StateNotifier<LessonInteractionState> {
  LessonInteractionNotifier() : super(LessonInteractionState());

  void acceptLesson(String lessonId) {
    state = state.copyWith(
      acceptedLessons: {...state.acceptedLessons, lessonId},
    );
  }

  void declineLesson(String lessonId) {
    state = state.copyWith(
      declinedLessons: {...state.declinedLessons, lessonId},
    );
  }

  void rateLessonUsefulness(String lessonId, int rating) {
    state = state.copyWith(
      lessonRatings: {...state.lessonRatings, lessonId: rating},
    );
  }

  void clearInteractions() {
    state = LessonInteractionState();
  }
}

class LessonInteractionState {
  final Set<String> acceptedLessons;
  final Set<String> declinedLessons;
  final Map<String, int> lessonRatings;

  LessonInteractionState({
    this.acceptedLessons = const {},
    this.declinedLessons = const {},
    this.lessonRatings = const {},
  });

  LessonInteractionState copyWith({
    Set<String>? acceptedLessons,
    Set<String>? declinedLessons,
    Map<String, int>? lessonRatings,
  }) {
    return LessonInteractionState(
      acceptedLessons: acceptedLessons ?? this.acceptedLessons,
      declinedLessons: declinedLessons ?? this.declinedLessons,
      lessonRatings: lessonRatings ?? this.lessonRatings,
    );
  }
}

// ========== Helper Classes ==========

class StrengthMetricsSummary {
  final double tacticalStrength;
  final double strategicStrength;
  final double endgameStrength;
  final double averageAccuracy;
  final String playStyle;

  StrengthMetricsSummary({
    required this.tacticalStrength,
    required this.strategicStrength,
    required this.endgameStrength,
    required this.averageAccuracy,
    required this.playStyle,
  });

  double get overallStrength =>
      (tacticalStrength + strategicStrength + endgameStrength) / 3;
}
