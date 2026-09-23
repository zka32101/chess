import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chess_lessons_service.dart';

// ========== Service Provider ==========

final chessLessonsServiceProvider =
    Provider((ref) => ChessLessonsService.instance);

// ========== Lesson Query Providers ==========

/// Get all lessons by type and difficulty
final lessonsByTypeProvider =
    FutureProvider.family<List<ChessLesson>, (String, int)>((ref, args) async {
  final service = ref.watch(chessLessonsServiceProvider);
  return service.getLessonsByType(args.$1, args.$2);
});

/// Get opening lessons by difficulty
final openingLessonsProvider =
    FutureProvider.family<List<ChessLesson>, int>((ref, difficulty) async {
  final service = ref.watch(chessLessonsServiceProvider);
  return service.getLessonsByType('opening', difficulty);
});

/// Get all openings (aggregated across difficulties)
final allOpeningsProvider = FutureProvider<List<ChessLesson>>((ref) async {
  final service = ref.watch(chessLessonsServiceProvider);
  final results = <ChessLesson>[];

  for (int difficulty = 1; difficulty <= 5; difficulty++) {
    final lessons = await service.getLessonsByType('opening', difficulty);
    results.addAll(lessons);
  }

  return results;
});

/// Get tactic lessons by difficulty
final tacticLessonsProvider =
    FutureProvider.family<List<ChessLesson>, int>((ref, difficulty) async {
  final service = ref.watch(chessLessonsServiceProvider);
  return service.getLessonsByType('tactics', difficulty);
});

/// Get all tactics patterns
final allTacticsProvider = FutureProvider<List<ChessLesson>>((ref) async {
  final service = ref.watch(chessLessonsServiceProvider);
  final results = <ChessLesson>[];

  for (int difficulty = 1; difficulty <= 5; difficulty++) {
    final lessons = await service.getLessonsByType('tactics', difficulty);
    results.addAll(lessons);
  }

  return results;
});

/// Get strategy lessons (all difficulties)
final strategyLessonsProvider = FutureProvider<List<ChessLesson>>((ref) async {
  final service = ref.watch(chessLessonsServiceProvider);
  return service.getLessonsByType('strategy', 0);
});

/// Get specific opening by ECO code
final openingByEcoProvider =
    FutureProvider.family<OpeningExplanation?, String>((ref, ecoCode) async {
  final service = ref.watch(chessLessonsServiceProvider);
  return service.getOpeningByEco(ecoCode);
});

/// Get tactics patterns by difficulty
final tacticsByDifficultyProvider =
    FutureProvider.family<List<TacticsPattern>, int>((ref, difficulty) async {
  final service = ref.watch(chessLessonsServiceProvider);
  return service.getTacticsByDifficulty(difficulty);
});

/// Get recommended lessons for current user
final recommendedLessonsProvider =
    FutureProvider<List<ChessLesson>>((ref) async {
  final service = ref.watch(chessLessonsServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) return [];

  return service.getRecommendedLessons(userId, 10);
});

// ========== Progress Tracking Providers ==========

/// Get user's complete lesson progress
final userLessonProgressProvider =
    FutureProvider<List<UserLessonProgress>>((ref) async {
  final service = ref.watch(chessLessonsServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) return [];

  return service.getUserProgress(userId);
});

/// Get progress for specific lesson
final lessonProgressProvider =
    FutureProvider.family<UserLessonProgress?, String>((ref, lessonId) async {
  final progress = await ref.watch(userLessonProgressProvider.future);
  try {
    return progress.firstWhere((p) => p.lessonId == lessonId);
  } catch (e) {
    return null;
  }
});

/// Get user's learning statistics
final userLearningStatsProvider =
    FutureProvider<LearningStatistics>((ref) async {
  final service = ref.watch(chessLessonsServiceProvider);
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  if (userId == null) {
    return LearningStatistics(
      lessonsStarted: 0,
      lessonsCompleted: 0,
      totalLessonsReviewed: 0,
      totalTimeSpent: Duration.zero,
      currentStreak: 0,
      averageDifficulty: 0,
      topicsMastered: [],
      topicsToImprove: [],
      overallProgress: 0,
    );
  }

  return service.getLearningStats(userId);
});

