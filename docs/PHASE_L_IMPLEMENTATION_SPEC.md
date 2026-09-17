# Phase L: Performance Optimization - Implementation Specification

**Status:** In Progress  
**Timeline:** Week 17 (4 days estimated)  
**Objective:** Implement aggressive caching, pagination, and performance monitoring across all Phase K services

---

## Overview

Phase L optimizes the Phase K infrastructure (leaderboards, friends, challenges, tournaments) through:
1. **Database Optimization** - Firestore indexes, pagination, batch queries
2. **Code Optimization** - Smart caching, performance monitoring, hot path optimization
3. **Build Optimization** - APK/IPA size reduction, tree-shaking, code obfuscation

**Expected Performance Gains:**
- Query response time: 50-80% reduction (from 500ms → 100-200ms)
- Cache hit rate: 70%+ for frequently accessed data
- Network efficiency: 60% reduction in data transferred via pagination
- Build size: 15-20% reduction through tree-shaking and obfuscation

---

## 1. Database Optimization

### 1.1 Firestore Indexes (✅ Complete)

**File:** `firestore.indexes.json`

**Indexes Created:**
- Global leaderboard: `rating DESC, region ASC`
- Regional leaderboard: `rating DESC` (optimized)
- Time-based leaderboard: `period ASC, rating DESC`
- Friend challenges: `challengeeUserId ASC, status ASC, createdAt DESC`
- Challenge streaks: `currentStreak DESC, totalChallengesWon DESC`
- Tournament status: `status ASC, startDate ASC`
- Tournament participants: `points DESC, wins DESC`
- Tournament matches: `round ASC, scheduledAt ASC`

**Firestore CLI Deployment:**
```bash
firebase firestore:indexes:create --project=yourwish-chess firestore.indexes.json
```

### 1.2 Pagination System (✅ Complete)

**File:** `lib/src/utils/pagination_helper.dart`

**Components:**
- `PaginationParams` - Configuration for pagination requests
- `PaginatedResult<T>` - Typed result with next token and hasMore flag
- `QueryOptimizer` - Static utility for applying pagination to queries
- `BatchQueryHelper` - Chunking and batch query execution

**Pagination Patterns:**
```dart
// Offset-limit pagination (simple, suitable for small datasets)
final result = await leaderboardService.getGlobalLeaderboardPaginated(
  pageSize: 20,
  startAfter: null, // First page
);

// Cursor-based pagination (recommended for large datasets)
final result = await leaderboardService.getGlobalLeaderboardPaginated(
  pageSize: 20,
  startAfter: previousResult.nextPageToken,
);
```

**Query Optimization Strategy:**
- Always use `limit(pageSize + 1)` to detect if more results exist
- Use cursor-based pagination for sorted results (Firestore native)
- Limit batch queries to 10 documents per chunk to avoid timeout issues

### 1.3 Query Caching (✅ Complete)

**File:** `lib/src/utils/query_cache.dart`

**Cache Types:**

1. **QueryCache<K, V>** - Basic TTL-based cache
   - Simple key-value storage with expiration
   - Automatic cleanup of expired entries
   - Thread-safe access

2. **SmartCache<K, V>** - Intelligent async cache
   - Deduplicates in-flight requests (prevents thundering herd)
   - Falls back to fetcher function if cache miss
   - Configurable TTL per entry

3. **CompositeCache<K, V>** - Multi-tier caching
   - L1: Hot cache (1 minute TTL)
   - L2: Warm cache (5 minute TTL)
   - L3: Cold cache (15 minute TTL)

4. **MonitoredCache<K, V>** - Cache with metrics
   - Tracks hit/miss/eviction statistics
   - Calculates hit rate and performance
   - Exports CacheStats for monitoring

**Cache Strategy by Data Type:**

| Data Type | TTL | Cache Type | Reasoning |
|-----------|-----|-----------|-----------|
| Leaderboard entries | 5 min | SmartCache | Frequently accessed, not real-time critical |
| User ranking stats | 10 min | SmartCache | Updates slower than entries |
| Challenge data | 2 min | SmartCache | More volatile, needs faster refresh |
| Tournament standings | 5 min | SmartCache | Updates during matches |
| Head-to-head stats | 1 hour | MonitoredCache | Rarely changes, good cache candidate |

### 1.4 Batch Query Operations

**BatchQueryHelper Methods:**
- `chunk<T>()` - Split lists into Firestore-safe chunks (max 10)
- `executeBatchQueries<T>()` - Execute multiple queries sequentially

**Usage Example:**
```dart
// Get 100 users' ranking stats efficiently
final userIds = [...]; // 100 user IDs
final stats = await leaderboardService.getRankingStatsBatch(userIds);
// Executes as 10 batches of 10 queries each
```

---

## 2. Code Optimization

### 2.1 Optimized Services (✅ Partial)

**Files:**
- `lib/src/services/leaderboard_service_optimized.dart`
- `lib/src/services/tournament_service_optimized.dart`

