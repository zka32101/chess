# Phase M-5: Firestore Setup & Cloud Functions

**Status:** Implementation Ready  
**Created:** 2026-09-16  
**Owner:** Claude Code (AI)

---

## Overview

Phase M-5 establishes Firestore data persistence infrastructure and automated Cloud Functions for daily analytics aggregation. This enables permanent storage of analytics data and automated batch processing of metrics.

---

## 1. Firestore Indexes

### Performance Metrics Indexes

**Collection:** `analytics/performance_metrics/{date}/{operationType}`

```yaml
Index: performance_metrics_timestamp_success
Fields:
  - timestamp (Ascending)
  - success (Ascending)

Index: performance_metrics_operation_date
Fields:
  - operationName (Ascending)
  - timestamp (Descending)
```

### Query Trends Indexes

**Collection:** `analytics/query_trends/{period}/{queryType}`

```yaml
Index: query_trends_period
Fields:
  - period (Descending)
  - queryType (Ascending)

Index: query_trends_by_query
Fields:
  - queryType (Ascending)
  - period (Descending)
```

### User Engagement Indexes

**Collection:** `analytics/user_engagement/{userId}`

```yaml
Index: user_engagement_lastActive
Fields:
  - lastActive (Descending)
  - churnedUser (Ascending)

Index: user_engagement_sessions
Fields:
  - sessionsCount (Descending)
  - userId (Ascending)
```

### Cache Analytics Indexes

**Collection:** `analytics/cache_analytics/{date}/{cacheName}`

```yaml
Index: cache_analytics_hitRate
Fields:
  - period (Descending)
  - hitRate (Descending)

Index: cache_by_name_period
Fields:
  - cacheName (Ascending)
  - period (Descending)
```

### Competitive Features Indexes

**Collection:** `analytics/competitive_features/{date}/{feature}`

```yaml
Index: features_adoption_rate
Fields:
  - period (Descending)
  - adoptionRate (Descending)

Index: features_by_name
Fields:
  - feature (Ascending)
  - period (Descending)
```

### Retention Metrics Indexes

**Collection:** `analytics/retention_metrics/{cohortDate}`

```yaml
Index: retention_cohort_date
Fields:
  - cohortDate (Descending)
  - cohortSize (Ascending)

Index: retention_by_retention_date
Fields:
  - day1Retention (Descending)
  - cohortDate (Descending)
```

---

## 2. Setup Instructions

### Step 1: Create Firestore Indexes

