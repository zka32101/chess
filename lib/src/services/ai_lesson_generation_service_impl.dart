import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_lesson.dart';
import '../models/game.dart';

/// AI-powered game analysis and lesson generation.
///
/// This is a separate, richer implementation from
/// `ai_lesson_generation_service.dart` (which is the one actually wired up
/// via `phase_j_providers.dart`): the two were built against different data
/// models and are not interchangeable, so this class stands on its own
/// rather than implementing that unrelated service's interface.
class AILessonGenerationServiceImpl {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AILessonGenerationServiceImpl._();

  Future<GameAnalysis> analyzeGame(String userId, String gameId) async {
    try {
      // Fetch game from Firestore
      final gameDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('games')
          .doc(gameId)
          .get();

      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }

      final game = GameModel.fromJson(gameDoc.data() as Map<String, dynamic>);
      final pgn = game.pgn ?? '';

      // Analyze each move in the game
      final moveAnalyses = <MoveAnalysis>[];
      double totalAccuracy = 0.0;
      int blunders = 0, mistakes = 0, inaccuracies = 0, goodMoves = 0;
      final Set<String> openingsEncountered = {};
      final Set<String> tacticPatternsFound = {};
      final Set<String> weaknesses = {};

      // Parse PGN and analyze moves
      final moves = pgn.split(' ').where((m) => m.isNotEmpty).toList();

      for (int i = 0; i < moves.length; i++) {
        final move = moves[i];
        final analysisType = _classifyMove(move, i);
        final bestMove = _findBestMove(pgn, i);
        final explanation = _generateMoveExplanation(move, analysisType);
        final tacticPattern = _identifyTacticPattern(pgn, i);

        final evaluationDiff = _calculateEvaluationDifference(move, bestMove);

        moveAnalyses.add(
          MoveAnalysis(
            moveNumber: i + 1,
            move: move,
            currentFen: _calculateFenAtMove(pgn, i),
            analysisType: analysisType,
            evaluationDifference: evaluationDiff,
            bestMove: bestMove,
            explanation: explanation,
            tacticPattern: tacticPattern,
            isBlunder: analysisType == AnalysisType.blunder,
            isMistake: analysisType == AnalysisType.mistake,
            isInaccuracy: analysisType == AnalysisType.inaccuracy,
          ),
        );

        // Count errors
        if (analysisType == AnalysisType.blunder) blunders++;
        if (analysisType == AnalysisType.mistake) mistakes++;
        if (analysisType == AnalysisType.inaccuracy) inaccuracies++;
        if (analysisType == AnalysisType.goodMove) goodMoves++;

        // Track accuracy
        final accuracy = _calculateMoveAccuracy(analysisType);
        totalAccuracy += accuracy;

        // Identify tactics and openings
        if (tacticPattern.isNotEmpty) {
          tacticPatternsFound.add(tacticPattern);
        }
      }

      // Calculate overall accuracy
      final overallAccuracy =
          moveAnalyses.isNotEmpty ? totalAccuracy / moveAnalyses.length : 100.0;

      // Identify weaknesses
      if (blunders > 0) weaknesses.add('Blunder control');
      if (mistakes > moves.length * 0.3) weaknesses.add('Move accuracy');
      if (inaccuracies > moves.length * 0.5)
        weaknesses.add('Position evaluation');

      // Generate suggested lessons
      final suggestedLessons = await _generateSuggestedLessons(
        userId,
        moveAnalyses,
        tacticPatternsFound.toList(),
      );

      // Save analysis to Firestore
      final analysis = GameAnalysis(
        id: gameId,
        userId: userId,
        gameId: gameId,
        analysisDate: DateTime.now(),
        overallAccuracy: overallAccuracy,
        totalMoves: moves.length,
        blunders: blunders,
        mistakes: mistakes,
        inaccuracies: inaccuracies,
        goodMoves: goodMoves,
        moveAnalyses: moveAnalyses,
        identifiedWeaknesses: weaknesses.toList(),
        openingsPlayed: openingsEncountered.toList(),
        tacticPatternsEncountered: tacticPatternsFound.toList(),
        overallAssessment: _generateOverallAssessment(
          overallAccuracy,
          blunders,
          moves.length,
        ),
        suggestedLessons: suggestedLessons,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('game_analyses')
          .doc(gameId)
          .set(analysis.toJson());

      return analysis;
    } catch (e) {
      throw Exception('Error analyzing game: $e');
    }
  }

