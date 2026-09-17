import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ml_models.dart';
import '../models/analytics_models.dart';
import 'dart:math' as math;

class AnomalyDetectionService {
  final FirebaseFirestore _firestore;
  static AnomalyDetectionService? _instance;

  final Map<String, List<double>> _metricHistory = {};
  final Map<String, AnomalyDetectionResult> _lastResults = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  AnomalyDetectionService(this._firestore);

  static AnomalyDetectionService getInstance(FirebaseFirestore firestore) {
    _instance ??= AnomalyDetectionService(firestore);
    return _instance!;
  }

  Future<List<AnomalyAlert>> detectAnomalies({
    required String metricName,
    required List<double> values,
    double zScoreThreshold = 3.0,
  }) async {
    try {
      if (values.isEmpty) return [];

      final alerts = <AnomalyAlert>[];
      final mean = _calculateMean(values);
      final stdDev = _calculateStdDev(values, mean);

      if (stdDev == 0) return [];

      for (int i = 0; i < values.length; i++) {
        final value = values[i];
        final zScore = (value - mean).abs() / stdDev;

        if (zScore > zScoreThreshold) {
          final severity = _determineSeverity(zScore);
          final alert = AnomalyAlert(
            alertId: '$metricName-${DateTime.now().millisecondsSinceEpoch}',
            metricName: metricName,
            detectedValue: value,
            baselineValue: mean,
            anomalyScore: math.min(zScore / 5.0, 1.0),
            detectedAt: DateTime.now(),
            severity: severity,
            description: 'Detected ${severity.toUpperCase()} anomaly: $metricName = $value (baseline: $mean)',
            recommendedAction: _getRecommendedAction(metricName, value, mean),
          );
          alerts.add(alert);
        }
      }

      // Store alerts in Firestore
      await _storeAlerts(alerts);
      return alerts;
    } catch (e) {
      throw Exception('Error detecting anomalies: $e');
    }
  }

  Future<AnomalyDetectionResult?> detectSingleAnomalyScore({
    required String metricName,
    required double value,
    required int historySize = 30,
  }) async {
    try {
      // Get historical data
      final history = await _getMetricHistory(metricName, historySize);
      if (history.length < 2) return null;

      final mean = _calculateMean(history);
      final stdDev = _calculateStdDev(history, mean);

      if (stdDev == 0) return null;

      final zScore = (value - mean).abs() / stdDev;
      final isAnomaly = zScore > 3.0;
      final anomalyScore = math.min(zScore / 5.0, 1.0);

      final result = AnomalyDetectionResult(
        metricName: metricName,
        value: value,
        mean: mean,
        stdDev: stdDev,
        zScore: zScore,
        isAnomaly: isAnomaly,
        anomalyScore: anomalyScore,
        anomalyType: _classifyAnomaly(value, mean, stdDev),
      );

      _lastResults[metricName] = result;
      return result;
    } catch (e) {
      throw Exception('Error detecting single anomaly: $e');
    }
  }

  Future<bool> flagRegressions({
    required String queryType,
    required int currentP50,
    double regressionThreshold = 0.2,
  }) async {
    try {
      // Get historical P50 values (last 7 days)
      final trends = await _getQueryTrends(queryType, 7);
      if (trends.isEmpty) return false;

      final p50Values = trends.map((t) => t.p50Latency.toDouble()).toList();
      final avgP50 = _calculateMean(p50Values);

      // Check if current is >20% worse than average
      final degradation = (currentP50 - avgP50) / avgP50;
      final isRegression = degradation > regressionThreshold;

      if (isRegression) {
        await _storeRegressionAlert(queryType, currentP50, avgP50, degradation);
      }

      return isRegression;
    } catch (e) {
      throw Exception('Error flagging regressions: $e');
    }
  }

  Future<double> getAnomalyScore({
    required String metricName,
    required double value,
  }) async {
    try {
      // Use cache if available
      if (_cacheTimestamps.containsKey(metricName)) {
        final cacheTime = _cacheTimestamps[metricName]!;
        if (DateTime.now().difference(cacheTime) < _cacheDuration) {
          if (_lastResults.containsKey(metricName)) {
            return _lastResults[metricName]!.anomalyScore;
          }
        }
      }

      final result = await detectSingleAnomalyScore(
        metricName: metricName,
        value: value,
      );

      if (result != null) {
        _cacheTimestamps[metricName] = DateTime.now();
        return result.anomalyScore;
      }

      return 0.0;
    } catch (e) {
      throw Exception('Error getting anomaly score: $e');
    }
  }

  Future<List<AnomalyAlert>> getRecentAnomalies({
    required int hours = 24,
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));

