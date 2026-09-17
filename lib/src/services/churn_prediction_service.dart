import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ml_models.dart';
import '../models/analytics_models.dart';
import 'dart:math' as math;

class ChurnPredictionService {
  final FirebaseFirestore _firestore;
  static ChurnPredictionService? _instance;

  final Duration _cacheDuration = const Duration(hours: 2);
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, ChurnRiskProfile> _riskProfiles = {};

  ChurnPredictionService(this._firestore);

  static ChurnPredictionService getInstance(FirebaseFirestore firestore) {
    _instance ??= ChurnPredictionService(firestore);
    return _instance!;
  }

  Future<ChurnRiskProfile> getPredictedChurnRisk({
    required String userId,
    int daysSinceSignup = 30,
    int sessionsLast7Days = 5,
    double avgSessionDurationMinutes = 15.0,
    int daysInactive = 2,
    int featureTypesUsed = 3,
  }) async {
    try {
      // Check cache
      if (_riskProfiles.containsKey(userId) && _isCacheValid(userId)) {
        return _riskProfiles[userId]!;
      }

      // Logistic regression coefficients (trained weights)
      const weights = {
        'daysSinceSignup': -0.02, // Longer tenure = lower churn
        'sessionsLast7Days': -0.15, // More sessions = lower churn
        'avgSessionDuration': -0.05, // Longer sessions = lower churn
        'daysInactive': 0.25, // More inactive = higher churn
        'featureUsage': -0.10, // More feature diversity = lower churn
      };

      // Normalize features to 0-1 range
      final normalizedFeatures = {
        'daysSinceSignup': _normalize(daysSinceSignup, 0, 180),
        'sessionsLast7Days': _normalize(sessionsLast7Days, 0, 20),
        'avgSessionDuration': _normalize(avgSessionDurationMinutes, 0, 60),
        'daysInactive': _normalize(daysInactive, 0, 30),
        'featureUsage': _normalize(featureTypesUsed, 0, 10),
      };

      // Calculate logit
      var logit = -2.5; // Intercept
      logit += weights['daysSinceSignup']! * normalizedFeatures['daysSinceSignup']!;
      logit += weights['sessionsLast7Days']! * normalizedFeatures['sessionsLast7Days']!;
      logit += weights['avgSessionDuration']! * normalizedFeatures['avgSessionDuration']!;
      logit += weights['daysInactive']! * normalizedFeatures['daysInactive']!;
      logit += weights['featureUsage']! * normalizedFeatures['featureUsage']!;

      // Convert to probability (sigmoid function)
      final prob14Day = _sigmoid(logit);
      final prob30Day = math.min(1.0, prob14Day * 1.5); // 30-day is higher

      // Identify top risk factors
      final riskFactors = <String>[];
      if (daysInactive > 7) riskFactors.add('High inactivity');
      if (sessionsLast7Days < 2) riskFactors.add('Low engagement');
      if (daysSinceSignup < 7) riskFactors.add('New user');
      if (featureTypesUsed < 2) riskFactors.add('Limited feature usage');
      if (avgSessionDurationMinutes < 5) riskFactors.add('Short sessions');

      // Get recommendation
      final recommendation = _getRetentionRecommendation(
        prob14Day,
        riskFactors,
      );

      final profile = ChurnRiskProfile(
        userId: userId,
        churnProbability14Day: prob14Day,
        churnProbability30Day: prob30Day,
        topRiskFactors: riskFactors,
        riskFactorWeights: weights.cast(),
        riskSegment: _getRiskSegment(prob14Day),
        recommendedAction: recommendation,
        calculatedAt: DateTime.now(),
        nextReviewDate: DateTime.now().add(const Duration(days: 7)),
      );

      _riskProfiles[userId] = profile;
      _cacheTimestamps[userId] = DateTime.now();

      // Store in Firestore
      await _storeChurnProfile(profile);

      return profile;
    } catch (e) {
      throw Exception('Error predicting churn risk: $e');
    }
  }

