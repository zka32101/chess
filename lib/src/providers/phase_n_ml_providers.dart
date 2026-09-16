import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ml_models.dart';
import '../models/analytics_models.dart';
import '../services/anomaly_detection_service.dart';
import '../services/performance_forecasting_service.dart';
import '../services/churn_prediction_service.dart';
import '../services/user_clustering_service.dart';

// Service Providers
final anomalyDetectionServiceProvider = Provider<AnomalyDetectionService>((ref) {
  return AnomalyDetectionService.getInstance(FirebaseFirestore.instance);
});

final performanceForecastingServiceProvider =
    Provider<PerformanceForecastingService>((ref) {
  return PerformanceForecastingService.getInstance(FirebaseFirestore.instance);
});

final churnPredictionServiceProvider = Provider<ChurnPredictionService>((ref) {
  return ChurnPredictionService.getInstance(FirebaseFirestore.instance);
});

final userClusteringServiceProvider = Provider<UserClusteringService>((ref) {
  return UserClusteringService.getInstance(FirebaseFirestore.instance);
});

// Anomaly Detection Providers
final recentAnomaliesProvider = FutureProvider<List<AnomalyAlert>>((ref) async {
  final service = ref.watch(anomalyDetectionServiceProvider);
  return service.getRecentAnomalies(hours: 24);
});

final anomalyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(anomalyDetectionServiceProvider);
  return service.getAnomalyStats(days: 7);
});

final performanceAnomaliesProvider =
    FutureProvider.family<List<AnomalyAlert>, int>((ref, days) async {
  final service = ref.watch(anomalyDetectionServiceProvider);
  return service.getRecentAnomalies(hours: days * 24);
});

final engagementAnomaliesProvider =
    FutureProvider.family<List<AnomalyAlert>, String>((ref, metricName) async {
  final service = ref.watch(anomalyDetectionServiceProvider);
  final anomalies = await service.getRecentAnomalies(hours: 24);
  return anomalies
      .where((a) => a.metricName.contains(metricName))
      .toList();
});

final anomalyTrendProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, days) async {
  final service = ref.watch(anomalyDetectionServiceProvider);
  return service.getAnomalyStats(days: days);
});

// Forecasting Providers
final performanceForecastProvider = FutureProvider.family<
    PerformanceForecast,
    ({String queryType, int forecastDays})>((ref, params) async {
  final service = ref.watch(performanceForecastingServiceProvider);
  return service.forecastLatency(
    queryType: params.queryType,
    forecastDays: params.forecastDays,
  );
});

final userGrowthForecastProvider =
    FutureProvider<PerformanceForecast>((ref) async {
  final service = ref.watch(performanceForecastingServiceProvider);
  return service.forecastUserGrowth(forecastDays: 7);
});

final cacheHitRateForecastProvider =
    FutureProvider<PerformanceForecast>((ref) async {
  final service = ref.watch(performanceForecastingServiceProvider);
  return service.forecastCacheHitRate(forecastDays: 7);
});

final featureAdoptionForecastProvider = FutureProvider.family<
    PerformanceForecast,
    ({String feature, int forecastDays})>((ref, params) async {
  final service = ref.watch(performanceForecastingServiceProvider);
  return service.forecastFeatureAdoption(
    feature: params.feature,
    forecastDays: params.forecastDays,
  );
});

final forecastAccuracyProvider = FutureProvider.family<ForecastingMetrics, String>((ref, modelName) async {
  final service = ref.watch(performanceForecastingServiceProvider);
  return service.getModelMetrics(modelName);
});

// Churn Prediction Providers
final highRiskUsersProvider =
    FutureProvider.family<List<ChurnRiskProfile>, int>((ref, riskThreshold) async {
  final service = ref.watch(churnPredictionServiceProvider);
  return service.getHighRiskUsers(
    riskThreshold: riskThreshold,
    limit: 100,
  );
});

final userChurnRiskProvider = FutureProvider.family<ChurnRiskProfile, String>((ref, userId) async {
  final service = ref.watch(churnPredictionServiceProvider);
  return service.getPredictedChurnRisk(userId: userId);
});

final cohortChurnForecastProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, cohortDate) async {
  final service = ref.watch(churnPredictionServiceProvider);
  return service.getCohortChurnForecast(cohortDate: cohortDate);
});

final churnFactorAnalysisProvider = FutureProvider.family<List<ChurnFactor>, String>((ref, userId) async {
  final service = ref.watch(churnPredictionServiceProvider);
  return service.getChurnFactors(userId: userId);
});

final retentionOpportunitiesProvider =
    FutureProvider<List<RetentionOpportunity>>((ref) async {
  final service = ref.watch(churnPredictionServiceProvider);
  return service.getRetentionOpportunities(limit: 50);
});

final churnReportProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, daysLookback) async {
  final service = ref.watch(churnPredictionServiceProvider);
  return service.generateChurnReport(daysLookback: daysLookback);
});

// User Clustering Providers
final allUserClustersProvider =
    FutureProvider<List<UserCluster>>((ref) async {
  final service = ref.watch(userClusteringServiceProvider);
  return service.getAllClusters();
});

final userClusterProvider = FutureProvider.family<UserCluster?, String>((ref, userId) async {
  final service = ref.watch(userClusteringServiceProvider);
  return service.getUserCluster(userId: userId);
});

final clusterCharacteristicsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, clusterId) async {
  final service = ref.watch(userClusteringServiceProvider);
  return service.getClusterCharacteristics(clusterId: clusterId);
});

