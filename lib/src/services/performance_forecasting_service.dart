import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ml_models.dart';
import '../models/analytics_models.dart';
import 'dart:math' as math;

class PerformanceForecastingService {
  final FirebaseFirestore _firestore;
  static PerformanceForecastingService? _instance;

  final Duration _cacheDuration = const Duration(hours: 1);
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, PerformanceForecast> _forecasts = {};

  PerformanceForecastingService(this._firestore);

  static PerformanceForecastingService getInstance(FirebaseFirestore firestore) {
    _instance ??= PerformanceForecastingService(firestore);
    return _instance!;
  }

  Future<PerformanceForecast> forecastLatency({
    required String queryType,
    required int forecastDays = 7,
    int historyDays = 30,
  }) async {
    try {
      // Check cache
      final cacheKey = '$queryType-latency-$forecastDays';
      if (_isCacheValid(cacheKey)) {
        return _forecasts[cacheKey]!;
      }

      // Get historical data
      final trends = await _getQueryTrends(queryType, historyDays);
      if (trends.length < 3) {
        throw Exception('Insufficient data for forecasting');
      }

      // Extract P50 values
      final values = trends.map((t) => t.p50Latency.toDouble()).toList();
      final dates = trends.map((t) => t.period).toList();

      // Apply exponential smoothing
      final forecast = _exponentialSmoothing(
        values,
        dates,
        forecastDays,
        alpha: 0.2,
      );

      // Calculate metrics
      final metrics = _calculateForecastMetrics(values, forecast);

      _forecasts[cacheKey] = forecast;
      _cacheTimestamps[cacheKey] = DateTime.now();

      // Store in Firestore
      await _storeForecasts(forecast);

      return forecast;
    } catch (e) {
      throw Exception('Error forecasting latency: $e');
    }
  }

  Future<PerformanceForecast> forecastUserGrowth({
    required int forecastDays = 7,
    int historyDays = 30,
  }) async {
    try {
      final cacheKey = 'user_growth-$forecastDays';
      if (_isCacheValid(cacheKey)) {
        return _forecasts[cacheKey]!;
      }

      // Mock user growth data - in production, get from actual DAU metrics
      final values = await _getUserGrowthMetrics(historyDays);
      if (values.isEmpty) {
        throw Exception('No user growth data available');
      }

      final dates = List.generate(
        values.length,
        (i) => DateTime.now().subtract(Duration(days: values.length - i - 1)),
      );

      // Apply linear regression for trend
      final forecast = _linearRegression(
        values,
        dates,
        forecastDays,
      );

      final metrics = _calculateForecastMetrics(values, forecast);

      _forecasts[cacheKey] = forecast;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return forecast;
    } catch (e) {
      throw Exception('Error forecasting user growth: $e');
    }
  }

  Future<PerformanceForecast> forecastCacheHitRate({
    required int forecastDays = 7,
    int historyDays = 30,
  }) async {
    try {
      final cacheKey = 'cache_hitrate-$forecastDays';
      if (_isCacheValid(cacheKey)) {
        return _forecasts[cacheKey]!;
      }

      // Get historical cache analytics
      final cacheAnalytics = await _getCacheAnalytics(historyDays);
      if (cacheAnalytics.isEmpty) {
        throw Exception('No cache analytics available');
      }

      final values = cacheAnalytics.map((c) => c.hitRate * 100).toList();
      final dates = cacheAnalytics.map((c) => c.period).toList();

      // Apply exponential smoothing
      final forecast = _exponentialSmoothing(
        values,
        dates,
        forecastDays,
        alpha: 0.15,
      );

      final metrics = _calculateForecastMetrics(values, forecast);

      _forecasts[cacheKey] = forecast;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return forecast;
    } catch (e) {
      throw Exception('Error forecasting cache hit rate: $e');
    }
  }

  Future<PerformanceForecast> forecastFeatureAdoption({
    required String feature,
    required int forecastDays = 7,
    int historyDays = 30,
  }) async {
    try {
      final cacheKey = '$feature-adoption-$forecastDays';
      if (_isCacheValid(cacheKey)) {
        return _forecasts[cacheKey]!;
      }

      // Get feature adoption trend
      final features = await _getFeatureStats(feature, historyDays);
      if (features.isEmpty) {
        throw Exception('No feature adoption data');
      }

      final values = features.map((f) => f.activeUsers.toDouble()).toList();
      final dates = features.map((f) => f.period).toList();

      // Apply exponential smoothing
      final forecast = _exponentialSmoothing(
        values,
        dates,
        forecastDays,
        alpha: 0.25,
      );

      final metrics = _calculateForecastMetrics(values, forecast);

      _forecasts[cacheKey] = forecast;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return forecast;
    } catch (e) {
      throw Exception('Error forecasting feature adoption: $e');
    }
  }

