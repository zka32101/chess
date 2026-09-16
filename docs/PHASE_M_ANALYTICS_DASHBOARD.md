# Phase M: Analytics Dashboard - Implementation Specification

**Phase Status:** Planning  
**Date Started:** 2026-09-16  
**Target Duration:** 2-3 days  
**Owner:** Claude Code (AI)

---

## Executive Summary

Phase M implements a comprehensive analytics dashboard that visualizes performance metrics collected during Phase L, tracks user engagement patterns, and provides insights into competitive gaming features from Phase K. The dashboard integrates with performance monitoring infrastructure, caches analytics data efficiently, and delivers real-time metrics visualization.

**Key Metrics:**
- Query performance trends (historical + real-time)
- User engagement analytics (daily/weekly/monthly)
- Cache effectiveness metrics
- Build optimization impact tracking
- Competitive feature adoption rates

---

## Phase M Architecture

### Overview

```
Phase M Analytics Dashboard
├── 1. Analytics Services (Data collection & aggregation)
├── 2. Analytics Models (Type-safe data structures)
├── 3. Riverpod Providers (State management & reactivity)
├── 4. Dashboard UI (Visualization & interactivity)
├── 5. Firestore Integration (Data persistence)
└── 6. Real-time Monitoring (Performance tracking)
```

### Key Components

#### 1. Analytics Services

**AnalyticsService** - Core analytics data collection
- `trackQueryPerformance()` - Record query execution times
- `trackUserEngagement()` - Record user actions
- `trackCacheMetrics()` - Record cache hit/miss data
- `getPerformanceTrends()` - Retrieve performance history
- `getUserEngagementStats()` - Get engagement metrics
- `getCacheAnalytics()` - Get cache performance data
- `getCompetitiveFeatureUsage()` - Track Phase K adoption

**TrendAggregationService** - Historical trend analysis
- `aggregateDailyMetrics()` - Daily performance rollup
- `aggregateWeeklyMetrics()` - Weekly trend analysis
- `calculatePercentileMetrics()` - P50, P95, P99 latency
- `identifyPerformanceRegression()` - Detect slowdowns
- `generateTrendReport()` - Create trend summaries

**CohortAnalyticsService** - User cohort analysis
- `getUserCohort()` - Segment users by signup date
- `getRetentionMetrics()` - Track user retention rates
- `getChurnAnalytics()` - Identify churned users
- `comparePerformanceBySegment()` - Segment-level analysis
- `generateCohortReport()` - Cohort performance report

#### 2. Analytics Models

**PerformanceMetrics**
```dart
class PerformanceMetrics {
  final String operationName;
  final int durationMs;
  final DateTime timestamp;
  final bool success;
  final String? errorType;
  final Map<String, dynamic> metadata;
}
```

**QueryPerformanceTrend**
```dart
class QueryPerformanceTrend {
  final String queryType;        // e.g., "leaderboard", "friends"
  final int p50Latency;          // Median
  final int p95Latency;          // 95th percentile
  final int p99Latency;          // 99th percentile
  final double successRate;
  final DateTime period;
  final int sampleCount;
}
```

**UserEngagementMetrics**
```dart
class UserEngagementMetrics {
  final String userId;
  final int sessionsCount;
  final Duration totalPlayTime;
  final DateTime lastActive;
  final Map<String, int> featureUsage;  // Feature -> count
  final bool churnedUser;
}
```

**CacheAnalytics**
```dart
class CacheAnalytics {
  final String cacheName;
  final int hitCount;
  final int missCount;
  final double hitRate;           // hitCount / (hitCount + missCount)
  final Duration avgCacheLookup;
  final int evictionCount;
  final DateTime period;
}
```

**CompetitiveFeatureStats**
```dart
class CompetitiveFeatureStats {
  final String feature;           // "leaderboard", "challenges", "tournaments"
  final int activeUsers;
  final int totalInteractions;
  final double adoptionRate;      // activeUsers / totalUsers
  final Map<String, dynamic> topMetrics;
  final DateTime period;
}
```

#### 3. Riverpod Providers (18+ providers)

**Service Providers:**
- `analyticsServiceProvider` - Analytics service singleton
- `trendAggregationServiceProvider` - Trend analysis service
- `cohortAnalyticsServiceProvider` - Cohort analytics service

**Performance Providers:**
- `queryPerformanceTrendsProvider` - Historical query performance
- `queryPerformanceTrendsFamilyProvider` - By query type
- `performanceRegressionProvider` - Detected regressions
- `latencyPercentileProvider` - P50/P95/P99 metrics

**Engagement Providers:**
- `userEngagementMetricsProvider` - User engagement data
- `userEngagementFamilyProvider` - By user segment
- `retentionMetricsProvider` - User retention rates
- `churnRiskProvider` - Churn prediction