// ========== State Management Providers ==========

/// Track currently active lesson
final activeLessonProvider = StateProvider<String?>((ref) => null);

/// Track lesson notes/annotations
final lessonNotesProvider =
    StateProvider.family<String, String>((ref, lessonId) => '');

/// Track self-assessment score for lesson
final selfAssessmentProvider =
    StateProvider.family<int, String>((ref, lessonId) => 0);

/// Track current lesson difficulty filter
final lessonDifficultyFilterProvider = StateProvider<int>((ref) => 1);

/// Track current lesson type filter
final lessonTypeFilterProvider = StateProvider<String>((ref) => 'opening');

// ========== Computed/Aggregated Providers ==========

/// Check if user has started a specific lesson
final hasStartedLessonProvider =
    FutureProvider.family<bool, String>((ref, lessonId) async {
  final progress = await ref.watch(lessonProgressProvider(lessonId).future);
  return progress != null && progress.status != 'not_started';
});

/// Get lessons completed count
final lessonsCompletedCountProvider = FutureProvider<int>((ref) async {
  final stats = await ref.watch(userLearningStatsProvider.future);
  return stats.lessonsCompleted;
});

/// Get current learning streak
final currentStreakProvider = FutureProvider<int>((ref) async {
  final stats = await ref.watch(userLearningStatsProvider.future);
  return stats.currentStreak;
});

/// Get topics mastered
final topicsMasteredProvider = FutureProvider<List<String>>((ref) async {
  final stats = await ref.watch(userLearningStatsProvider.future);
  return stats.topicsMastered;
});

/// Get topics needing improvement
final topicsToImproveProvider = FutureProvider<List<String>>((ref) async {
  final stats = await ref.watch(userLearningStatsProvider.future);
  return stats.topicsToImprove;
});

/// Get overall learning progress percentage
final overallProgressProvider = FutureProvider<double>((ref) async {
  final stats = await ref.watch(userLearningStatsProvider.future);
  return stats.overallProgress;
});

/// Filter lessons by active filters
final filteredLessonsProvider = FutureProvider<List<ChessLesson>>((ref) async {
  final type = ref.watch(lessonTypeFilterProvider);
  final difficulty = ref.watch(lessonDifficultyFilterProvider);

  return ref.watch(lessonsByTypeProvider((type, difficulty)).future);
});

/// Get statistics summary for dashboard
final lessonStatsSummaryProvider =
    FutureProvider<LessonStatsSummary>((ref) async {
  final stats = await ref.watch(userLearningStatsProvider.future);
  final progress = await ref.watch(userLessonProgressProvider.future);
  final completed = await ref.watch(lessonsCompletedCountProvider.future);

  return LessonStatsSummary(
    totalLessonsStarted: stats.lessonsStarted,
    totalLessonsCompleted: completed,
    currentStreak: stats.currentStreak,
    averageDifficulty: stats.averageDifficulty,
    overallProgress: stats.overallProgress,
    topicsMastered: stats.topicsMastered.length,
    topicsToImprove: stats.topicsToImprove.length,
    totalTimeSpent: stats.totalTimeSpent,
    nextRecommendedDifficulty: _getNextDifficulty(stats.averageDifficulty),
  );
});

// ========== Helper Functions ==========

int _getNextDifficulty(double currentDifficulty) =>
    (currentDifficulty + 1).ceil().clamp(1, 5);

// ========== Data Classes ==========

class LessonStatsSummary {
  LessonStatsSummary({
    required this.totalLessonsStarted,
    required this.totalLessonsCompleted,
    required this.currentStreak,
    required this.averageDifficulty,
    required this.overallProgress,
    required this.topicsMastered,
    required this.topicsToImprove,
    required this.totalTimeSpent,
    required this.nextRecommendedDifficulty,
  });
  final int totalLessonsStarted;
  final int totalLessonsCompleted;
  final int currentStreak;
  final double averageDifficulty;
  final double overallProgress;
  final int topicsMastered;
  final int topicsToImprove;
  final Duration totalTimeSpent;
  final int nextRecommendedDifficulty;
}