1. Go to [Firebase Console - Indexes](https://console.firebase.google.com/project/yourwish-chess/firestore/indexes)
2. Click "Create Index"
3. For each index above, configure:
   - Collection ID
   - Field paths (in order)
   - Query scope (automatically detected from fields)
4. Click "Create" and wait for indexing to complete (typically 2-5 minutes)

**Note:** Composite indexes only needed if queries combine multiple fields. Single-field queries auto-index.

### Step 2: Deploy Cloud Functions

Cloud Functions handle automated daily metric aggregation at midnight UTC.

#### Function 1: Daily Metrics Rollup

**File:** `functions/src/analytics/aggregateMetrics.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const aggregateDailyMetrics = functions.pubsub
  .schedule('0 0 * * *')  // Daily at 00:00 UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const today = new Date();
      today.setUTCHours(0, 0, 0, 0);
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      const dateStr = yesterday.toISOString().split('T')[0];

      // Aggregate query performance metrics
      await aggregateQueryMetrics(dateStr);
      
      // Aggregate cache metrics
      await aggregateCacheMetrics(dateStr);
      
      // Aggregate competitive features
      await aggregateFeatureMetrics(dateStr);
      
      console.log(`Successfully aggregated metrics for ${dateStr}`);
      return null;
    } catch (error) {
      console.error('Error aggregating metrics:', error);
      throw error;
    }
  });

async function aggregateQueryMetrics(dateStr: string): Promise<void> {
  const snapshot = await db
    .collection('analytics/performance_metrics/' + dateStr)
    .get();

  const metrics: { [key: string]: any } = {};

  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const queryType = data.operationName || 'unknown';
    
    if (!metrics[queryType]) {
      metrics[queryType] = {
        latencies: [],
        successCount: 0,
        totalCount: 0,
      };
    }

    metrics[queryType].latencies.push(data.durationMs);
    if (data.success) metrics[queryType].successCount++;
    metrics[queryType].totalCount++;
  });

  // Calculate percentiles and store trends
  const period = new Date(dateStr).toISOString();
  
  for (const [queryType, data] of Object.entries(metrics)) {
    const latencies = (data as any).latencies.sort((a: number, b: number) => a - b);
    const p50 = latencies[Math.floor(latencies.length * 0.5)];
    const p95 = latencies[Math.floor(latencies.length * 0.95)];
    const p99 = latencies[Math.floor(latencies.length * 0.99)];
    
    await db
      .collection('analytics/query_trends/' + period.split('T')[0])
      .doc(queryType)
      .set({
        queryType,
        p50Latency: p50,
        p95Latency: p95,
        p99Latency: p99,
        successRate: (data as any).successCount / (data as any).totalCount,
        period: admin.firestore.Timestamp.fromDate(new Date(dateStr)),
        sampleCount: (data as any).totalCount,
      });
  }
}

async function aggregateCacheMetrics(dateStr: string): Promise<void> {
  const snapshot = await db
    .collection('analytics/cache_analytics/' + dateStr)
    .get();

  snapshot.docs.forEach(async (doc) => {
    const data = doc.data();
    // Cache documents already contain aggregated metrics
    // Just verify and re-store if needed
    await db
      .collection('analytics/cache_analytics/' + dateStr)
      .doc(doc.id)
      .update({
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
  });
}

async function aggregateFeatureMetrics(dateStr: string): Promise<void> {
  const snapshot = await db
    .collection('analytics/competitive_features/' + dateStr)
    .get();

  snapshot.docs.forEach(async (doc) => {
    const data = doc.data();
    // Feature documents already contain adoption metrics
    // Verify and update timestamp
    await db
      .collection('analytics/competitive_features/' + dateStr)
      .doc(doc.id)
      .update({
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });
  });
}
```

**Deploy:**
```bash
cd functions
firebase deploy --only functions:aggregateDailyMetrics
```

#### Function 2: Retention Metrics Calculation

**File:** `functions/src/analytics/calculateRetention.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const calculateDailyRetention = functions.pubsub
  .schedule('0 1 * * *')  // Daily at 01:00 UTC (after metrics aggregation)
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const today = new Date();
      today.setUTCHours(0, 0, 0, 0);
      
      // Calculate retention for all cohorts from past 30 days
      for (let i = 0; i < 30; i++) {
        const cohortDate = new Date(today);
        cohortDate.setDate(cohortDate.getDate() - i);
        await calculateCohortRetention(cohortDate);
      }
      
      console.log('Successfully calculated retention metrics');
      return null;
    } catch (error) {
      console.error('Error calculating retention:', error);
      throw error;
    }
  });

async function calculateCohortRetention(cohortDate: Date): Promise<void> {
  const cohortDateStr = cohortDate.toISOString().split('T')[0];
  
  // Get all users in this cohort
  const cohortSnapshot = await db
    .collection('analytics/user_cohorts')
    .where('cohortDate', '==', cohortDateStr)
    .get();

  if (cohortSnapshot.empty) return;

  const cohortSize = cohortSnapshot.size;
  const retentionByDay: { [key: number]: number } = {};

  // Check retention for days 1-30
  for (let day = 1; day <= 30; day++) {
    const checkDate = new Date(cohortDate);
    checkDate.setDate(checkDate.getDate() + day);
    const checkDateStr = checkDate.toISOString().split('T')[0];

    const activeSnapshot = await db
      .collection('analytics/user_engagement')
      .where('cohortDate', '==', cohortDateStr)
      .where('lastActive', '>=', checkDate)
      .get();

    retentionByDay[day] = (activeSnapshot.size / cohortSize) * 100;
  }

  // Store retention metrics
  const d1Retention = retentionByDay[1] || 0;
  const d7Retention = retentionByDay[7] || 0;
  const d30Retention = retentionByDay[30] || 0;

  await db
    .collection('analytics/retention_metrics')
    .doc(cohortDateStr)
    .set({
      cohortDate: cohortDateStr,
      cohortSize,
      retentionByDay,
      day1Retention: d1Retention,
      day7Retention: d7Retention,
      day30Retention: d30Retention,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });
}
```

**Deploy:**
```bash
firebase deploy --only functions:calculateDailyRetention
```

---

## 3. Data Retention Policies

### Retention Rules

| Collection | Retention Period | Policy |
|-----------|-----------------|--------|
| `analytics/performance_metrics` | 90 days | Auto-delete after 90 days |
| `analytics/query_trends` | Unlimited | Keep all historical trends |
| `analytics/user_engagement` | Unlimited | Keep all user history |
| `analytics/cache_analytics` | 60 days | Auto-delete after 60 days |
| `analytics/competitive_features` | Unlimited | Keep all feature history |
| `analytics/retention_metrics` | Unlimited | Keep all cohort history |
| `analytics/daily_snapshots` | 1 year | Auto-delete after 1 year |

### Implementing TTL (Time-To-Live)

1. In Firebase Console, enable TTL:
   - Go to Firestore Database settings
   - Enable TTL for each collection
   - Set TTL field to `deletedAt` or `expiresAt`

2. In Dart code, set TTL when creating documents:

```dart
Future<void> recordPerformanceMetric(PerformanceMetrics metric) async {
  final nineDaysFromNow = DateTime.now().add(Duration(days: 90));
  
  await firestore
    .collection('analytics/performance_metrics/${_getDateString()}}')
    .doc(metric.operationName)
    .set({
      ...metric.toJson(),
      'expiresAt': Timestamp.fromDate(nineDaysFromNow),
    });
}
```

---

## 4. Testing Cloud Functions Locally

### Setup Local Emulator

```bash
# Install Firebase emulator
npm install -g firebase-tools

# Start emulator
firebase emulators:start --project=yourwish-chess

# In separate terminal, run tests
npm test -- --testEnvironment=node
```

### Test Daily Aggregation

```typescript
describe('Analytics Aggregation', () => {
  it('should aggregate daily metrics', async () => {
    // Create test data
    await db.collection('analytics/performance_metrics/2024-01-01').add({
      operationName: 'leaderboard_query',
      durationMs: 150,
      success: true,
      timestamp: admin.firestore.Timestamp.now(),
    });

    // Trigger aggregation
    const aggregateMetrics = require('./aggregateMetrics').aggregateDailyMetrics;
    await aggregateMetrics({});

    // Verify results
    const trend = await db
      .collection('analytics/query_trends/2024-01-01')
      .doc('leaderboard_query')
      .get();

    expect(trend.exists).toBe(true);
    expect(trend.data().p50Latency).toBe(150);
  });
});
```

---

## 5. Monitoring & Alerting

### Setup Cloud Monitoring

1. Go to [Cloud Monitoring](https://console.cloud.google.com/monitoring)
2. Create alert policy for:
   - Function execution errors: Alert if errors > 1 in 5 minutes
   - Function execution time: Alert if P95 > 30 seconds
   - Firestore read/write rate: Alert if quota exceeded

### Key Metrics to Monitor

```
firebase.googleapis.com/database/connections
firebase.googleapis.com/firestore/document_deletes
firebase.googleapis.com/firestore/network_bytes_billed
firebase.googleapis.com/functions/execution_count
firebase.googleapis.com/functions/execution_times
```

---

## 6. Troubleshooting

### Issue: Indexes not created

**Solution:**
```bash
firebase indexes:list
firebase indexes:create
```

### Issue: Cloud Function timeout

**Solution:** Increase timeout in function config:
```yaml
runtime: nodejs18
timeout: 540  # 9 minutes max
memory: 2048MB
```

### Issue: Firestore quota exceeded

**Solution:**
- Check usage in Firebase Console
- Enable on-demand billing (for auto-scaling)
- Implement index-based queries only
- Add pagination to large reads

---

## 7. Security Rules

### Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /analytics/{document=**} {
      allow read: if request.auth.uid != null && 
                     hasRole(request.auth.uid, 'admin');
      allow create, update: if hasRole(request.auth.uid, 'analytics_writer');
    }
    
    function hasRole(uid, role) {
      return get(/databases/$(database)/documents/users/$(uid))
        .data.roles[role] == true;
    }
  }
}
```

Set admin/analytics_writer roles in Firestore:
```dart
await firestore.collection('users').doc(userId).update({
  'roles': {
    'admin': true,
    'analytics_writer': true,
  }
});
```

---

**Phase M-5 Status:** Documentation Ready  
**Next:** Phase M-6 (Testing & Documentation)  
**Effort:** 2-3 hours for index creation and function deployment