final clusterStatisticsProvider = FutureProvider.family<ClusterStatistics, int>((ref, clusterId) async {
  final service = ref.watch(userClusteringServiceProvider);
  return service.getClusterStatistics(clusterId: clusterId);
});

final clusterComparisonProvider = FutureProvider.family<
    UserSegmentComparison,
    ({int cluster1Id, int cluster2Id})>((ref, params) async {
  final service = ref.watch(userClusteringServiceProvider);
  return service.compareSegments(
    cluster1Id: params.cluster1Id,
    cluster2Id: params.cluster2Id,
  );
});

// ML Insights Aggregate Providers
final mlInsightsSummaryProvider =
    FutureProvider<MLInsightsSummary>((ref) async {
  final anomaliesAsync = ref.watch(recentAnomaliesProvider);
  final highRiskAsync = ref.watch(highRiskUsersProvider(60));

  return anomaliesAsync.when(
    loading: () => MLInsightsSummary(
      activeAnomalies: 0,
      highRiskUsers: 0,
      topAnomalies: [],
      topForecasts: [],
      recommendedActions: [],
      generatedAt: DateTime.now(),
    ),
    error: (err, stack) => MLInsightsSummary(
      activeAnomalies: 0,
      highRiskUsers: 0,
      topAnomalies: [],
      topForecasts: [],
      recommendedActions: [],
      generatedAt: DateTime.now(),
    ),
    data: (anomalies) => highRiskAsync.when(
      loading: () => MLInsightsSummary(
        activeAnomalies: anomalies.length,
        highRiskUsers: 0,
        topAnomalies:
            anomalies.take(3).map((a) => a.metricName).toList(),
        topForecasts: [],
        recommendedActions: [],
        generatedAt: DateTime.now(),
      ),
      error: (err, stack) => MLInsightsSummary(
        activeAnomalies: anomalies.length,
        highRiskUsers: 0,
        topAnomalies:
            anomalies.take(3).map((a) => a.metricName).toList(),
        topForecasts: [],
        recommendedActions: [],
        generatedAt: DateTime.now(),
      ),
      data: (highRiskUsers) => MLInsightsSummary(
        activeAnomalies: anomalies.length,
        highRiskUsers: highRiskUsers.length,
        topAnomalies:
            anomalies.take(3).map((a) => a.metricName).toList(),
        topForecasts: [],
        recommendedActions:
            highRiskUsers.take(3).map((u) => u.recommendedAction).toList(),
        generatedAt: DateTime.now(),
        criticalAlerts:
            anomalies.where((a) => a.severity == 'critical').length,
        warningAlerts: anomalies.where((a) => a.severity == 'high').length,
      ),
    ),
  );
});

final mlAlertsProvider = FutureProvider<List<AnomalyAlert>>((ref) async {
  final service = ref.watch(anomalyDetectionServiceProvider);
  return service.getRecentAnomalies(hours: 48);
});

final recommendedActionsProvider =
    FutureProvider<List<String>>((ref) async {
  final summaryAsync = ref.watch(mlInsightsSummaryProvider);

  return summaryAsync.when(
    loading: () => [],
    error: (err, stack) => [],
    data: (summary) => summary.recommendedActions,
  );
});

// Performance Comparison Providers
final performanceComparison = FutureProvider<Map<String, dynamic>>((ref) async {
  final leaderboardForecast = ref.watch(
    performanceForecastProvider((queryType: 'leaderboard', forecastDays: 7)),
  );

  return leaderboardForecast.when(
    loading: () => {'queryTypes': [], 'latencies': []},
    error: (err, stack) => {'queryTypes': [], 'latencies': []},
    data: (forecast) => {
      'queryTypes': ['leaderboard', 'friends', 'challenges'],
      'latencies': [
        forecast.forecastValues.isNotEmpty
            ? forecast.forecastValues.first.toInt()
            : 150,
        160,
        170,
      ],
    },
  );
});

// Cache Control Notifiers for manual operations
final anomalyDetectionCacheNotifierProvider =
    StateNotifierProvider<AnomalyCacheNotifier, bool>((ref) {
  return AnomalyCacheNotifier();
});

class AnomalyCacheNotifier extends StateNotifier<bool> {
  AnomalyCacheNotifier() : super(false);

  void clearCache(AnomalyDetectionService service) {
    service.clearCache();
    state = !state; // Toggle to trigger refresh
  }
}

final forecastingCacheNotifierProvider =
    StateNotifierProvider<ForecastingCacheNotifier, bool>((ref) {
  return ForecastingCacheNotifier();
});

class ForecastingCacheNotifier extends StateNotifier<bool> {
  ForecastingCacheNotifier() : super(false);

  void clearCache(PerformanceForecastingService service) {
    service.clearCache();
    state = !state;
  }
}

final churnCacheNotifierProvider =
    StateNotifierProvider<ChurnCacheNotifier, bool>((ref) {
  return ChurnCacheNotifier();
});

class ChurnCacheNotifier extends StateNotifier<bool> {
  ChurnCacheNotifier() : super(false);

  void clearCache(ChurnPredictionService service) {
    service.clearCache();
    state = !state;
  }
}

final clusteringCacheNotifierProvider =
    StateNotifierProvider<ClusteringCacheNotifier, bool>((ref) {
  return ClusteringCacheNotifier();
});

class ClusteringCacheNotifier extends StateNotifier<bool> {
  ClusteringCacheNotifier() : super(false);

  void clearCache(UserClusteringService service) {
    service.clearCache();
    state = !state;
  }
}
