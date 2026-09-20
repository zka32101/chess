import 'package:chess_tactics_master/src/models/ai_lesson.dart';
import 'package:chess_tactics_master/src/models/game.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Optimized AI analysis service
/// Parallelizes move analysis and implements caching
class AIAnalysisOptimizer {
  final FirebaseFirestore _firestore;
  final Map<String, GameAnalysis> _analysisCache = {};
  final Map<String, ChessPosition> _positionCache = {};

  AIAnalysisOptimizer({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Analyze game with optimizations:
  /// 1. Cache lookup
  /// 2. Parallel move analysis
  /// 3. Efficient aggregation
  Future<GameAnalysis> analyzeGameOptimized(
    String userId,
    String gameId,
    GameModel game,
  ) async {
    // Check cache first
    final cached = _analysisCache[gameId];
    if (cached != null) {
      return cached;
    }

    // Parse moves once
    final pgn = game.pgn ?? '';
    final moves = pgn.split(' ').where((m) => m.isNotEmpty).toList();

    // Parallelize move analysis
    final moveAnalyses = await Future.wait(
      [
        for (int i = 0; i < moves.length; i++)
          _analyzeMoveOptimized(game, moves, i),
      ],
      eagerError: false,
    );

    // Aggregate results in single pass
    final aggregated = _aggregateMoveAnalysis(moveAnalyses, game);
    final goodMoves = moveAnalyses
        .where((m) =>
            m.analysisType == AnalysisType.goodMove ||
            m.analysisType == AnalysisType.excellentMove ||
            m.analysisType == AnalysisType.bestMove)
        .length;

    final analysis = GameAnalysis(
      id: gameId,
      userId: userId,
      gameId: gameId,
      analysisDate: DateTime.now(),
      overallAccuracy: aggregated.accuracy,
      totalMoves: moves.length,
      blunders: aggregated.blunders,
      mistakes: aggregated.mistakes,
      inaccuracies: aggregated.inaccuracies,
      goodMoves: goodMoves,
      moveAnalyses: moveAnalyses,
      identifiedWeaknesses: aggregated.weaknesses,
      openingsPlayed: const [],
      tacticPatternsEncountered: moveAnalyses
          .map((m) => m.tacticPattern)
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList(),
      overallAssessment: _generateOverallAssessment(
        aggregated.accuracy,
        aggregated.blunders,
      ),
      suggestedLessons: const [],
    );

    // Cache result
    _analysisCache[gameId] = analysis;

    return analysis;
  }

  /// Analyze single move efficiently
  /// Reuses cached positions to avoid recomputation
  Future<MoveAnalysis> _analyzeMoveOptimized(
    GameModel game,
    List<String> moves,
    int moveIndex,
  ) async {
    try {
      // Get or compute position
      final position = _getOrComputePosition(moves, moveIndex);

      // For now, mock analysis (would use chess engine)
      final moveQuality = _evaluateMoveQuality(moves[moveIndex], moveIndex);
      final tactics = _detectTacticalPatterns(position, moves[moveIndex]);

      return MoveAnalysis(
        moveNumber: moveIndex + 1,
        move: moves[moveIndex],
        currentFen: position.fen,
        analysisType: moveQuality,
        evaluationDifference: _calculateEvalDifference(moveQuality),
        bestMove: moves[moveIndex],
        explanation: _explainMove(moveQuality, tactics),
        tacticPattern: tactics.isNotEmpty ? tactics.first : '',
        isBlunder: moveQuality == AnalysisType.blunder,
        isMistake: moveQuality == AnalysisType.mistake,
        isInaccuracy: moveQuality == AnalysisType.inaccuracy,
      );
    } catch (e) {
      // Return empty analysis on error
      return MoveAnalysis(
        moveNumber: moveIndex + 1,
        move: moves[moveIndex],
        currentFen: '',
        analysisType: AnalysisType.goodMove,
        evaluationDifference: 0.0,
        bestMove: moves[moveIndex],
        explanation: 'Unable to analyze move',
        tacticPattern: '',
        isBlunder: false,
        isMistake: false,
        isInaccuracy: false,
      );
    }
  }

  /// Get or compute chess position
  /// Caches positions to avoid recomputation
  ChessPosition _getOrComputePosition(List<String> moves, int upToIndex) {
    final key = moves.sublist(0, upToIndex + 1).join('_');

    if (_positionCache.containsKey(key)) {
      return _positionCache[key]!;
    }

    // Reuse previous position if available
    ChessPosition position = ChessPosition.startingPosition;
    if (upToIndex > 0) {
      final prevKey = moves.sublist(0, upToIndex).join('_');
      if (_positionCache.containsKey(prevKey)) {
        position = _positionCache[prevKey]!;
      }
    }

    // Apply only the new move
    position = position.applyMove(moves[upToIndex]);
    _positionCache[key] = position;

    return position;
  }

  /// Aggregate move analysis results
  _AggregatedAnalysis _aggregateMoveAnalysis(
    List<MoveAnalysis> moveAnalyses,
    GameModel game,
  ) {
    int blunders = 0;
    int mistakes = 0;
    int inaccuracies = 0;
    int bestMoves = 0;
    double totalAccuracy = 0.0;
    final weaknesses = <String>{};

    for (final analysis in moveAnalyses) {
      switch (analysis.analysisType) {
        case AnalysisType.blunder:
          blunders++;
          totalAccuracy += 20;
        case AnalysisType.mistake:
          mistakes++;
          totalAccuracy += 50;
        case AnalysisType.inaccuracy:
          inaccuracies++;
          totalAccuracy += 75;
        case AnalysisType.goodMove:
          totalAccuracy += 85;
        case AnalysisType.excellentMove:
          totalAccuracy += 95;
        case AnalysisType.bestMove:
          bestMoves++;
          totalAccuracy += 100;
      }

      // Identify patterns
      if (analysis.analysisType == AnalysisType.blunder ||
          analysis.analysisType == AnalysisType.mistake) {
        // Would analyze position to identify weakness pattern
        // For now, generic weakness
        weaknesses.add('MoveExecution');
      }
    }

    final accuracy =
        moveAnalyses.isEmpty ? 0.0 : totalAccuracy / moveAnalyses.length;

    return _AggregatedAnalysis(
      accuracy: accuracy.clamp(0, 100),
      blunders: blunders,
      mistakes: mistakes,
      inaccuracies: inaccuracies,
      bestMoves: bestMoves,
      weaknesses: weaknesses.toList(),
    );
  }

  /// Evaluate move quality (mock implementation)
  AnalysisType _evaluateMoveQuality(String move, int moveIndex) {
    // Simplified evaluation - would use chess engine
    final moveNum = moveIndex + 1;

    if (moveNum <= 10 && move.toLowerCase().contains('e')) {
      return AnalysisType.goodMove;
    } else if (moveNum > 20 && moveIndex % 3 == 0) {
      return AnalysisType.inaccuracy;
    }

    return AnalysisType.goodMove;
  }

  /// Detect tactical patterns in position
  List<String> _detectTacticalPatterns(
    ChessPosition position,
    String move,
  ) {
    final patterns = <String>[];
    // Analyze position for tactical themes
    // Would use position evaluation here
    return patterns;
  }

  /// Explain move quality
  String _explainMove(AnalysisType quality, List<String> tactics) {
    return switch (quality) {
      AnalysisType.blunder => 'Blunder - loses material or position',
      AnalysisType.mistake => 'Mistake - weakens position',
      AnalysisType.inaccuracy => 'Inaccuracy - not optimal',
      AnalysisType.goodMove => 'Good move - solid play',
      AnalysisType.excellentMove => 'Excellent move - strong advantage',
      AnalysisType.bestMove => 'Best move - perfect continuation',
    };
  }

  /// Generate a short overall assessment from accuracy/blunder counts
  String _generateOverallAssessment(double accuracy, int blunders) {
    if (accuracy > 85 && blunders == 0) {
      return 'Excellent game with very few errors.';
    } else if (accuracy > 70) {
      return 'Good game overall, room for improvement in tactics.';
    } else {
      return 'Several mistakes found. Focus on pattern recognition.';
    }
  }

  /// Calculate evaluation difference
  double _calculateEvalDifference(AnalysisType analysisType) {
    return switch (analysisType) {
      AnalysisType.blunder => 3.0,
      AnalysisType.mistake => 1.5,
      AnalysisType.inaccuracy => 0.5,
      AnalysisType.goodMove => 0.0,
      AnalysisType.excellentMove => -0.5,
      AnalysisType.bestMove => -1.0,
    };
  }

  /// Clear caches
  void clearCaches() {
    _analysisCache.clear();
    _positionCache.clear();
  }

  /// Get cache statistics
  CacheStatistics getStats() {
    return CacheStatistics(
      analysisCount: _analysisCache.length,
      positionCount: _positionCache.length,
    );
  }
}

/// Chess position representation (simplified)
class ChessPosition {
  final String fen;

  ChessPosition({required this.fen});

  static ChessPosition get startingPosition =>
      ChessPosition(fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR');

  /// Apply move to position
  ChessPosition applyMove(String move) {
    // Simplified - would use proper chess engine
    return ChessPosition(fen: '$fen:$move');
  }
}

/// Aggregated analysis results
class _AggregatedAnalysis {
  final double accuracy;
  final int blunders;
  final int mistakes;
  final int inaccuracies;
  final int bestMoves;
  final List<String> weaknesses;

  _AggregatedAnalysis({
    required this.accuracy,
    required this.blunders,
    required this.mistakes,
    required this.inaccuracies,
    required this.bestMoves,
    required this.weaknesses,
  });
}

/// Cache statistics
class CacheStatistics {
  final int analysisCount;
  final int positionCount;

  CacheStatistics({
    required this.analysisCount,
    required this.positionCount,
  });

  int get totalCached => analysisCount + positionCount;
}
