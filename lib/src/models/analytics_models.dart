import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_models.freezed.dart';
part 'analytics_models.g.dart';

@freezed
class PerformanceMetrics with _$PerformanceMetrics {
  const factory PerformanceMetrics({
    required String operationName,
    required int durationMs,
    required DateTime timestamp,
    required bool success,
    String? errorType,
    @Default({}) Map<String, dynamic> metadata,
  }) = _PerformanceMetrics;

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);
}

@freezed
class QueryPerformanceTrend with _$QueryPerformanceTrend {
  const factory QueryPerformanceTrend({
    required String queryType,
    required int p50Latency,
    required int p95Latency,
    required int p99Latency,
    required double successRate,
    required DateTime period,
    required int sampleCount,
  }) = _QueryPerformanceTrend;

  factory QueryPerformanceTrend.fromJson(Map<String, dynamic> json) =>
      _$QueryPerformanceTrendFromJson(json);
}

@freezed
class UserEngagementMetrics with _$UserEngagementMetrics {
  const factory UserEngagementMetrics({
    required String userId,
    required int sessionsCount,
    required Duration totalPlayTime,
    required DateTime lastActive,
    @Default({}) Map<String, int> featureUsage,
    required bool churnedUser,
  }) = _UserEngagementMetrics;

  factory UserEngagementMetrics.fromJson(Map<String, dynamic> json) =>
      _$UserEngagementMetricsFromJson(json);
}

@freezed
class CacheAnalytics with _$CacheAnalytics {
  const factory CacheAnalytics({
    required String cacheName,
    required int hitCount,
    required int missCount,
    required double hitRate,
    required Duration avgCacheLookup,
    required int evictionCount,
    required DateTime period,
  }) = _CacheAnalytics;

  factory CacheAnalytics.fromJson(Map<String, dynamic> json) =>
      _$CacheAnalyticsFromJson(json);
}

@freezed
class CompetitiveFeatureStats with _$CompetitiveFeatureStats {
  const factory CompetitiveFeatureStats({
    required String feature,
    required int activeUsers,
    required int totalInteractions,
    required double adoptionRate,
    @Default({}) Map<String, dynamic> topMetrics,
    required DateTime period,
  }) = _CompetitiveFeatureStats;

  factory CompetitiveFeatureStats.fromJson(Map<String, dynamic> json) =>
      _$CompetitiveFeatureStatsFromJson(json);
}

@freezed
class RetentionMetrics with _$RetentionMetrics {
  const factory RetentionMetrics({
    required String cohortDate,
    required int cohortSize,
    @Default({}) Map<String, int> retentionByDay,
    required double day1Retention,
    required double day7Retention,
    required double day30Retention,
  }) = _RetentionMetrics;

  factory RetentionMetrics.fromJson(Map<String, dynamic> json) =>
      _$RetentionMetricsFromJson(json);
}

@freezed
class BuildMetrics with _$BuildMetrics {
  const factory BuildMetrics({
    required String version,
    required int apkSizeMb,
    required int codeSizeMb,
    required int assetsSizeMb,
    required int librariesSizeMb,
    required DateTime buildDate,
    @Default({}) Map<String, dynamic> optimizationMetrics,
  }) = _BuildMetrics;

  factory BuildMetrics.fromJson(Map<String, dynamic> json) =>
      _$BuildMetricsFromJson(json);
}

@freezed
class DashboardKPI with _$DashboardKPI {
  const factory DashboardKPI({
    required String label,
    required String value,
    required String unit,
    String? trend,
    String? trendPercent,
  }) = _DashboardKPI;

  factory DashboardKPI.fromJson(Map<String, dynamic> json) =>
      _$DashboardKPIFromJson(json);
}
