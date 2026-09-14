import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for managing chess lessons, openings, tactics, and strategy content
class ChessLessonsService {
  static final ChessLessonsService _instance = ChessLessonsService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for lessons
  final Map<String, ChessLesson> _lessonCache = {};
  final Map<String, OpeningExplanation> _openingCache = {};

  ChessLessonsService._();

  static ChessLessonsService get instance => _instance;

  /// Get lessons filtered by type and difficulty
  Future<List<ChessLesson>> getLessonsByType(String type, int difficulty) async {
    try {
      final query = await _firestore
          .collection('chess_lessons')
          .doc(type)
          .collection('lessons')
          .where('difficulty', isEqualTo: difficulty)
          .limit(20)
          .get();

      return query.docs
          .map((doc) => _parseChessLesson(doc.data(), type))
          .toList();
    } catch (e) {
      debugPrint('Error getting lessons by type: $e');
      return [];
    }
  }

  /// Get specific opening by ECO code
  Future<OpeningExplanation?> getOpeningByEco(String ecoCode) async {
    if (_openingCache.containsKey(ecoCode)) {
      return _openingCache[ecoCode];
    }

    try {
      final doc = await _firestore
          .collection('chess_lessons')
          .doc('openings')
          .collection('by_eco')
          .doc(ecoCode)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final opening = OpeningExplanation(
        id: doc.id,
        title: data['name'] as String? ?? '',
        description: data['strategicIdeas'] as String? ?? '',
        contentType: 'opening',
        difficulty: data['difficulty'] as int? ?? 1,
        pgn: data['mainLines'] != null ? (data['mainLines'] as List).first : '',
        keyPoints: List<String>.from(data['typicalPlans'] as List? ?? []),
        commonMistakes: [],
        prerequisites: '',
        relatedTopics: [],
        estimatedDuration: const Duration(minutes: 15),
        statistics: data['statistics'] as Map<String, dynamic>? ?? {},
        ecoCode: ecoCode,
        mainLines: List<String>.from(data['mainLines'] as List? ?? []),
        alternativeLines: List<String>.from(data['alternatives'] as List? ?? []),
        winRates: _parseWinRates(data['statistics'] as Map<String, dynamic>? ?? {}),
        typicalPlans: List<String>.from(data['typicalPlans'] as List? ?? []),
        historicalNotes: List<String>.from(data['historicalNotes'] as List? ?? []),
        totalGames: data['totalGames'] as int? ?? 0,
      );

      _openingCache[ecoCode] = opening;
      return opening;
    } catch (e) {
      debugPrint('Error getting opening by ECO: $e');
      return null;
    }
  }