  Future<List<AIOpeningRecommendation>> generateOpeningRecommendations(
    String userId,
  ) async {
    try {
      // Get player profile to understand play style
      final profile = await generatePlayerProfile(userId);

      // Get user's skill level from lesson progress
      final userProgressSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .get();

      RecommendationLevel skillLevel = RecommendationLevel.beginner;
      if (userProgressSnapshot.docs.isNotEmpty) {
        final completedLessons =
            userProgressSnapshot.docs.where((d) => d['status'] == 'completed');
        if (completedLessons.length > 20) {
          skillLevel = RecommendationLevel.intermediate;
        }
        if (completedLessons.length > 50) {
          skillLevel = RecommendationLevel.advanced;
        }
        if (completedLessons.length > 100) {
          skillLevel = RecommendationLevel.expert;
        }
      }

      // Generate recommendations based on profile
      final recommendations = <AIOpeningRecommendation>[];

      // Recommend openings based on weak areas
      for (final weakness in profile.mainWeaknesses) {
        final recommendation = _createOpeningRecommendation(
          userId,
          weakness,
          skillLevel,
          profile.playStyle,
        );
        recommendations.add(recommendation);
      }

      // Save to Firestore
      for (final rec in recommendations) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('opening_recommendations')
            .doc(rec.id)
            .set(rec.toJson());
      }

      return recommendations;
    } catch (e) {
      throw Exception('Error generating opening recommendations: $e');
    }
  }

  Future<ImprovementPath> generateImprovementPath(String userId) async {
    try {
      final profile = await generatePlayerProfile(userId);

      final priorityAreas = profile.mainWeaknesses.take(5).toList();
      final lessonsToTake = await _getRecommendedLessons(
        userId,
        priorityAreas,
      );
      final practiceOpenings = profile.preferredOpenings.take(3).toList();
      final tacticPatternsToStudy = profile.frequentMistakes.take(5).toList();

      final improvementPath = ImprovementPath(
        userId: userId,
        priorityAreas: priorityAreas,
        lessonsToTake: lessonsToTake,
        practiceOpenings: practiceOpenings,
        tacticPatternsToStudy: tacticPatternsToStudy,
        estimatedDaysToImprovement: _estimateDaysToImprovement(
          profile.mainWeaknesses.length,
          lessonsToTake.length,
        ),
        personalizedAdvice: _generatePersonalizedAdvice(
          profile,
          priorityAreas,
        ),
        generatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).set(
          {'improvement_path': improvementPath.toJson()},
          SetOptions(merge: true));

      return improvementPath;
    } catch (e) {
      throw Exception('Error generating improvement path: $e');
    }
  }

  Future<List<AIGeneratedLesson>> getAIGeneratedLessons(
    String userId, {
    AIContentType? contentType,
    RecommendationLevel? skillLevel,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_generated_lessons');

      if (contentType != null) {
        query = query.where('contentType', isEqualTo: contentType.toString());
      }

      if (skillLevel != null) {
        query =
            query.where('recommendedLevel', isEqualTo: skillLevel.toString());
      }

      query = query.orderBy('generatedAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) =>
              AIGeneratedLesson.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching AI-generated lessons: $e');
    }
  }

  Future<void> rateLessonUsefulness(
    String userId,
    String lessonId,
    int rating,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_generated_lessons')
          .doc(lessonId)
          .update({
        'usefulnessRating': rating,
        'ratedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error rating lesson: $e');
    }
  }

  Future<PlayerProfile> generatePlayerProfile(String userId) async {
    try {
      final gamesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('games')
          .get();

      if (gamesSnapshot.docs.isEmpty) {
        return PlayerProfile(
          userId: userId,
          totalGamesAnalyzed: 0,
          averageAccuracy: 0.0,
          mainWeaknesses: [],
          mainStrengths: [],
          preferredOpenings: [],
          frequentMistakes: [],
          tacticPatternsKnown: 0,
          playStyle: 'Unknown',
          lastAnalysisDate: DateTime.now(),
          recommendedNextLessons: [],
        );
      }

      final analysesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('game_analyses')
          .get();

      double totalAccuracy = 0.0;
      final Set<String> weaknesses = {};
      final Set<String> strengths = {};
      final Set<String> openings = {};
      final Set<String> mistakes = {};
      int tacticCount = 0;

      for (final doc in analysesSnapshot.docs) {
        final analysis =
            GameAnalysis.fromJson(doc.data() as Map<String, dynamic>);
        totalAccuracy += analysis.overallAccuracy;
        weaknesses.addAll(analysis.identifiedWeaknesses);
        openings.addAll(analysis.openingsPlayed);
        mistakes.addAll(analysis.moveAnalyses
            .where((m) => m.isMistake || m.isBlunder)
            .map((m) => m.tacticPattern)
            .where((p) => p.isNotEmpty));
        tacticCount += analysis.tacticPatternsEncountered.length;
      }

      final averageAccuracy = analysesSnapshot.docs.isNotEmpty
          ? totalAccuracy / analysesSnapshot.docs.length
          : 0.0;

      final lessonsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_generated_lessons')
          .get();

      final recommendedLessons = lessonsSnapshot.docs
          .map((doc) =>
              AIGeneratedLesson.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return PlayerProfile(
        userId: userId,
        totalGamesAnalyzed: gamesSnapshot.docs.length,
        averageAccuracy: averageAccuracy,
        mainWeaknesses: weaknesses.take(5).toList(),
        mainStrengths: _identifyStrengths(analysesSnapshot.docs),
        preferredOpenings: openings.take(3).toList(),
        frequentMistakes: mistakes.take(5).toList(),
        tacticPatternsKnown: tacticCount,
        playStyle: _determinePlayStyle(analysesSnapshot.docs),
        lastAnalysisDate: DateTime.now(),
        recommendedNextLessons: recommendedLessons.take(3).toList(),
      );
    } catch (e) {
      throw Exception('Error generating player profile: $e');
    }
  }

  Future<List<EndgameInsight>> analyzeEndgameWeaknesses(String userId) async {
    try {
      final analysesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('game_analyses')
          .get();

      final insights = <EndgameInsight>[];

      for (final doc in analysesSnapshot.docs) {
        final analysis =
            GameAnalysis.fromJson(doc.data() as Map<String, dynamic>);

        // Find moves in endgame (last 20 moves)
        final endgameMoves = analysis.moveAnalyses.skip(
          (analysis.moveAnalyses.length * 0.8).toInt(),
        );

        for (final move in endgameMoves) {
          if (move.isMistake || move.isBlunder) {
            final insight = EndgameInsight(
              id: '${userId}_${analysis.id}_${move.moveNumber}',
              userId: userId,
              endgameName: _classifyEndgame(move.currentFen),
              position: move.currentFen,
              technique: _identifyEndgameTechnique(move.currentFen),
              explanation: move.explanation,
              keyPrinciples: _extractEndgamePrinciples(move.currentFen),
              relevantTacticalTheme: move.tacticPattern,
              isWeakness: true,
              identifiedAt: DateTime.now(),
            );
            insights.add(insight);
          }
        }
      }

      return insights;
    } catch (e) {
      throw Exception('Error analyzing endgame weaknesses: $e');
    }
  }

  Future<List<AIInsight>> getRecentInsights(String userId) async {
    try {
      final recentGamesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('game_analyses')
          .orderBy('analysisDate', descending: true)
          .limit(5)
          .get();

      final insights = <AIInsight>[];

      for (final doc in recentGamesSnapshot.docs) {
        final analysis =
            GameAnalysis.fromJson(doc.data() as Map<String, dynamic>);

        // Create insight from analysis
        if (analysis.identifiedWeaknesses.isNotEmpty) {
          insights.add(
            AIInsight(
              id: '${userId}_${analysis.id}_weakness',
              userId: userId,
              title: 'Focus: ${analysis.identifiedWeaknesses.first}',
              description: 'From game analysis',
              contentType: AIContentType.improvementArea,
              relatedGameId: analysis.gameId,
              relevanceRank: 1,
              generatedAt: DateTime.now(),
              isActionable: true,
              isRead: false,
            ),
          );
        }
      }

      return insights;
    } catch (e) {
      throw Exception('Error fetching recent insights: $e');
    }
  }

  Future<void> respondToLesson(
    String userId,
    String lessonId,
    bool accepted,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_generated_lessons')
          .doc(lessonId)
          .update({
        'userResponse': accepted ? 'accepted' : 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error responding to lesson: $e');
    }
  }

  Future<Map<String, dynamic>> getPerformanceProgressAnalytics(
    String userId,
  ) async {
    try {
      final analysesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('game_analyses')
          .orderBy('analysisDate')
          .get();

      if (analysesSnapshot.docs.length < 2) {
        return {'message': 'Insufficient data for analysis'};
      }

      final first = GameAnalysis.fromJson(
          analysesSnapshot.docs.first.data() as Map<String, dynamic>);
      final latest = GameAnalysis.fromJson(
          analysesSnapshot.docs.last.data() as Map<String, dynamic>);

      return {
        'accuracyImprovement': latest.overallAccuracy - first.overallAccuracy,
        'blunderReduction': first.blunders - latest.blunders,
        'gamesAnalyzed': analysesSnapshot.docs.length,
        'previousAccuracy': first.overallAccuracy,
        'currentAccuracy': latest.overallAccuracy,
        'trend': latest.overallAccuracy > first.overallAccuracy
            ? 'improving'
            : 'declining',
      };
    } catch (e) {
      throw Exception('Error calculating performance analytics: $e');
    }
  }

  Future<void> clearCachedAnalysis(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('game_analyses')
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error clearing cached analysis: $e');
    }
  }

  // Helper methods

  AnalysisType _classifyMove(String move, int moveIndex) {
    // Simplified classification - would use chess engine in production
    if (moveIndex < 5) return AnalysisType.goodMove;
    return AnalysisType.inaccuracy;
  }

  String _findBestMove(String pgn, int moveIndex) {
    // Simplified - would query chess engine
    return 'e2e4';
  }

  String _generateMoveExplanation(String move, AnalysisType type) {
    switch (type) {
      case AnalysisType.blunder:
        return 'This move loses significant material or position.';
      case AnalysisType.mistake:
        return 'This move worsens your position noticeably.';
      case AnalysisType.inaccuracy:
        return 'A better move was available.';
      case AnalysisType.goodMove:
        return 'A solid move that improves or maintains position.';
      case AnalysisType.excellentMove:
        return 'An excellent move showing strong calculation.';
      case AnalysisType.bestMove:
        return 'The best possible move in this position.';
    }
  }

  String _identifyTacticPattern(String pgn, int moveIndex) {
    // Simplified - would analyze position for tactics
    return 'pin';
  }

  double _calculateEvaluationDifference(String move, String bestMove) {
    return move == bestMove ? 0.0 : -0.5;
  }

  String _calculateFenAtMove(String pgn, int moveIndex) {
    // Simplified FEN calculation
    return 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  }

  double _calculateMoveAccuracy(AnalysisType type) {
    switch (type) {
      case AnalysisType.bestMove:
        return 100.0;
      case AnalysisType.excellentMove:
        return 95.0;
      case AnalysisType.goodMove:
        return 85.0;
      case AnalysisType.inaccuracy:
        return 70.0;
      case AnalysisType.mistake:
        return 40.0;
      case AnalysisType.blunder:
        return 0.0;
    }
  }

  Future<List<AIGeneratedLesson>> _generateSuggestedLessons(
    String userId,
    List<MoveAnalysis> moves,
    List<String> tactics,
  ) async {
    // Get relevant lessons from database
    final lessonsSnapshot =
        await _firestore.collection('chess_lessons').limit(3).get();

    return lessonsSnapshot.docs
        .map((doc) => AIGeneratedLesson(
              id: 'ai_${doc.id}',
              userId: userId,
              gameId: '',
              contentType: AIContentType.tacticPattern,
              title: doc['title'] ?? 'AI-Generated Lesson',
              description: 'Based on your recent game analysis',
              pgn: doc['pgn'] ?? '',
              keyPoints: List<String>.from(doc['keyPoints'] ?? []),
              commonMistakes: List<String>.from(doc['commonMistakes'] ?? []),
              suggestedFocus: tactics,
              relevanceScore: 0.85,
              recommendedLevel: RecommendationLevel.intermediate,
              generatedAt: DateTime.now(),
              estimatedMinutes: 15,
              isReviewed: false,
              isLiked: false,
              reviewCount: 0,
              customNotes: '',
            ))
        .toList();
  }

  String _generateOverallAssessment(
    double accuracy,
    int blunders,
    int totalMoves,
  ) {
    if (accuracy > 85 && blunders == 0) {
      return 'Excellent game with very few errors.';
    } else if (accuracy > 70) {
      return 'Good game overall, room for improvement in tactics.';
    } else {
      return 'Several mistakes found. Focus on pattern recognition.';
    }
  }

  AIOpeningRecommendation _createOpeningRecommendation(
    String userId,
    String weakness,
    RecommendationLevel skillLevel,
    String playStyle,
  ) {
    return AIOpeningRecommendation(
      id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      ecoCode: 'C45',
      openingName: 'Italian Game',
      reasoning: 'Recommended to address weakness: $weakness',
      compatibilityScore: 0.85,
      skillLevel: skillLevel,
      mainLines: ['1.e4 e5 2.Nf3 Nc6 3.Bc4'],
      tacticalThemes: ['pins', 'forks', 'discovered attacks'],
      strategicIdeas: ['center control', 'piece development'],
      winRates: {'white': 0.52, 'black': 0.48},
      recommendedAt: DateTime.now(),
    );
  }

  Future<List<AIGeneratedLesson>> _getRecommendedLessons(
    String userId,
    List<String> areas,
  ) async {
    final lessons = <AIGeneratedLesson>[];
    for (final area in areas) {
      lessons.add(
        AIGeneratedLesson(
          id: '${userId}_${area}_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          gameId: '',
          contentType: AIContentType.improvementArea,
          title: 'Master: $area',
          description: 'AI-generated lesson for improvement',
          pgn: '',
          keyPoints: [],
          commonMistakes: [],
          suggestedFocus: [area],
          relevanceScore: 0.9,
          recommendedLevel: RecommendationLevel.intermediate,
          generatedAt: DateTime.now(),
          estimatedMinutes: 20,
          isReviewed: false,
          isLiked: false,
          reviewCount: 0,
          customNotes: '',
        ),
      );
    }
    return lessons;
  }

  int _estimateDaysToImprovement(int weaknessCount, int lessonCount) {
    return (weaknessCount * 3 + lessonCount * 2) ~/ 2;
  }

  String _generatePersonalizedAdvice(
    PlayerProfile profile,
    List<String> priorityAreas,
  ) {
    return 'Focus on: ${priorityAreas.join(", ")}. Study related openings and practice tactical patterns.';
  }

  List<String> _identifyStrengths(List<QueryDocumentSnapshot> docs) {
    return ['Opening knowledge', 'Tactical awareness'];
  }

  String _determinePlayStyle(List<QueryDocumentSnapshot> docs) {
    return 'Tactical';
  }

  String _classifyEndgame(String fen) {
    return 'Rook and Pawn';
  }

  String _identifyEndgameTechnique(String fen) {
    return 'Zugzwang';
  }

  List<String> _extractEndgamePrinciples(String fen) {
    return ['King activity', 'Pawn promotion', 'Opposition'];
  }
}