      final snapshot = await _firestore
          .collection('analytics/anomalies')
          .where('detectedAt', isGreaterThan: cutoffTime)
          .orderBy('detectedAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => AnomalyAlert.fromJson({
                ...doc.data(),
                'detectedAt': (doc['detectedAt'] as Timestamp).toDate(),
                'acknowledgedAt': doc['acknowledgedAt'] != null
                    ? (doc['acknowledgedAt'] as Timestamp).toDate()
                    : null,
              }))
          .toList();
    } catch (e) {
      throw Exception('Error getting recent anomalies: $e');
    }
  }

  Future<void> acknowledgeAnomaly(String alertId) async {
    try {
      await _firestore
          .collection('analytics/anomalies')
          .doc(alertId)
          .update({
            'acknowledged': true,
            'acknowledgedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error acknowledging anomaly: $e');
    }
  }

  Future<Map<String, dynamic>> getAnomalyStats({required int days = 7}) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('analytics/anomalies')
          .where('detectedAt', isGreaterThan: cutoffTime)
          .get();

      final severityCounts = <String, int>{
        'low': 0,
        'medium': 0,
        'high': 0,
        'critical': 0,
      };

      for (var doc in snapshot.docs) {
        final severity = doc['severity'] as String? ?? 'medium';
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }

      return {
        'totalAnomalies': snapshot.size,
        'severityCounts': severityCounts,
        'period': days,
        'averagePerDay': snapshot.size / days,
      };
    } catch (e) {
      throw Exception('Error getting anomaly stats: $e');
    }
  }

  void clearCache() {
    _metricHistory.clear();
    _lastResults.clear();
    _cacheTimestamps.clear();
  }

  // Private helper methods

  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateStdDev(List<double> values, double mean) {
    if (values.length < 2) return 0;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return math.sqrt(
      squaredDiffs.reduce((a, b) => a + b) / (values.length - 1),
    );
  }

  String _determineSeverity(double zScore) {
    if (zScore > 4.0) return 'critical';
    if (zScore > 3.5) return 'high';
    if (zScore > 3.0) return 'medium';
    return 'low';
  }

  String? _getRecommendedAction(
    String metricName,
    double value,
    double baseline,
  ) {
    if (metricName.contains('latency')) {
      if (value > baseline) {
        return 'Investigate query performance and check for indexing issues';
      }
    } else if (metricName.contains('cache')) {
      if (value < baseline) {
        return 'Review cache configuration and TTL settings';
      }
    } else if (metricName.contains('engagement')) {
      if (value < baseline) {
        return 'Investigate user engagement drop; check for issues or changes';
      }
    }
    return null;
  }

  String? _classifyAnomaly(double value, double mean, double stdDev) {
    if (stdDev == 0) return null;

    if (value > mean + (2 * stdDev)) {
      return 'spike';
    } else if (value < mean - (2 * stdDev)) {
      return 'drop';
    } else if ((value - mean).abs() > stdDev) {
      return 'trend';
    }
    return null;
  }

  Future<List<double>> _getMetricHistory(String metricName, int days) async {
    // Check cache first
    if (_metricHistory.containsKey(metricName)) {
      return _metricHistory[metricName]!;
    }

    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('analytics/performance_metrics')
          .where('operationName', isEqualTo: metricName)
          .where('timestamp', isGreaterThan: cutoffTime)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final values = snapshot.docs
          .map((doc) => (doc['durationMs'] as num).toDouble())
          .toList();

      _metricHistory[metricName] = values;
      return values;
    } catch (e) {
      return [];
    }
  }

  Future<List<QueryPerformanceTrend>> _getQueryTrends(
    String queryType,
    int days,
  ) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('analytics/query_trends')
          .where('queryType', isEqualTo: queryType)
          .where('period', isGreaterThan: cutoffTime)
          .orderBy('period', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => QueryPerformanceTrend.fromJson({
                ...doc.data(),
                'period': (doc['period'] as Timestamp).toDate(),
              }))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _storeAlerts(List<AnomalyAlert> alerts) async {
    try {
      for (var alert in alerts) {
        await _firestore
            .collection('analytics/anomalies')
            .doc(alert.alertId)
            .set(alert.toJson());
      }
    } catch (e) {
      // Log but don't throw - storage failure shouldn't break detection
      print('Error storing anomaly alerts: $e');
    }
  }

  Future<void> _storeRegressionAlert(
    String queryType,
    int currentP50,
    double avgP50,
    double degradation,
  ) async {
    try {
      final alert = AnomalyAlert(
        alertId: 'regression-$queryType-${DateTime.now().millisecondsSinceEpoch}',
        metricName: '$queryType-p50',
        detectedValue: currentP50.toDouble(),
        baselineValue: avgP50,
        anomalyScore: math.min(degradation, 1.0),
        detectedAt: DateTime.now(),
        severity: 'high',
        description:
            'Performance regression detected in $queryType: P50 increased from $avgP50ms to ${currentP50}ms',
        recommendedAction: 'Review recent changes and run performance profiling',
      );

      await _firestore
          .collection('analytics/anomalies')
          .doc(alert.alertId)
          .set(alert.toJson());
    } catch (e) {
      print('Error storing regression alert: $e');
    }
  }
}