  /// Get tactical patterns by difficulty level
  Future<List<TacticsPattern>> getTacticsByDifficulty(int difficulty) async {
    try {
      final query = await _firestore
          .collection('chess_lessons')
          .doc('tactics')
          .collection('patterns')
          .where('difficulty', isEqualTo: difficulty)
          .limit(20)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return TacticsPattern(
          id: doc.id,
          title: data['name'] as String? ?? '',
          description: data['description'] as String? ?? '',
          contentType: 'tactics',
          difficulty: difficulty,
          pgn: '',
          keyPoints: List<String>.from(data['motifs'] as List? ?? []),
          commonMistakes: [],
          prerequisites: '',
          relatedTopics: List<String>.from(data['relatedPatterns'] as List? ?? []),
          estimatedDuration: const Duration(minutes: 10),
          statistics: {},
          motifs: List<String>.from(data['motifs'] as List? ?? []),
          executionSteps: data['executionSteps'] as String? ?? '',
          examples: List<String>.from(data['examples'] as List? ?? []),
          frequency: data['frequency'] as int? ?? 0,
          complexity: (data['complexity'] as num? ?? 0).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting tactics by difficulty: $e');
      return [];
    }
  }

  /// Start tracking user's lesson progress
  Future<UserLessonProgress> startLesson(String userId, String lessonId) async {
    try {
      final progress = UserLessonProgress(
        userId: userId,
        lessonId: lessonId,
        status: 'in_progress',
        percentageComplete: 0.0,
        timesReviewed: 0,
        lastAccessed: DateTime.now(),
        selfAssessmentScore: 0,
        userNotes: [],
        totalTimeSpent: Duration.zero,
      );

      await _firestore
          .collection('chess_lessons')
          .doc('user_progress')
          .collection(userId)
          .doc('lessons')
          .collection('data')
          .doc(lessonId)
          .set({
        'status': progress.status,
        'percentageComplete': progress.percentageComplete,
        'timesReviewed': progress.timesReviewed,
        'lastAccessed': Timestamp.fromDate(progress.lastAccessed),
        'selfAssessmentScore': progress.selfAssessmentScore,
        'userNotes': progress.userNotes,
        'totalTimeSpent': progress.totalTimeSpent.inMilliseconds,
      });

      return progress;
    } catch (e) {
      debugPrint('Error starting lesson: $e');
      return UserLessonProgress(
        userId: userId,
        lessonId: lessonId,
        status: 'error',
        percentageComplete: 0.0,
        timesReviewed: 0,
        lastAccessed: DateTime.now(),
        selfAssessmentScore: 0,
        userNotes: [],
        totalTimeSpent: Duration.zero,
      );
    }
  }

  /// Update lesson progress
  Future<void> updateLessonProgress(
    String userId,
    String lessonId,
    double percentageComplete,
  ) async {
    try {
      await _firestore
          .collection('chess_lessons')
          .doc('user_progress')
          .collection(userId)
          .doc('lessons')
          .collection('data')
          .doc(lessonId)
          .update({
        'percentageComplete': percentageComplete,
        'lastAccessed': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating lesson progress: $e');
    }
  }

  /// Get user's complete progress history
  Future<List<UserLessonProgress>> getUserProgress(String userId) async {
    try {
      final query = await _firestore
          .collection('chess_lessons')
          .doc('user_progress')
          .collection(userId)
          .doc('lessons')
          .collection('data')
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return UserLessonProgress(
          userId: userId,
          lessonId: doc.id,
          status: data['status'] as String? ?? 'not_started',
          percentageComplete: (data['percentageComplete'] as num? ?? 0).toDouble(),
          timesReviewed: data['timesReviewed'] as int? ?? 0,
          lastAccessed: (data['lastAccessed'] as Timestamp?)?.toDate() ?? DateTime.now(),
          selfAssessmentScore: data['selfAssessmentScore'] as int? ?? 0,
          userNotes: List<String>.from(data['userNotes'] as List? ?? []),
          totalTimeSpent: Duration(
            milliseconds: data['totalTimeSpent'] as int? ?? 0,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      return [];
    }
  }

  /// Get recommended lessons for user
  Future<List<ChessLesson>> getRecommendedLessons(
    String userId,
    int limit,
  ) async {
    try {
      // Get user's current level
      final stats = await getLearningStats(userId);

      // Recommend lessons at next difficulty level
      final recommendedDifficulty = (stats.averageDifficulty + 1).ceil().clamp(1, 5);

      final query = await _firestore
          .collection('chess_lessons')
          .doc('recommendations')
          .collection(userId)
          .where('difficulty', isEqualTo: recommendedDifficulty)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => _parseChessLesson(doc.data(), doc['type']))
          .toList();
    } catch (e) {
      debugPrint('Error getting recommended lessons: $e');
      return [];
    }
  }

  /// Get user's learning statistics
  Future<LearningStatistics> getLearningStats(String userId) async {
    try {
      final doc = await _firestore
          .collection('chess_lessons')
          .doc('user_progress')
          .collection(userId)
          .doc('statistics')
          .get();

      if (!doc.exists) {
        return LearningStatistics(
          lessonsStarted: 0,
          lessonsCompleted: 0,
          totalLessonsReviewed: 0,
          totalTimeSpent: Duration.zero,
          currentStreak: 0,
          averageDifficulty: 1.0,
          topicsMastered: [],
          topicsToImprove: [],
          overallProgress: 0.0,
        );
      }

      final data = doc.data() as Map<String, dynamic>;

      return LearningStatistics(
        lessonsStarted: data['lessonsStarted'] as int? ?? 0,
        lessonsCompleted: data['lessonsCompleted'] as int? ?? 0,
        totalLessonsReviewed: data['totalLessonsReviewed'] as int? ?? 0,
        totalTimeSpent:
            Duration(milliseconds: data['totalTimeSpent'] as int? ?? 0),
        currentStreak: data['currentStreak'] as int? ?? 0,
        averageDifficulty: (data['averageDifficulty'] as num? ?? 1.0).toDouble(),
        topicsMastered: List<String>.from(data['topicsMastered'] as List? ?? []),
        topicsToImprove: List<String>.from(data['topicsToImprove'] as List? ?? []),
        overallProgress:
            (data['overallProgress'] as num? ?? 0.0).toDouble(),
      );
    } catch (e) {
      debugPrint('Error getting learning stats: $e');
      return LearningStatistics(
        lessonsStarted: 0,
        lessonsCompleted: 0,
        totalLessonsReviewed: 0,
        totalTimeSpent: Duration.zero,
        currentStreak: 0,
        averageDifficulty: 1.0,
        topicsMastered: [],
        topicsToImprove: [],
        overallProgress: 0.0,
      );
    }
  }

  /// Complete lesson and update statistics
  Future<void> completeLessonAsync(String userId, String lessonId) async {
    try {
      await _firestore
          .collection('chess_lessons')
          .doc('user_progress')
          .collection(userId)
          .doc('lessons')
          .collection('data')
          .doc(lessonId)
          .update({
        'status': 'completed',
        'percentageComplete': 1.0,
      });

      // Update statistics
      await _updateStatistics(userId);
    } catch (e) {
      debugPrint('Error completing lesson: $e');
    }
  }

  /// Internal helper to parse ChessLesson from Firestore data
  ChessLesson _parseChessLesson(
    Map<String, dynamic> data,
    String type,
  ) {
    return ChessLesson(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      contentType: type,
      difficulty: data['difficulty'] as int? ?? 1,
      pgn: data['pgn'] as String? ?? '',
      keyPoints: List<String>.from(data['keyPoints'] as List? ?? []),
      commonMistakes: List<String>.from(data['commonMistakes'] as List? ?? []),
      prerequisites: data['prerequisites'] as String? ?? '',
      relatedTopics: List<String>.from(data['relatedTopics'] as List? ?? []),
      estimatedDuration: Duration(
        minutes: data['estimatedDuration'] as int? ?? 15,
      ),
      statistics: data['statistics'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Parse win rates from statistics
  Map<String, double> _parseWinRates(Map<String, dynamic> stats) {
    return {
      'white': (stats['whiteWinRate'] as num? ?? 0).toDouble(),
      'black': (stats['blackWinRate'] as num? ?? 0).toDouble(),
      'draws': (stats['drawRate'] as num? ?? 0).toDouble(),
    };
  }

  /// Update user statistics after lesson completion
  Future<void> _updateStatistics(String userId) async {
    try {
      final progress = await getUserProgress(userId);

      final completed =
          progress.where((p) => p.status == 'completed').length;
      final started = progress.where((p) => p.status != 'not_started').length;

      double avgDifficulty = 0;
      if (started > 0) {
        final difficulties = progress
            .map((p) => _getDifficultyFromLesson(p.lessonId))
            .toList();
        avgDifficulty = difficulties.reduce((a, b) => a + b) / difficulties.length;
      }

      final totalTime = progress.fold<int>(
        0,
        (sum, p) => sum + p.totalTimeSpent.inMilliseconds,
      );

      await _firestore
          .collection('chess_lessons')
          .doc('user_progress')
          .collection(userId)
          .doc('statistics')
          .set({
        'lessonsStarted': started,
        'lessonsCompleted': completed,
        'totalLessonsReviewed':
            progress.fold(0, (sum, p) => sum + (p.timesReviewed as int)),
        'totalTimeSpent': totalTime,
        'currentStreak': _calculateStreak(progress),
        'averageDifficulty': avgDifficulty,
        'topicsMastered': _getTopicsMastered(progress),
        'topicsToImprove': _getTopicsToImprove(progress),
        'overallProgress': completed / (started > 0 ? started : 1),
      });
    } catch (e) {
      debugPrint('Error updating statistics: $e');
    }
  }

  /// Get difficulty from lesson ID
  double _getDifficultyFromLesson(String lessonId) {
    // Simplified - would fetch from lesson data
    return 1.0;
  }

  /// Calculate current learning streak
  int _calculateStreak(List<UserLessonProgress> progress) {
    // Simplified calculation
    if (progress.isEmpty) return 0;

    progress.sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));

    int streak = 0;
    final now = DateTime.now();

    for (final lesson in progress) {
      final daysDiff = now.difference(lesson.lastAccessed).inDays;
      if (daysDiff <= streak + 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get topics user has mastered
  List<String> _getTopicsMastered(List<UserLessonProgress> progress) {
    return progress
        .where((p) => p.status == 'reviewed' && p.selfAssessmentScore >= 4)
        .map((p) => _getTopicFromLesson(p.lessonId))
        .toSet()
        .toList();
  }

  /// Get topics needing improvement
  List<String> _getTopicsToImprove(List<UserLessonProgress> progress) {
    return progress
        .where((p) => p.percentageComplete < 0.5)
        .map((p) => _getTopicFromLesson(p.lessonId))
        .toSet()
        .toList();
  }

  /// Get topic from lesson ID
  String _getTopicFromLesson(String lessonId) {
    // Simplified - would fetch from lesson data
    return 'strategy';
  }
}

/// ChessLesson base class
class ChessLesson {
  final String id;
  final String title;
  final String description;
  final String contentType;
  final int difficulty;
  final String pgn;
  final List<String> keyPoints;
  final List<String> commonMistakes;
  final String prerequisites;
  final List<String> relatedTopics;
  final Duration estimatedDuration;
  final Map<String, dynamic> statistics;

  ChessLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.difficulty,
    required this.pgn,
    required this.keyPoints,
    required this.commonMistakes,
    required this.prerequisites,
    required this.relatedTopics,
    required this.estimatedDuration,
    required this.statistics,
  });
}

/// OpeningExplanation extends ChessLesson
class OpeningExplanation extends ChessLesson {
  final String ecoCode;
  final List<String> mainLines;
  final List<String> alternativeLines;
  final Map<String, double> winRates;
  final List<String> typicalPlans;
  final List<String> historicalNotes;
  final int totalGames;

  OpeningExplanation({
    required String id,
    required String title,
    required String description,
    required int difficulty,
    required String pgn,
    required List<String> keyPoints,
    required List<String> commonMistakes,
    required String prerequisites,
    required List<String> relatedTopics,
    required Duration estimatedDuration,
    required Map<String, dynamic> statistics,
    required this.ecoCode,
    required this.mainLines,
    required this.alternativeLines,
    required this.winRates,
    required this.typicalPlans,
    required this.historicalNotes,
    required this.totalGames,
  }) : super(
    id: id,
    title: title,
    description: description,
    contentType: 'opening',
    difficulty: difficulty,
    pgn: pgn,
    keyPoints: keyPoints,
    commonMistakes: commonMistakes,
    prerequisites: prerequisites,
    relatedTopics: relatedTopics,
    estimatedDuration: estimatedDuration,
    statistics: statistics,
  );
}

/// TacticsPattern extends ChessLesson
class TacticsPattern extends ChessLesson {
  final List<String> motifs;
  final String executionSteps;
  final List<String> examples;
  final int frequency;
  final double complexity;

  TacticsPattern({
    required String id,
    required String title,
    required String description,
    required int difficulty,
    required String pgn,
    required List<String> keyPoints,
    required List<String> commonMistakes,
    required String prerequisites,
    required List<String> relatedTopics,
    required Duration estimatedDuration,
    required Map<String, dynamic> statistics,
    required this.motifs,
    required this.executionSteps,
    required this.examples,
    required this.frequency,
    required this.complexity,
  }) : super(
    id: id,
    title: title,
    description: description,
    contentType: 'tactics',
    difficulty: difficulty,
    pgn: pgn,
    keyPoints: keyPoints,
    commonMistakes: commonMistakes,
    prerequisites: prerequisites,
    relatedTopics: relatedTopics,
    estimatedDuration: estimatedDuration,
    statistics: statistics,
  );
}

/// User's lesson progress tracking
class UserLessonProgress {
  final String userId;
  final String lessonId;
  final String status;
  final double percentageComplete;
  final int timesReviewed;
  final DateTime lastAccessed;
  final int selfAssessmentScore;
  final List<String> userNotes;
  final Duration totalTimeSpent;

  UserLessonProgress({
    required this.userId,
    required this.lessonId,
    required this.status,
    required this.percentageComplete,
    required this.timesReviewed,
    required this.lastAccessed,
    required this.selfAssessmentScore,
    required this.userNotes,
    required this.totalTimeSpent,
  });
}

/// Learning statistics for user
class LearningStatistics {
  final int lessonsStarted;
  final int lessonsCompleted;
  final int totalLessonsReviewed;
  final Duration totalTimeSpent;
  final int currentStreak;
  final double averageDifficulty;
  final List<String> topicsMastered;
  final List<String> topicsToImprove;
  final double overallProgress;

  LearningStatistics({
    required this.lessonsStarted,
    required this.lessonsCompleted,
    required this.totalLessonsReviewed,
    required this.totalTimeSpent,
    required this.currentStreak,
    required this.averageDifficulty,
    required this.topicsMastered,
    required this.topicsToImprove,
    required this.overallProgress,
  });
}