**Cache Providers:**
- `cacheAnalyticsProvider` - Cache performance data
- `cacheHitRateProvider` - Cache hit rate metrics
- `cacheEvictionAnalyticsProvider` - Eviction patterns

**Competitive Feature Providers:**
- `competitiveFeatureStatsProvider` - Feature adoption
- `leaderboardAdoptionProvider` - Leaderboard usage
- `challengeAdoptionProvider` - Challenge system usage
- `tournamentAdoptionProvider` - Tournament adoption

#### 4. Dashboard UI Components

**DashboardHome**
- Real-time metrics cards (top-level KPIs)
- Navigation to detailed dashboards
- Quick stats: APK size, query P50, cache hit rate, DAU

**PerformanceDashboard**
- Line chart: Query performance over time (7/30/90 day views)
- Latency breakdown: P50, P95, P99 comparisons
- Query type performance comparison
- Regression alerts and anomaly detection

**EngagementDashboard**
- DAU/MAU trends (line chart)
- User retention cohort analysis (heatmap)
- Feature adoption rates (bar chart)
- Session duration distribution

**CacheDashboard**
- Cache hit rate trends (line chart)
- Cache type comparison (bar chart)
- Eviction patterns (time series)
- Memory usage metrics

**CompetitiveFeaturesDashboard**
- Feature adoption rates (leaderboard, challenges, tournaments)
- Active user counts per feature
- Feature interaction heatmap
- Top metrics by feature

**BuildOptimizationDashboard**
- APK size history (line chart)
- Asset optimization impact
- Build time analysis
- Size comparison: baseline vs optimized

#### 5. Data Persistence

**Firestore Collections:**

```
analytics/
├── performance_metrics/ (daily rollup)
│   ├── {date}/
│   │   └── {operationType} - PerformanceMetrics
│
├── query_trends/ (aggregated by day/week/month)
│   ├── {period}/
│   │   ├── leaderboard - QueryPerformanceTrend
│   │   ├── friends - QueryPerformanceTrend
│   │   ├── challenges - QueryPerformanceTrend
│   │   └── tournaments - QueryPerformanceTrend
│
├── user_engagement/
│   ├── {userId}/ - UserEngagementMetrics
│
├── cache_analytics/ (daily snapshots)
│   ├── {date}/
│   │   ├── smart_cache - CacheAnalytics
│   │   ├── composite_cache - CacheAnalytics
│   │   └── monitored_cache - CacheAnalytics
│
├── competitive_features/
│   ├── {date}/
│   │   ├── leaderboard - CompetitiveFeatureStats
│   │   ├── challenges - CompetitiveFeatureStats
│   │   └── tournaments - CompetitiveFeatureStats
│
└── build_metrics/ (per release)
    ├── {version}/
    │   └── BuildMetrics
```

### 6. Real-time Monitoring

**Metrics Collection Points:**
- Phase L PerformanceMonitor → Analytics Service
- Phase L Cache operations → CacheAnalytics
- Phase K Service interactions → UserEngagement
- App startup/shutdown → EngagementMetrics

**Update Frequency:**
- Real-time metrics: Every operation
- Minute-level aggregation: Every 60s
- Daily rollup: Midnight UTC
- Weekly/monthly: Automated batch jobs

---

## Implementation Tasks

### M-1: Analytics Models & Types (Day 1)
- [ ] Create `lib/src/models/analytics_models.dart` (400+ lines)
  - PerformanceMetrics, QueryPerformanceTrend
  - UserEngagementMetrics, CacheAnalytics
  - CompetitiveFeatureStats, CohortMetrics
  - All with Freezed + JSON serialization

**Effort:** 4-5 hours
**Dependencies:** Phase L models (PerformanceMonitor output format)

### M-2: Analytics Services (Day 1-2)
- [ ] Create `lib/src/services/analytics_service.dart` (500+ lines)
  - Core metrics collection and querying
  
- [ ] Create `lib/src/services/trend_aggregation_service.dart` (400+ lines)
  - Historical trend analysis and rollups
  
- [ ] Create `lib/src/services/cohort_analytics_service.dart` (350+ lines)
  - User cohort segmentation and analysis

**Effort:** 10-12 hours
**Dependencies:** Firestore, Phase L PerformanceMonitor

### M-3: Riverpod Providers (Day 2)
- [ ] Create `lib/src/providers/phase_m_analytics_providers.dart` (450+ lines)
  - 18+ reactive providers for dashboard data
  - Full integration with analytics services
  - Performance-optimized queries

**Effort:** 6-8 hours
**Dependencies:** Analytics services, Riverpod 2.2+

### M-4: Dashboard UI (Day 2-3)
- [ ] Create `lib/src/screens/analytics/dashboard_home.dart`
  - Main dashboard with KPI cards
  