  Future<ForecastingMetrics> getModelMetrics(String modelName) async {
    try {
      final doc = await _firestore
          .collection('analytics/ml_models')
          .doc(modelName)
          .get();

      if (!doc.exists) {
        throw Exception('Model not found: $modelName');
      }

      return ForecastingMetrics.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Error getting model metrics: $e');
    }
  }

  void clearCache() {
    _forecasts.clear();
    _cacheTimestamps.clear();
  }

  // Private helper methods

  bool _isCacheValid(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;
    final cacheTime = _cacheTimestamps[key]!;
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  PerformanceForecast _exponentialSmoothing(
    List<double> values,
    List<DateTime> dates,
    int forecastDays, {
    double alpha = 0.2,
  }) {
    if (values.isEmpty) {
      throw Exception('No values to forecast');
    }

    // Calculate smoothed values
    final smoothed = <double>[values[0]];
    for (int i = 1; i < values.length; i++) {
      smoothed.add(alpha * values[i] + (1 - alpha) * smoothed[i - 1]);
    }

    final lastSmoothed = smoothed.last;
    final trend = _calculateTrend(smoothed);

    // Forecast future values
    final forecastValues = <double>[];
    final forecastDates = <DateTime>[];
    var forecastValue = lastSmoothed;

    for (int i = 0; i < forecastDays; i++) {
      forecastValue += trend;
      forecastValues.add(math.max(0, forecastValue));
      forecastDates.add(dates.last.add(Duration(days: i + 1)));
    }

    // Calculate confidence intervals
    final stdDev = _calculateStdDev(values);
    final confidenceLower90 =
        forecastValues.map((v) => math.max(0, v - 1.645 * stdDev)).toList();
    final confidenceUpper90 =
        forecastValues.map((v) => v + 1.645 * stdDev).toList();
    final confidenceLower95 =
        forecastValues.map((v) => math.max(0, v - 1.96 * stdDev)).toList();
    final confidenceUpper95 =
        forecastValues.map((v) => v + 1.96 * stdDev).toList();

    // Calculate metrics
    final mean = _calculateMean(values);
    final residuals = values
        .asMap()
        .entries
        .map((e) => (e.value - smoothed[e.key]) * (e.value - smoothed[e.key]))
        .toList();
    final rmse = math.sqrt(residuals.reduce((a, b) => a + b) / residuals.length);
    final r2 = 1 - (residuals.reduce((a, b) => a + b) /
        values.asMap()
            .entries
            .map((e) => (e.value - mean) * (e.value - mean))
            .reduce((a, b) => a + b));

    return PerformanceForecast(
      metricName: 'performance',
      forecastDates: forecastDates,
      forecastValues: forecastValues,
      confidenceLower90: confidenceLower90,
      confidenceUpper90: confidenceUpper90,
      confidenceLower95: confidenceLower95,
      confidenceUpper95: confidenceUpper95,
      generatedAt: DateTime.now(),
      rmse: rmse,
      r2Score: math.max(0, math.min(r2, 1.0)),
      trendDirection: trend > 0 ? 'up' : (trend < 0 ? 'down' : 'stable'),
    );
  }

  PerformanceForecast _linearRegression(
    List<double> values,
    List<DateTime> dates,
    int forecastDays,
  ) {
    if (values.length < 2) {
      throw Exception('Insufficient data for linear regression');
    }

    // Calculate regression line: y = a + b*x
    final n = values.length;
    final xMean = (n - 1) / 2.0;
    final yMean = values.reduce((a, b) => a + b) / n;

    var sumXY = 0.0;
    var sumX2 = 0.0;

    for (int i = 0; i < n; i++) {
      final x = i - xMean;
      final y = values[i] - yMean;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = sumX2 == 0 ? 0 : sumXY / sumX2;
    final intercept = yMean - slope * xMean;

    // Forecast future values
    final forecastValues = <double>[];
    final forecastDates = <DateTime>[];

    for (int i = 0; i < forecastDays; i++) {
      final x = (n - 1) + i + 1;
      forecastValues.add(math.max(0, intercept + slope * x));
      forecastDates.add(dates.last.add(Duration(days: i + 1)));
    }

    // Calculate metrics
    final residuals = values.asMap().entries.map((e) {
      final x = e.key - xMean;
      final predicted = intercept + slope * x;
      return (e.value - predicted) * (e.value - predicted);
    }).toList();

    final rmse = math.sqrt(residuals.reduce((a, b) => a + b) / residuals.length);
    final mean = yMean;
    final ssTotal = values.fold<double>(0, (sum, v) => sum + (v - mean) * (v - mean));
    final ssRes = residuals.reduce((a, b) => a + b);
    final r2 = ssTotal == 0 ? 0 : 1 - (ssRes / ssTotal);

    return PerformanceForecast(
      metricName: 'user_growth',
      forecastDates: forecastDates,
      forecastValues: forecastValues,
      confidenceLower90: forecastValues.map((v) => math.max(0, v - 1.645 * rmse)).toList(),
      confidenceUpper90: forecastValues.map((v) => v + 1.645 * rmse).toList(),
      confidenceLower95: forecastValues.map((v) => math.max(0, v - 1.96 * rmse)).toList(),
      confidenceUpper95: forecastValues.map((v) => v + 1.96 * rmse).toList(),
      generatedAt: DateTime.now(),
      rmse: rmse,
      r2Score: math.max(0, math.min(r2, 1.0)),
      trendDirection: slope > 0 ? 'up' : (slope < 0 ? 'down' : 'stable'),
    );
  }

  double _calculateTrend(List<double> smoothed) {
    if (smoothed.length < 2) return 0;
    return (smoothed.last - smoothed[smoothed.length - 2]) * 0.5;
  }

  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = _calculateMean(values);
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return math.sqrt(squaredDiffs.reduce((a, b) => a + b) / (values.length - 1));
  }

  ForecastingMetrics _calculateForecastMetrics(
    List<double> actual,
    PerformanceForecast forecast,
  ) {
    return ForecastingMetrics(
      modelName: 'exponential_smoothing',
      rmse: forecast.rmse,
      mae: _calculateMAE(actual),
      r2Score: forecast.r2Score,
      mape: _calculateMAPE(actual),
      trainingDataPoints: actual.length,
      trainedAt: DateTime.now(),
      accuracy: forecast.r2Score * 100,
    );
  }

  double _calculateMAE(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = _calculateMean(values);
    return values.map((v) => (v - mean).abs()).reduce((a, b) => a + b) / values.length;
  }

  double _calculateMAPE(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = _calculateMean(values);
    var sum = 0.0;
    for (var v in values) {
      if (mean != 0) {
        sum += ((v - mean).abs() / mean.abs());
      }
    }
    return (sum / values.length) * 100;
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

  Future<List<double>> _getUserGrowthMetrics(int days) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection('analytics/daily_snapshots')
          .where('date', isGreaterThan: cutoffTime)
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => (doc['activeUsers'] as num).toDouble())
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<CacheAnalytics>> _getCacheAnalytics(int days) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection('analytics/cache_analytics')
          .where('period', isGreaterThan: cutoffTime)
          .orderBy('period', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => CacheAnalytics.fromJson({
                ...doc.data(),
                'period': (doc['period'] as Timestamp).toDate(),
                'avgCacheLookup': Duration(
                  milliseconds: (doc['avgCacheLookup'] as num).toInt(),
                ),
              }))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<CompetitiveFeatureStats>> _getFeatureStats(
    String feature,
    int days,
  ) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection('analytics/competitive_features')
          .where('feature', isEqualTo: feature)
          .where('period', isGreaterThan: cutoffTime)
          .orderBy('period', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => CompetitiveFeatureStats.fromJson({
                ...doc.data(),
                'period': (doc['period'] as Timestamp).toDate(),
              }))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _storeForecasts(PerformanceForecast forecast) async {
    try {
      await _firestore
          .collection('analytics/forecasts')
          .doc('${forecast.metricName}-${DateTime.now().millisecondsSinceEpoch}')
          .set(forecast.toJson());
    } catch (e) {
      print('Error storing forecast: $e');
    }
  }
}
