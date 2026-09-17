import 'package:freezed_annotation/freezed_annotation.dart';

part 'ml_models.freezed.dart';
part 'ml_models.g.dart';

@freezed
class AnomalyAlert with _$AnomalyAlert {
  const factory AnomalyAlert({
    required String alertId,
    required String metricName,
    required double detectedValue,
    required double baselineValue,
    required double anomalyScore,
    required DateTime detectedAt,
    required String severity, // 'low', 'medium', 'high', 'critical'
    required String description,
    String? recommendedAction,
    @Default(false) bool acknowledged,
    DateTime? acknowledgedAt,
  }) = _AnomalyAlert;

  factory AnomalyAlert.fromJson(Map<String, dynamic> json) =>
      _$AnomalyAlertFromJson(json);
}

@freezed
class PerformanceForecast with _$PerformanceForecast {
  const factory PerformanceForecast({
    required String metricName,
    required List<DateTime> forecastDates,
    required List<double> forecastValues,
    required List<double> confidenceLower90,
    required List<double> confidenceUpper90,
    required List<double> confidenceLower95,
    required List<double> confidenceUpper95,
    required DateTime generatedAt,
    required double rmse,
    required double r2Score,
    required String trendDirection, // 'up', 'down', 'stable'
  }) = _PerformanceForecast;

  factory PerformanceForecast.fromJson(Map<String, dynamic> json) =>
      _$PerformanceForecastFromJson(json);
}

@freezed
class ChurnRiskProfile with _$ChurnRiskProfile {
  const factory ChurnRiskProfile({
    required String userId,
    required double churnProbability14Day,
    required double churnProbability30Day,
    required List<String> topRiskFactors,
    @Default({}) Map<String, double> riskFactorWeights,
    required String riskSegment, // 'low', 'medium', 'high', 'critical'
    required String recommendedAction,
    required DateTime calculatedAt,
    DateTime? nextReviewDate,
  }) = _ChurnRiskProfile;

  factory ChurnRiskProfile.fromJson(Map<String, dynamic> json) =>
      _$ChurnRiskProfileFromJson(json);
}

@freezed
class UserCluster with _$UserCluster {
  const factory UserCluster({
    required int clusterId,
    required int clusterSize,
    required String clusterLabel, // e.g., "Casual Players", "Power Users"
    required String description,
    required Map<String, dynamic> characteristics,
    required Map<String, double> avgMetrics,
    required double engagementScore,
    required double retentionRate,
    @Default({}) Map<String, int> featureUsage,
    required DateTime lastUpdated,
  }) = _UserCluster;

  factory UserCluster.fromJson(Map<String, dynamic> json) =>
      _$UserClusterFromJson(json);
}

@freezed
class AnomalyDetectionResult with _$AnomalyDetectionResult {
  const factory AnomalyDetectionResult({
    required String metricName,
    required double value,
    required double mean,
    required double stdDev,
    required double zScore,
    required bool isAnomaly,
    required double anomalyScore, // 0.0 to 1.0
    @Default(null) String? anomalyType, // 'spike', 'drop', 'trend'
  }) = _AnomalyDetectionResult;

  factory AnomalyDetectionResult.fromJson(Map<String, dynamic> json) =>
      _$AnomalyDetectionResultFromJson(json);
}

@freezed
class ForecastingMetrics with _$ForecastingMetrics {
  const factory ForecastingMetrics({
    required String modelName,
    required double rmse,
    required double mae,
    required double r2Score,
    required double mape,
    required int trainingDataPoints,
    required DateTime trainedAt,
    @Default(0.0) double accuracy,
  }) = _ForecastingMetrics;

  factory ForecastingMetrics.fromJson(Map<String, dynamic> json) =>
      _$ForecastingMetricsFromJson(json);
}

@freezed
class ChurnFactor with _$ChurnFactor {
  const factory ChurnFactor({
    required String factorName,
    required double weight,
    required double contribution,
    required String interpretation, // e.g., "Days since signup"
    @Default(false) bool isPositive, // true = retention factor
  }) = _ChurnFactor;

  factory ChurnFactor.fromJson(Map<String, dynamic> json) =>
      _$ChurnFactorFromJson(json);
}

@freezed
class ClusterStatistics with _$ClusterStatistics {
  const factory ClusterStatistics({
    required int clusterId,
    required double silhouetteScore,
    required double daviesBouldinIndex,
    required double clusterStability,
    required Map<String, double> centroid,
    required List<String> topCharacteristics,
    required int totalUsers,
    required DateTime calculatedAt,
  }) = _ClusterStatistics;

  factory ClusterStatistics.fromJson(Map<String, dynamic> json) =>
      _$ClusterStatisticsFromJson(json);
}

@freezed
class MLInsightsSummary with _$MLInsightsSummary {
  const factory MLInsightsSummary({
    required int activeAnomalies,
    required int highRiskUsers,
    required List<String> topAnomalies,
    required List<String> topForecasts,
    required List<String> recommendedActions,
    required DateTime generatedAt,
    @Default(0) int criticalAlerts,
    @Default(0) int warningAlerts,
  }) = _MLInsightsSummary;

  factory MLInsightsSummary.fromJson(Map<String, dynamic> json) =>
      _$MLInsightsSummaryFromJson(json);
}

@freezed
class RetentionOpportunity with _$RetentionOpportunity {
  const factory RetentionOpportunity({
    required String userId,
    required double churnRisk,
    required String recommendedOffer,
    required String targetReason,
    required double expectedRetentionImpact,
    required DateTime identifiedAt,
    @Default(false) bool actionTaken,
    DateTime? actionTakenAt,
  }) = _RetentionOpportunity;

  factory RetentionOpportunity.fromJson(Map<String, dynamic> json) =>
      _$RetentionOpportunityFromJson(json);
}

@freezed
class FeatureTrend with _$FeatureTrend {
  const factory FeatureTrend({
    required String featureName,
    required List<DateTime> dates,
    required List<int> usageCount,
    required String trendDirection, // 'up', 'down', 'stable'
    required double growthRate,
    required DateTime forecastedPeak,
    required int forecastedPeakValue,
    @Default(0.0) double adoptionRate,
  }) = _FeatureTrend;

  factory FeatureTrend.fromJson(Map<String, dynamic> json) =>
      _$FeatureTrendFromJson(json);
}

@freezed
class MLModelMetadata with _$MLModelMetadata {
  const factory MLModelMetadata({
    required String modelName,
    required String modelType, // 'anomaly_detection', 'forecasting', 'churn_prediction', 'clustering'
    required String algorithm,
    required Map<String, dynamic> hyperparameters,
    required ForecastingMetrics performanceMetrics,
    required DateTime trainedAt,
    required DateTime validatedAt,
    required int dataPointsUsed,
    @Default(false) bool isProduction,
  }) = _MLModelMetadata;

  factory MLModelMetadata.fromJson(Map<String, dynamic> json) =>
      _$MLModelMetadataFromJson(json);
}

@freezed
class UserSegmentComparison with _$UserSegmentComparison {
  const factory UserSegmentComparison({
    required int cluster1Id,
    required int cluster2Id,
    required Map<String, double> differenceMetrics,
    required List<String> distinctCharacteristics,
    required double overlapPercentage,
    required DateTime comparedAt,
  }) = _UserSegmentComparison;

  factory UserSegmentComparison.fromJson(Map<String, dynamic> json) =>
      _$UserSegmentComparisonFromJson(json);
}