- [ ] Create `lib/src/screens/analytics/performance_dashboard.dart`
  - Query performance trends visualization
  
- [ ] Create `lib/src/screens/analytics/engagement_dashboard.dart`
  - User engagement analytics
  
- [ ] Create `lib/src/screens/analytics/cache_dashboard.dart`
  - Cache performance metrics
  
- [ ] Create `lib/src/screens/analytics/competitive_features_dashboard.dart`
  - Feature adoption analytics
  
- [ ] Create `lib/src/widgets/analytics_charts.dart` (500+ lines)
  - Reusable chart components
  - Line charts, bar charts, heatmaps

**Effort:** 12-15 hours
**Dependencies:** fl_chart or charts package, analytics providers

### M-5: Firestore Integration (Day 3)
- [ ] Create Firestore indexes for analytics queries
- [ ] Set up daily metric aggregation Cloud Functions
- [ ] Configure data retention policies

**Effort:** 3-4 hours
**Dependencies:** Firebase Console access

### M-6: Testing & Documentation (Day 3)
- [ ] Unit tests for analytics services
- [ ] Widget tests for dashboard screens
- [ ] Integration tests for Firestore queries
- [ ] Documentation and architecture guide

**Effort:** 4-5 hours

---

## Dependencies & Integration

### New Dependencies
```yaml
# Charts & visualization
fl_chart: ^6.0.0          # or charts: ^0.12.0

# Data formatting
intl: ^0.18.0             # Already in pubspec
```

### Integration Points

**With Phase L (Performance Optimization):**
- Consume PerformanceMonitor metrics
- Display cache hit rates from QueryCache
- Track query performance improvements
- Monitor build optimization impact

**With Phase K (Competitive Features):**
- Track leaderboard feature adoption
- Monitor challenge system usage
- Analyze tournament participation
- Show competitive gaming trends

**With Phase E (Premium):**
- Premium analytics access (advanced features)
- Premium users see advanced dashboards
- Feature usage by subscription tier

---

## Success Metrics

**Implementation Goals:**
- ✅ 18+ analytics providers with full type safety
- ✅ 5 major dashboard screens + components
- ✅ Real-time metric visualization
- ✅ Historical trend analysis (7/30/90 day views)
- ✅ User engagement cohort analysis
- ✅ Firestore data persistence with daily rollups

**Performance Targets:**
- Dashboard load time: <2 seconds
- Chart rendering: <500ms
- Real-time updates: <1 second latency
- Data aggregation jobs: <5 minutes for daily rollup

**Code Quality:**
- 100% Dart analyzer compliance
- Comprehensive test coverage (60%+)
- Full documentation with examples
- Production-ready error handling

---

## Files to Create

### Models (450+ lines)
- `lib/src/models/analytics_models.dart`

### Services (1,250+ lines)
- `lib/src/services/analytics_service.dart`
- `lib/src/services/trend_aggregation_service.dart`
- `lib/src/services/cohort_analytics_service.dart`

### Providers (450+ lines)
- `lib/src/providers/phase_m_analytics_providers.dart`

### Screens & Widgets (1,200+ lines)
- `lib/src/screens/analytics/dashboard_home.dart`
- `lib/src/screens/analytics/performance_dashboard.dart`
- `lib/src/screens/analytics/engagement_dashboard.dart`
- `lib/src/screens/analytics/cache_dashboard.dart`
- `lib/src/screens/analytics/competitive_features_dashboard.dart`
- `lib/src/widgets/analytics_charts.dart`

### Tests (300+ lines)
- `test/analytics_services_test.dart`
- `test/analytics_providers_test.dart`
- `test/analytics_dashboard_test.dart`

### Documentation
- `docs/PHASE_M_IMPLEMENTATION_GUIDE.md`
- `docs/PHASE_M_API_REFERENCE.md`

**Total Estimated:** 3,700+ lines of code and documentation

---

## Timeline

| Task | Duration | Dependencies |
|------|----------|--------------|
| M-1: Models & Types | 4-5h | Phase L complete |
| M-2: Services | 10-12h | Models complete |
| M-3: Providers | 6-8h | Services complete |
| M-4: Dashboard UI | 12-15h | Providers complete |
| M-5: Firestore Setup | 3-4h | Parallel to UI |
| M-6: Testing & Docs | 4-5h | All components |
| **Total** | **40-50h** | 2-3 days |

---

## Next Steps

1. **Immediate:** Finalize Phase L-3 asset optimization
2. **Upon Phase L completion:** Begin Phase M implementation
3. **Priority order:** M-1 → M-2 → M-3 → M-4 → M-5 → M-6

---

**Phase M Status:** Planning  
**Next Milestone:** Phase L completion → Phase M kickoff  
**Quality Gate:** All CI checks pass, Phase L merged to main

---

*Generated by Claude Code (AI)*  
*Date: 2026-09-16*