  Future<List<ChurnRiskProfile>> getHighRiskUsers({
    required int riskThreshold = 50, // >50% churn probability
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('analytics/churn_predictions')
          .where('churnProbability14Day', isGreaterThan: riskThreshold / 100)
          .orderBy('churnProbability14Day', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ChurnRiskProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error getting high-risk users: $e');
    }
  }

  Future<Map<String, dynamic>> getCohortChurnForecast({
    required String cohortDate,
  }) async {
    try {
      // Get users from cohort
      final cohortSnapshot = await _firestore
          .collection('analytics/user_cohorts')
          .where('cohortDate', isEqualTo: cohortDate)
          .get();

      if (cohortSnapshot.docs.isEmpty) {
        throw Exception('Cohort not found: $cohortDate');
      }

      final cohortSize = cohortSnapshot.size;
      var totalChurnRisk = 0.0;

      // Calculate aggregate churn risk
      for (var doc in cohortSnapshot.docs) {
        final userChurnRisk = (doc['estimatedChurnRisk'] as num?)?.toDouble() ?? 0.5;
        totalChurnRisk += userChurnRisk;
      }

      final avgChurnRisk = totalChurnRisk / cohortSize;

      return {
        'cohortDate': cohortDate,
        'cohortSize': cohortSize,
        'avgChurnRisk': avgChurnRisk,
        'estimatedChurnCount': (cohortSize * avgChurnRisk).toInt(),
        'retentionProbability': 1.0 - avgChurnRisk,
        'riskLevel': _getRiskSegment(avgChurnRisk),
        'forecast7Day': avgChurnRisk * 0.8,
        'forecast30Day': math.min(1.0, avgChurnRisk * 1.5),
      };
    } catch (e) {
      throw Exception('Error getting cohort churn forecast: $e');
    }
  }

  Future<List<ChurnFactor>> getChurnFactors({
    required String userId,
  }) async {
    try {
      final profile = await getPredictedChurnRisk(userId: userId);

      final factors = <ChurnFactor>[];
      for (var factor in profile.topRiskFactors) {
        factors.add(ChurnFactor(
          factorName: factor,
          weight: profile.riskFactorWeights['factor'] ?? 0.1,
          contribution: (profile.riskFactorWeights['factor'] ?? 0.1) * profile.churnProbability14Day,
          interpretation: _interpretRiskFactor(factor),
          isPositive: false,
        ));
      }

      return factors;
    } catch (e) {
      throw Exception('Error getting churn factors: $e');
    }
  }

  Future<List<RetentionOpportunity>> getRetentionOpportunities({
    required int limit = 50,
  }) async {
    try {
      // Get high-risk users
      final highRiskUsers = await getHighRiskUsers(
        riskThreshold: 60,
        limit: limit,
      );

      final opportunities = <RetentionOpportunity>[];
      for (var user in highRiskUsers) {
        opportunities.add(RetentionOpportunity(
          userId: user.userId,
          churnRisk: user.churnProbability14Day,
          recommendedOffer: _selectRetentionOffer(user),
          targetReason: user.recommendedAction,
          expectedRetentionImpact: _estimateRetentionImpact(user),
          identifiedAt: user.calculatedAt,
        ));
      }

      return opportunities;
    } catch (e) {
      throw Exception('Error getting retention opportunities: $e');
    }
  }

  Future<Map<String, dynamic>> generateChurnReport({
    required int daysLookback = 30,
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: daysLookback));

      final snapshot = await _firestore
          .collection('analytics/churn_predictions')
          .where('calculatedAt', isGreaterThan: cutoffTime)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'period': daysLookback,
          'totalUsersAnalyzed': 0,
          'avgChurnRisk': 0.0,
          'highRiskCount': 0,
          'mediumRiskCount': 0,
          'lowRiskCount': 0,
        };
      }

      var avgChurnRisk = 0.0;
      var highRiskCount = 0;
      var mediumRiskCount = 0;
      var lowRiskCount = 0;

      for (var doc in snapshot.docs) {
        final churnRisk = (doc['churnProbability14Day'] as num).toDouble();
        avgChurnRisk += churnRisk;

        if (churnRisk > 0.7) {
          highRiskCount++;
        } else if (churnRisk > 0.4) {
          mediumRiskCount++;
        } else {
          lowRiskCount++;
        }
      }

      avgChurnRisk /= snapshot.size;

      return {
        'period': daysLookback,
        'totalUsersAnalyzed': snapshot.size,
        'avgChurnRisk': avgChurnRisk,
        'highRiskCount': highRiskCount,
        'mediumRiskCount': mediumRiskCount,
        'lowRiskCount': lowRiskCount,
        'highRiskPercentage': (highRiskCount / snapshot.size * 100).toStringAsFixed(1),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error generating churn report: $e');
    }
  }

  void clearCache() {
    _riskProfiles.clear();
    _cacheTimestamps.clear();
  }

  // Private helper methods

  bool _isCacheValid(String userId) {
    if (!_cacheTimestamps.containsKey(userId)) return false;
    final cacheTime = _cacheTimestamps[userId]!;
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  double _normalize(double value, double min, double max) {
    if (max == min) return 0.5;
    return (value - min) / (max - min);
  }

  double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }

  String _getRiskSegment(double probability) {
    if (probability > 0.7) return 'critical';
    if (probability > 0.5) return 'high';
    if (probability > 0.3) return 'medium';
    return 'low';
  }

  String _getRetentionRecommendation(
    double churnProbability,
    List<String> riskFactors,
  ) {
    if (churnProbability > 0.7) {
      return 'Send premium offer + personalized engagement plan';
    } else if (churnProbability > 0.5) {
      return 'Offer limited-time bonus or discount';
    } else if (churnProbability > 0.3) {
      return 'Send re-engagement email with tips';
    } else {
      return 'Continue normal engagement';
    }
  }

  String _interpretRiskFactor(String factor) {
    switch (factor.toLowerCase()) {
      case 'high inactivity':
        return 'User has not logged in for >7 days, high churn predictor';
      case 'low engagement':
        return '<2 sessions in last 7 days indicates declining interest';
      case 'new user':
        return 'New users within first week have higher churn risk';
      case 'limited feature usage':
        return 'Using <2 features limits retention likelihood';
      case 'short sessions':
        return 'Average session <5 minutes suggests low engagement';
      default:
        return 'This factor contributes to churn likelihood';
    }
  }

  String _selectRetentionOffer(ChurnRiskProfile user) {
    if (user.churnProbability14Day > 0.8) {
      return '30% discount on next month + VIP support';
    } else if (user.churnProbability14Day > 0.6) {
      return '20% discount + exclusive feature access';
    } else {
      return '7-day free trial of premium features';
    }
  }

  double _estimateRetentionImpact(ChurnRiskProfile user) {
    // Estimate probability retention offer will prevent churn
    if (user.topRiskFactors.contains('High inactivity')) {
      return 0.4; // 40% chance personalized offer will re-engage
    } else if (user.topRiskFactors.contains('Low engagement')) {
      return 0.5; // 50% chance discount will retain
    }
    return 0.6; // 60% chance for medium-risk users
  }

  Future<void> _storeChurnProfile(ChurnRiskProfile profile) async {
    try {
      await _firestore
          .collection('analytics/churn_predictions')
          .doc(profile.userId)
          .set(profile.toJson());
    } catch (e) {
      print('Error storing churn profile: $e');
    }
  }
}