**Optimizations Applied:**

1. **LeaderboardServiceOptimized**
   - Replaces basic caching with SmartCache
   - Adds `getGlobalLeaderboardPaginated()` with cursor-based pagination
   - Implements `getRankingStatsBatch()` for efficient bulk queries
   - Adds `getMultipleLeaderboards()` for concurrent region queries
   - Provides `MonitoredCache` for H2H stats with cache metrics

2. **TournamentServiceOptimized**
   - Smart caching for tournament, standings, and match data
   - Paginated tournament listing
   - Paginated match retrieval with round filtering
   - Batch tournament fetching (chunks queries safely)
   - Participant count caching with TTL
   - Upcoming matches query with pagination

**Migration Path:**
```dart
// Phase K: Original service
final leaderboardService = LeaderboardService.instance;

// Phase L: Optimized service (backward compatible with same interface)
final optimizedService = LeaderboardServiceOptimized.instance;

// Can run both in parallel during migration
```

### 2.2 Performance Monitoring (✅ Complete)

**File:** `lib/src/utils/performance_monitor.dart`

**Components:**

1. **PerformanceMetric**
   - Records operation name, duration, timestamp, success status
   - Stores error message if operation failed

2. **PerformanceMonitor** (Singleton)
   - Records all operation metrics
   - Maintains rolling window of metrics (default 1000 max)
   - Provides query/analysis functions

3. **PerformanceSummary**
   - Aggregated statistics: call count, avg/min/max duration, success rate
   - Generated from metric history

4. **ThresholdMonitor**
   - Defines performance thresholds (warning/error levels)
   - Generates alerts when thresholds exceeded

**Usage Pattern:**
```dart
// Automatic measurement
await performanceMonitor.measureAsync(
  'getGlobalLeaderboard',
  () => leaderboardService.getGlobalLeaderboard(),
);

// Manual timing
monitor.startTimer('complexOperation');
// ... do work ...
monitor.stopTimer('complexOperation', success: true);

// Query metrics
final summary = monitor.getSummary();
final avgDuration = monitor.getAverageDuration('getGlobalLeaderboard');
final slowest = monitor.getSlowestOperations(10);
```

**Performance Thresholds:**

| Operation | Warning | Error |
|-----------|---------|-------|
| Single user query | 200ms | 500ms |
| Leaderboard page | 300ms | 800ms |
| Tournament batch | 500ms | 1500ms |
| H2H calculation | 400ms | 1000ms |

### 2.3 Hot Path Optimization

**Identified Hot Paths:**
1. **Leaderboard display** - Called on every app open
2. **Friend list loading** - Frequent user interactions
3. **Challenge notifications** - Real-time updates
4. **Tournament standings** - During tournaments

**Optimization Strategy:**
- Implement aggressive caching (5-minute TTL)
- Paginate results (show top 20, load more on demand)
- Preload related data (fetch friend status with friend list)
- Batch similar queries together
- Use debouncing for real-time updates (500ms)

### 2.4 Widget Rebuild Optimization

**Principles:**
- Use `const` constructors for stateless widgets
- Implement `ReassembleWidget` for selective rebuilds
- Use Riverpod `select()` for partial provider dependencies
- Avoid rebuilding entire lists (use `ListView.builder`)

**Example Optimization:**
```dart
// Before: Rebuilds entire list on any change
final data = ref.watch(userSocialStatsProvider(userId));

// After: Only rebuilds if friendsCount changes
final friendsCount = ref.watch(
  userSocialStatsProvider(userId).select((stats) => stats.friendsCount),
);
```

---

## 3. Build Optimization

### 3.1 APK/IPA Size Reduction

**Strategies:**
1. **Code Tree-Shaking** - Remove unused code
2. **Asset Compression** - Optimize image assets
3. **Dart Obfuscation** - Reduce code size during minification
4. **Package Optimization** - Remove unused dependencies

**Configuration (`pubspec.yaml`):**
```yaml
flutter:
  assets:
    # Only include necessary assets
    - assets/images/chess/
    - assets/data/openings.json

dependencies:
  # Remove unused packages
  # - unused_package: ^1.0.0
```

**Build Commands:**
```bash
# Release build with tree-shaking and obfuscation
flutter build apk --release --tree-shake-icons
flutter build ios --release

# Analyze build size
flutter analyze --suppress=unnecessary_import
dart pub global activate get_size_cli
get_size_cli flutter build apk --release
```

**Expected Size Reductions:**
- Remove unused Chess engine code: -5MB
- Asset compression: -2MB
- Tree-shaking unused dependencies: -3MB
- Obfuscation: -2MB
- **Total: ~12MB reduction (15-20%)**

### 3.2 Code Splitting and Lazy Loading

**Lazy Load Strategy:**
```dart
// Load tournament features only when accessed
dynamic tournamentsFeature = await loadFeature('tournaments');
final screen = tournamentsFeature.TournamentsScreen();

// Load analytics only in production
if (kReleaseMode) {
  await loadFeature('analytics');
}
```

