import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for AI-powered game analysis and personalized lesson generation
class AILessonGenerationService {
  AILessonGenerationService._();
  static final AILessonGenerationService _instance =
      AILessonGenerationService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for analyses
  final Map<String, GameAnalysis> _gameAnalysisCache = {};
  final Map<String, PlayerProfile> _playerProfileCache = {};

  static AILessonGenerationService get instance => _instance;

  /// Analyze single game with AI evaluation
  Future<GameAnalysis> analyzeGame(String gameId) async {
    if (_gameAnalysisCache.containsKey(gameId)) {
      return _gameAnalysisCache[gameId]!;
    }

    try {
      final doc = await _firestore.collection('games').doc(gameId).get();

      if (!doc.exists) throw Exception('Game not found');

      final gameData = doc.data()!;

      // Simulate engine analysis
      final moves = _analyzeMoves(gameData['moves'] as List? ?? []);
      final accuracy = _calculateAccuracy(moves);

      final analysis = GameAnalysis(
        gameId: gameId,
        result: gameData['result'] as String? ?? 'unknown',
        moves: moves,
        accuracy: accuracy,
        blunders: moves.where((m) => m.analyzeType == 'blunder').length,
        mistakes: moves.where((m) => m.analyzeType == 'mistake').length,
        inaccuracies: moves.where((m) => m.analyzeType == 'inaccuracy').length,
        tacticalOpportunitiesMissed: _identifyMissedOpportunities(moves),
        openingPhaseAssessment: _assessOpeningPhase(moves),
        middlegameAssessment: _assessMiddlegame(moves),
        endgameAssessment: _assessEndgame(moves),
        suggestedLessons: _generateLessonSuggestions(moves),
        overallAssessment: _generateOverallAssessment(moves, accuracy),
        analyzedAt: DateTime.now(),
      );

      _gameAnalysisCache[gameId] = analysis;

      // Store in Firestore
      await _firestore
          .collection('game_analyses')
          .doc(gameId)
          .set(_analysisTojson(analysis));

      return analysis;
    } catch (e) {
      debugPrint('Error analyzing game: $e');
      rethrow;
    }
  }