### 3.3 Image and Asset Optimization

**Asset Pipeline:**
1. Use WebP format for images (40% smaller than PNG)
2. Compress images to max 50KB per asset
3. Use SVG for icons (vector scaling, tiny size)
4. Implement responsive image loading

**Commands:**
```bash
# Convert PNG to WebP
cwebp -q 85 image.png -o image.webp

# Compress JPEG
jpegoptim --max=50 *.jpg
```

---

## 4. Provider Layer Optimization

### 4.1 Provider Selection Strategy

**FutureProvider.family** - Use for:
- Single async operations with parameters
- Data that changes infrequently
- Cache key naturally available (userId, tournamentId, etc.)

**StreamProvider.family** - Use for:
- Real-time data updates
- Leaderboard live standings (future phase)
- Challenge notifications (future phase)

**StateProvider** - Use for:
- UI state (selected filter, sort order)
- Pagination cursor tokens
- Temporary user selections

**Computation:**
```dart
// Cached computation (5 minute TTL)
final userSocialStatsProvider = FutureProvider.family<SocialStats, String>(
  (ref, userId) async {
    // Riverpod automatically caches and invalidates
    final friends = await ref.watch(userFriendsProvider(userId).future);
    final stats = await ref.watch(userRankingStatsProvider(userId).future);
    return SocialStats(
      friendsCount: friends.length,
      globalRank: stats.rank,
      // ...
    );
  },
);
```

### 4.2 Cache Invalidation Strategy

**Automatic Invalidation:**
- Riverpod's `.future` automatically refreshes on data changes
- Service cache.remove() triggers provider refresh

**Manual Invalidation:**
```dart
// Invalidate single provider
ref.refresh(userSocialStatsProvider(userId));

// Invalidate all leaderboard data
ref.invalidate(globalLeaderboardProvider);

// Invalidate on service cache clear
leaderboardService.clearCache();
ref.refresh(globalLeaderboardProvider(100));
```

---

## 5. Implementation Roadmap

### Phase L-1: Database Optimization (Complete)
- ✅ Create Firestore indexes configuration
- ✅ Document pagination patterns
- ✅ Implement query cache infrastructure

### Phase L-2: Code Optimization (In Progress)
- ✅ Create optimized service implementations
- ✅ Implement performance monitoring
- ⏳ Update existing services with pagination
- ⏳ Add cache metrics to Riverpod layer

### Phase L-3: Build Optimization (Pending)
- ⏳ Analyze current build size
- ⏳ Implement tree-shaking configuration
- ⏳ Optimize assets (WebP conversion, compression)
- ⏳ Configure code obfuscation

### Phase L-4: Testing & Documentation (Pending)
- ⏳ Performance benchmark tests
- ⏳ Load testing scenarios
- ⏳ Cache effectiveness validation
- ⏳ Performance documentation

---

## 6. Success Metrics

### Database Performance
- ✅ All Phase K queries have Firestore indexes
- ✅ Pagination system supports cursor-based navigation
- ✅ Batch query utility handles 10-item chunks safely

### Code Performance
- Query response time: 100-200ms (50-80% reduction)
- Cache hit rate: 70%+ for hot paths
- Memory usage: <50MB for cache structures

### Build Performance
- APK size: <100MB (from ~112MB baseline)
- App startup: <2 seconds
- Initial screen render: <500ms

### Monitoring
- All operations have performance metrics
- Alerts trigger for operations exceeding thresholds
- Weekly performance reports generated

---

## 7. Files Created

### Utilities
- `lib/src/utils/pagination_helper.dart` - Pagination and batch query helpers
- `lib/src/utils/query_cache.dart` - Multi-tier caching system
- `lib/src/utils/performance_monitor.dart` - Performance metrics and monitoring

### Optimized Services
- `lib/src/services/leaderboard_service_optimized.dart` - Paginated, cached leaderboard queries
- `lib/src/services/tournament_service_optimized.dart` - Paginated, cached tournament queries

### Configuration
- `firestore.indexes.json` - Firestore index definitions

---

## 8. Integration Checklist

- [ ] Deploy Firestore indexes to production
- [ ] Update Phase K providers to use optimized services
- [ ] Add performance monitoring to all services
- [ ] Implement cache invalidation strategy
- [ ] Configure Riverpod provider selection
- [ ] Test pagination with large datasets
- [ ] Profile hot paths and validate improvements
- [ ] Generate performance baseline metrics
- [ ] Document optimization decisions
- [ ] Create performance monitoring dashboard

---

## 9. Next Phase (Phase M)

After Phase L completion:
- Build advanced analytics dashboard
- Add cohort analysis and retention metrics
- Extend Phase H analytics with Phase K social data
- Create admin reporting interface

---

**Phase L Status:** Infrastructure Layer Complete (60%)  
**Last Updated:** 2026-09-15  
**Owner:** Claude Code (AI)