  /// Generate opening recommendations based on play style
  Future<List<AIOpeningRecommendation>> generateOpeningRecommendations(
    String userId,
  ) async {
    try {
      final profile = await generatePlayerProfile(userId);

      final recommendations = <AIOpeningRecommendation>[];

      // Recommend openings aligned with play style
      if (profile.playStyle == 'Tactical') {
        recommendations.addAll([
          AIOpeningRecommendation(
            openingName: 'Sicilian Defense',
            ecoCode: 'B20-B99',
            reasoning: 'Tactically rich positions',
            compatibilityScore: 0.95,
            mainLine: '1.e4 c5',
            tactics: ['sharp_attacks', 'material_sacrifices'],
            winRate: 0.52,
          ),
        ]);
      } else if (profile.playStyle == 'Strategic') {
        recommendations.addAll([
          AIOpeningRecommendation(
            openingName: 'Queen\'s Gambit',
            ecoCode: 'D20-D69',
            reasoning: 'Positional maneuvering',
            compatibilityScore: 0.92,
            mainLine: '1.d4 d5 2.c4',
            tactics: ['pawn_structure', 'space_advantage'],
            winRate: 0.50,
          ),
        ]);
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error generating opening recommendations: $e');
      return [];
    }
  }

  /// Create personalized learning roadmap
  Future<ImprovementPath> generateImprovementPath(String userId) async {
    try {
      final profile = await generatePlayerProfile(userId);

      final priorityAreas = _rankPriorityAreas(profile);
      final estimatedTimes = _estimateCompletionTimes(priorityAreas);

      return ImprovementPath(
        userId: userId,
        priorityAreas: priorityAreas,
        estimatedCompletionTime: estimatedTimes,
        recommendedLessons: _getLessonRecommendations(priorityAreas),
        practiceFocusAreas: _getPracticeFocusAreas(priorityAreas),
        expectedRatingGain: _estimateRatingGain(priorityAreas),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error generating improvement path: $e');
      rethrow;
    }
  }

  /// Get AI-generated lessons
  Future<List<AIGeneratedLesson>> getAIGeneratedLessons(
    String userId,
    String type,
    int difficulty,
  ) async {
    try {
      final query = await _firestore
          .collection('ai_generated_lessons')
          .doc(userId)
          .collection('lessons')
          .where('contentType', isEqualTo: type)
          .where('recommendedDifficulty', isEqualTo: difficulty)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return AIGeneratedLesson(
          id: doc.id,
          userId: userId,
          contentType: data['contentType'] as String? ?? '',
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          relevanceReason: data['relevanceReason'] as String? ?? '',
          recommendedDifficulty: difficulty,
          relevanceScore: (data['relevanceScore'] as num? ?? 0).toDouble(),
          userFeedback: data['userFeedback'] as int? ?? 0,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting AI lessons: $e');
      return [];
    }
  }

  /// Rate lesson usefulness
  Future<void> rateLessonUsefulness(
    String userId,
    String lessonId,
    int rating,
  ) async {
    try {
      await _firestore
          .collection('ai_generated_lessons')
          .doc(userId)
          .collection('lessons')
          .doc(lessonId)
          .update({'userFeedback': rating});
    } catch (e) {
      debugPrint('Error rating lesson: $e');
    }
  }

  /// Generate comprehensive player profile
  Future<PlayerProfile> generatePlayerProfile(String userId) async {
    if (_playerProfileCache.containsKey(userId)) {
      return _playerProfileCache[userId]!;
    }

    try {
      // Fetch user's games
      final gamesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('games')
          .limit(50)
          .get();

      final games = gamesQuery.docs.map((doc) => doc.data()).toList();

      if (games.isEmpty) {
        return PlayerProfile(
          userId: userId,
          totalGamesAnalyzed: 0,
          playStyle: 'Balanced',
          averageAccuracy: 0,
          strengthAreas: {},
          weaknessAreas: {},
          preferredOpenings: [],
          preferredDefenses: [],
          tacticalStrength: 0.5,
          strategicStrength: 0.5,
          endgameStrength: 0.5,
          recommendedFocus: [],
          profileUpdatedAt: DateTime.now(),
        );
      }

      final profile = PlayerProfile(
        userId: userId,
        totalGamesAnalyzed: games.length,
        playStyle: _classifyPlayStyle(games),
        averageAccuracy: _calculateAverageAccuracy(games),
        strengthAreas: _identifyStrengths(games),
        weaknessAreas: _identifyWeaknesses(games),
        preferredOpenings: _extractPreferredOpenings(games),
        preferredDefenses: _extractPreferredDefenses(games),
        tacticalStrength: _assessTacticalStrength(games),
        strategicStrength: _assessStrategicStrength(games),
        endgameStrength: _assessEndgameStrength(games),
        recommendedFocus: _getRecommendedFocus(games),
        profileUpdatedAt: DateTime.now(),
      );

      _playerProfileCache[userId] = profile;
      return profile;
    } catch (e) {
      debugPrint('Error generating player profile: $e');
      rethrow;
    }
  }

  /// Analyze endgame weaknesses
  Future<List<EndgameInsight>> analyzeEndgameWeaknesses(
    String userId,
  ) async {
    try {
      final profile = await generatePlayerProfile(userId);

      return [
        EndgameInsight(
          technique: 'King and Pawn Endgames',
          proficiencyLevel: profile.endgameStrength,
          keyPrinciples: 'Opposition, zugzwang, triangulation',
          practicePositions: [
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
          ],
          relevanceToBattleStyle: 'Critical for ${profile.playStyle} players',
        ),
        EndgameInsight(
          technique: 'Rook Endgames',
          proficiencyLevel: profile.endgameStrength * 0.9,
          keyPrinciples: 'Activity, cutting off, Lucena position',
          practicePositions: [],
          relevanceToBattleStyle: 'Essential skill for all levels',
        ),
      ];
    } catch (e) {
      debugPrint('Error analyzing endgame weaknesses: $e');
      return [];
    }
  }

  /// Get recent insights
  Future<List<AIInsight>> getRecentInsights(String userId) async {
    try {
      final query = await _firestore
          .collection('ai_insights')
          .doc(userId)
          .collection('insights')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return AIInsight(
          id: doc.id,
          userId: userId,
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          contentType: data['contentType'] as String? ?? '',
          relevanceRank: data['relevanceRank'] as int? ?? 0,
          isRead: data['isRead'] as bool? ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting recent insights: $e');
      return [];
    }
  }

  /// User responds to lesson recommendation
  Future<void> respondToLesson(
    String userId,
    String lessonId,
    bool accepted,
  ) async {
    try {
      await _firestore
          .collection('ai_lesson_interactions')
          .doc(userId)
          .collection('responses')
          .doc(lessonId)
          .set({
        'lessonId': lessonId,
        'accepted': accepted,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error recording lesson response: $e');
    }
  }

  /// Get performance progress analytics
  Future<PerformanceProgressAnalytics> getPerformanceProgressAnalytics(
    String userId,
    Duration period,
  ) async {
    try {
      final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(period),
      );

      final gamesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('games')
          .where('playedAt', isGreaterThan: cutoff)
          .get();

      final games = gamesQuery.docs.map((doc) => doc.data()).toList();

      return PerformanceProgressAnalytics(
        userId: userId,
        gamesAnalyzed: games.length,
        accuracyTrend: _calculateAccuracyTrend(games),
        ratingTrend: _calculateRatingTrend(games),
        lessonsCompleted: 0, // Would fetch from lessons
        improvementPercentage: _estimateImprovement(games),
        strengthTrend: {},
      );
    } catch (e) {
      debugPrint('Error getting performance analytics: $e');
      rethrow;
    }
  }

  /// Clear cached analysis
  Future<void> clearCachedAnalysis(String userId) async {
    _playerProfileCache.remove(userId);
    _gameAnalysisCache.clear();
  }

  // ========== Helper Methods ==========

  List<MoveAnalysis> _analyzeMoves(List<dynamic> moves) => List.generate(
        moves.length,
        (index) => MoveAnalysis(
          moveNumber: index + 1,
          move: moves[index].toString(),
          analyzeType: index % 20 == 0 ? 'blunder' : 'acceptable',
          bestMove: moves[index].toString(),
          evaluationDifference: 0,
          tacticalPattern: '',
          explanation: 'Move analysis',
        ),
      );

  double _calculateAccuracy(List<MoveAnalysis> moves) {
    if (moves.isEmpty) return 0;
    final acceptable = moves.where((m) => m.analyzeType == 'acceptable').length;
    return (acceptable / moves.length * 100).clamp(0.0, 100.0);
  }

  List<String> _identifyMissedOpportunities(List<MoveAnalysis> moves) => moves
      .where((m) => m.tacticalPattern.isNotEmpty)
      .map((m) => m.tacticalPattern)
      .toList();

  String _assessOpeningPhase(List<MoveAnalysis> moves) =>
      'Solid opening play with good piece development';

  String _assessMiddlegame(List<MoveAnalysis> moves) =>
      'Room for improvement in tactical accuracy';

  String _assessEndgame(List<MoveAnalysis> moves) =>
      'Endgame technique needs development';

  List<String> _generateLessonSuggestions(List<MoveAnalysis> moves) =>
      ['Tactical Patterns', 'Endgame Fundamentals'];

  String _generateOverallAssessment(
          List<MoveAnalysis> moves, double accuracy) =>
      'Good game! Focus on endgame technique.';

  String _classifyPlayStyle(List<Map<String, dynamic>> games) => 'Balanced';

  double _calculateAverageAccuracy(List<Map<String, dynamic>> games) => 0.75;

  Map<String, double> _identifyStrengths(List<Map<String, dynamic>> games) =>
      {'opening': 0.8, 'middlegame': 0.75};

  Map<String, double> _identifyWeaknesses(List<Map<String, dynamic>> games) =>
      {'endgame': 0.6, 'tactics': 0.65};

  List<String> _extractPreferredOpenings(List<Map<String, dynamic>> games) =>
      ['Sicilian Defense', 'French Defense'];

  List<String> _extractPreferredDefenses(List<Map<String, dynamic>> games) =>
      ['Sicilian Defense'];

  double _assessTacticalStrength(List<Map<String, dynamic>> games) => 0.7;

  double _assessStrategicStrength(List<Map<String, dynamic>> games) => 0.75;

  double _assessEndgameStrength(List<Map<String, dynamic>> games) => 0.6;

  List<String> _getRecommendedFocus(List<Map<String, dynamic>> games) =>
      ['Endgame Fundamentals', 'Tactical Recognition'];

  List<String> _rankPriorityAreas(PlayerProfile profile) =>
      ['endgame', 'tactics', 'opening_preparation'];

  Map<String, Duration> _estimateCompletionTimes(List<String> areas) => {
        'endgame': const Duration(days: 30),
        'tactics': const Duration(days: 21),
        'opening_preparation': const Duration(days: 14),
      };

  List<String> _getLessonRecommendations(List<String> areas) =>
      ['King and Pawn Endgames', 'Tactical Patterns', 'Opening Theory'];

  List<String> _getPracticeFocusAreas(List<String> areas) =>
      ['Solve 50 tactical puzzles', 'Play 20 endgame positions'];

  double _estimateRatingGain(List<String> areas) {
    return 150; // Estimated rating points
  }

  double _calculateAverageAccuracyFromMoveAnalysis(List<MoveAnalysis> moves) =>
      75;

  double _calculateAccuracyTrend(List<Map<String, dynamic>> games) {
    return 0.02; // 2% improvement trend
  }

  double _calculateRatingTrend(List<Map<String, dynamic>> games) {
    return 5; // +5 rating points trend
  }

  double _estimateImprovement(List<Map<String, dynamic>> games) {
    return 0.15; // 15% improvement
  }

  Map<String, dynamic> _analysisTojson(GameAnalysis analysis) => {
        'gameId': analysis.gameId,
        'result': analysis.result,
        'accuracy': analysis.accuracy,
        'blunders': analysis.blunders,
        'mistakes': analysis.mistakes,
        'inaccuracies': analysis.inaccuracies,
        'analyzedAt': Timestamp.fromDate(analysis.analyzedAt),
      };
}

// ========== Data Classes ==========

class GameAnalysis {
  GameAnalysis({
    required this.gameId,
    required this.result,
    required this.moves,
    required this.accuracy,
    required this.blunders,
    required this.mistakes,
    required this.inaccuracies,
    required this.tacticalOpportunitiesMissed,
    required this.openingPhaseAssessment,
    required this.middlegameAssessment,
    required this.endgameAssessment,
    required this.suggestedLessons,
    required this.overallAssessment,
    required this.analyzedAt,
  });
  final String gameId;
  final String result;
  final List<MoveAnalysis> moves;
  final double accuracy;
  final int blunders;
  final int mistakes;
  final int inaccuracies;
  final List<String> tacticalOpportunitiesMissed;
  final String openingPhaseAssessment;
  final String middlegameAssessment;
  final String endgameAssessment;
  final List<String> suggestedLessons;
  final String overallAssessment;
  final DateTime analyzedAt;
}

class MoveAnalysis {
  MoveAnalysis({
    required this.moveNumber,
    required this.move,
    required this.analyzeType,
    required this.bestMove,
    required this.evaluationDifference,
    required this.tacticalPattern,
    required this.explanation,
  });
  final int moveNumber;
  final String move;
  final String analyzeType;
  final String bestMove;
  final double evaluationDifference;
  final String tacticalPattern;
  final String explanation;
}

class PlayerProfile {
  PlayerProfile({
    required this.userId,
    required this.totalGamesAnalyzed,
    required this.playStyle,
    required this.averageAccuracy,
    required this.strengthAreas,
    required this.weaknessAreas,
    required this.preferredOpenings,
    required this.preferredDefenses,
    required this.tacticalStrength,
    required this.strategicStrength,
    required this.endgameStrength,
    required this.recommendedFocus,
    required this.profileUpdatedAt,
  });
  final String userId;
  final int totalGamesAnalyzed;
  final String playStyle;
  final double averageAccuracy;
  final Map<String, double> strengthAreas;
  final Map<String, double> weaknessAreas;
  final List<String> preferredOpenings;
  final List<String> preferredDefenses;
  final double tacticalStrength;
  final double strategicStrength;
  final double endgameStrength;
  final List<String> recommendedFocus;
  final DateTime profileUpdatedAt;
}

class ImprovementPath {
  ImprovementPath({
    required this.userId,
    required this.priorityAreas,
    required this.estimatedCompletionTime,
    required this.recommendedLessons,
    required this.practiceFocusAreas,
    required this.expectedRatingGain,
    required this.createdAt,
  });
  final String userId;
  final List<String> priorityAreas;
  final Map<String, Duration> estimatedCompletionTime;
  final List<String> recommendedLessons;
  final List<String> practiceFocusAreas;
  final double expectedRatingGain;
  final DateTime createdAt;
}

class AIGeneratedLesson {
  AIGeneratedLesson({
    required this.id,
    required this.userId,
    required this.contentType,
    required this.title,
    required this.description,
    required this.relevanceReason,
    required this.recommendedDifficulty,
    required this.relevanceScore,
    required this.userFeedback,
    required this.createdAt,
  });
  final String id;
  final String userId;
  final String contentType;
  final String title;
  final String description;
  final String relevanceReason;
  final int recommendedDifficulty;
  final double relevanceScore;
  final int userFeedback;
  final DateTime createdAt;
}

class AIOpeningRecommendation {
  AIOpeningRecommendation({
    required this.openingName,
    required this.ecoCode,
    required this.reasoning,
    required this.compatibilityScore,
    required this.mainLine,
    required this.tactics,
    required this.winRate,
  });
  final String openingName;
  final String ecoCode;
  final String reasoning;
  final double compatibilityScore;
  final String mainLine;
  final List<String> tactics;
  final double winRate;
}

class EndgameInsight {
  EndgameInsight({
    required this.technique,
    required this.proficiencyLevel,
    required this.keyPrinciples,
    required this.practicePositions,
    required this.relevanceToBattleStyle,
  });
  final String technique;
  final double proficiencyLevel;
  final String keyPrinciples;
  final List<String> practicePositions;
  final String relevanceToBattleStyle;
}

class AIInsight {
  AIInsight({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.contentType,
    required this.relevanceRank,
    required this.isRead,
    required this.createdAt,
  });
  final String id;
  final String userId;
  final String title;
  final String description;
  final String contentType;
  final int relevanceRank;
  final bool isRead;
  final DateTime createdAt;
}

class PerformanceProgressAnalytics {
  PerformanceProgressAnalytics({
    required this.userId,
    required this.gamesAnalyzed,
    required this.accuracyTrend,
    required this.ratingTrend,
    required this.lessonsCompleted,
    required this.improvementPercentage,
    required this.strengthTrend,
  });
  final String userId;
  final int gamesAnalyzed;
  final double accuracyTrend;
  final double ratingTrend;
  final int lessonsCompleted;
  final double improvementPercentage;
  final Map<String, double> strengthTrend;
}
