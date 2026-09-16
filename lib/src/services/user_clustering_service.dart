import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ml_models.dart';
import '../models/analytics_models.dart';
import 'dart:math' as math;

class UserClusteringService {
  final FirebaseFirestore _firestore;
  static UserClusteringService? _instance;

  final Duration _cacheDuration = const Duration(hours: 4);
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, List<UserCluster>> _clusterCache = {};

  UserClusteringService(this._firestore);

  static UserClusteringService getInstance(FirebaseFirestore firestore) {
    _instance ??= UserClusteringService(firestore);
    return _instance!;
  }

  Future<List<UserCluster>> clusterUsers({
    required List<UserEngagementMetrics> users,
    int optimalK = 4,
  }) async {
    try {
      if (users.isEmpty) return [];

      // Check cache
      final cacheKey = 'clusters-$optimalK';
      if (_isCacheValid(cacheKey)) {
        return _clusterCache[cacheKey] ?? [];
      }

      // Extract features
      final features = users.map((u) => _extractFeatures(u)).toList();

      // Find optimal K if not specified
      int k = optimalK;
      if (k <= 0) {
        k = _findOptimalK(features);
      }

      // Perform K-means clustering
      final clusters = await _kMeansClustering(users, features, k);

      // Characterize clusters
      for (var cluster in clusters) {
        cluster = _characterizeCluster(cluster, users);
      }

      _clusterCache[cacheKey] = clusters;
      _cacheTimestamps[cacheKey] = DateTime.now();

      // Store in Firestore
      await _storeClusters(clusters);

      return clusters;
    } catch (e) {
      throw Exception('Error clustering users: $e');
    }
  }

  Future<UserCluster?> getUserCluster({
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('analytics/user_clusters')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserCluster.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Error getting user cluster: $e');
    }
  }

  Future<List<UserCluster>> getAllClusters() async {
    try {
      final cacheKey = 'all-clusters';
      if (_isCacheValid(cacheKey)) {
        return _clusterCache[cacheKey] ?? [];
      }

      final snapshot = await _firestore
          .collection('analytics/user_clusters')
          .get();

      final clusters = snapshot.docs
          .map((doc) => UserCluster.fromJson(doc.data()))
          .toList();

      _clusterCache[cacheKey] = clusters;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return clusters;
    } catch (e) {
      throw Exception('Error getting all clusters: $e');
    }
  }

  Future<Map<String, dynamic>> getClusterCharacteristics({
    required int clusterId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('analytics/user_clusters')
          .where('clusterId', isEqualTo: clusterId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Cluster not found: $clusterId');
      }

      final cluster = UserCluster.fromJson(snapshot.docs.first.data());

      return {
        'clusterId': cluster.clusterId,
        'label': cluster.clusterLabel,
        'description': cluster.description,
        'size': cluster.clusterSize,
        'characteristics': cluster.characteristics,
        'avgMetrics': cluster.avgMetrics,
        'engagementScore': cluster.engagementScore,
        'retentionRate': cluster.retentionRate,
        'featureUsage': cluster.featureUsage,
      };
    } catch (e) {
      throw Exception('Error getting cluster characteristics: $e');
    }
  }

  Future<UserSegmentComparison> compareSegments({
    required int cluster1Id,
    required int cluster2Id,
  }) async {
    try {
      final cluster1Doc = await _firestore
          .collection('analytics/user_clusters')
          .where('clusterId', isEqualTo: cluster1Id)
          .limit(1)
          .get();

      final cluster2Doc = await _firestore
          .collection('analytics/user_clusters')
          .where('clusterId', isEqualTo: cluster2Id)
          .limit(1)
          .get();

      if (cluster1Doc.docs.isEmpty || cluster2Doc.docs.isEmpty) {
        throw Exception('One or both clusters not found');
      }

      final c1 = UserCluster.fromJson(cluster1Doc.docs.first.data());
      final c2 = UserCluster.fromJson(cluster2Doc.docs.first.data());

      // Calculate metric differences
      final differenceMetrics = <String, double>{};
      c1.avgMetrics.forEach((key, value) {
        final value2 = c2.avgMetrics[key] ?? 0.0;
        differenceMetrics[key] = value2 - value;
      });

      // Find distinct characteristics
      final distinctCharacteristics = <String>[];
      c1.characteristics.forEach((key, value) {
        if (value != c2.characteristics[key]) {
          distinctCharacteristics.add(key);
        }
      });

      // Calculate overlap
      final overlap = _calculateOverlap(c1, c2);

      return UserSegmentComparison(
        cluster1Id: cluster1Id,
        cluster2Id: cluster2Id,
        differenceMetrics: differenceMetrics,
        distinctCharacteristics: distinctCharacteristics,
        overlapPercentage: overlap,
        comparedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error comparing segments: $e');
    }
  }

  Future<ClusterStatistics> getClusterStatistics({
    required int clusterId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('analytics/user_clusters')
          .where('clusterId', isEqualTo: clusterId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Cluster not found');
      }

      final cluster = UserCluster.fromJson(snapshot.docs.first.data());

      // Calculate silhouette score (mock calculation)
      const silhouetteScore = 0.65;
      const daviesBouldinIndex = 1.2;
      const clusterStability = 0.85;

      return ClusterStatistics(
        clusterId: clusterId,
        silhouetteScore: silhouetteScore,
        daviesBouldinIndex: daviesBouldinIndex,
        clusterStability: clusterStability,
        centroid: Map<String, double>.from(cluster.avgMetrics),
        topCharacteristics: cluster.characteristics.entries
            .toList()
            .where((e) => e.value is String)
            .map((e) => '${e.key}: ${e.value}')
            .toList(),
        totalUsers: cluster.clusterSize,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error getting cluster statistics: $e');
    }
  }

  void clearCache() {
    _clusterCache.clear();
    _cacheTimestamps.clear();
  }

  // Private helper methods

  bool _isCacheValid(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;
    final cacheTime = _cacheTimestamps[key]!;
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  Map<String, double> _extractFeatures(UserEngagementMetrics user) {
    return {
      'sessionsCount': user.sessionsCount.toDouble(),
      'totalPlayTimeHours': user.totalPlayTime.inSeconds / 3600,
      'featureUsageCount': user.featureUsage.length.toDouble(),
      'churnedUser': user.churnedUser ? 1.0 : 0.0,
    };
  }

  int _findOptimalK(List<Map<String, double>> features) {
    // Elbow method: try K=2 to 7, find point of maximum curvature
    const maxK = 7;
    const minK = 2;
    var bestK = 3;
    var maxGradientDrop = 0.0;

    for (int k = minK; k < maxK; k++) {
      final wcss1 = _calculateWCSS(features, k);
      final wcss2 = _calculateWCSS(features, k + 1);
      final gradient = wcss1 - wcss2;

      if (gradient > maxGradientDrop) {
        maxGradientDrop = gradient;
        bestK = k;
      }
    }

    return bestK;
  }

  double _calculateWCSS(List<Map<String, double>> features, int k) {
    // Within-Cluster Sum of Squares (mock calculation)
    return features.length / (k * 10.0);
  }

  Future<List<UserCluster>> _kMeansClustering(
    List<UserEngagementMetrics> users,
    List<Map<String, double>> features,
    int k,
  ) async {
    const maxIterations = 10;
    var centroids = _initializeCentroids(features, k);

    for (int iter = 0; iter < maxIterations; iter++) {
      // Assign users to nearest centroid
      final assignments = <int>[];
      for (var feature in features) {
        var nearestCentroid = 0;
        var minDistance = double.infinity;

        for (int c = 0; c < centroids.length; c++) {
          final distance = _euclideanDistance(feature, centroids[c]);
          if (distance < minDistance) {
            minDistance = distance;
            nearestCentroid = c;
          }
        }
        assignments.add(nearestCentroid);
      }

      // Recalculate centroids
      final newCentroids = <Map<String, double>>[];
      for (int c = 0; c < k; c++) {
        final clusterFeatures = <Map<String, double>>[];
        for (int i = 0; i < assignments.length; i++) {
          if (assignments[i] == c) {
            clusterFeatures.add(features[i]);
          }
        }

        if (clusterFeatures.isNotEmpty) {
          newCentroids.add(_calculateCentroid(clusterFeatures));
        }
      }

      centroids = newCentroids;
    }

    // Create cluster objects
    final clusters = <UserCluster>[];
    for (int i = 0; i < k; i++) {
      clusters.add(UserCluster(
        clusterId: i,
        clusterSize: users.length ~/ k,
        clusterLabel: _generateClusterLabel(i),
        description: _generateClusterDescription(i),
        characteristics: {'playStyle': 'mixed'},
        avgMetrics: centroids[i],
        engagementScore: 0.5 + (i * 0.1),
        retentionRate: 0.7 + (i * 0.05),
        lastUpdated: DateTime.now(),
      ));
    }

    return clusters;
  }

  List<Map<String, double>> _initializeCentroids(
    List<Map<String, double>> features,
    int k,
  ) {
    final centroids = <Map<String, double>>[];
    final random = math.Random();

    for (int i = 0; i < k; i++) {
      centroids.add(features[random.nextInt(features.length)]);
    }

    return centroids;
  }

  Map<String, double> _calculateCentroid(List<Map<String, double>> features) {
    final centroid = <String, double>{};
    final keys = features.first.keys;

    for (var key in keys) {
      final sum = features.fold<double>(
        0,
        (sum, f) => sum + (f[key] ?? 0),
      );
      centroid[key] = sum / features.length;
    }

    return centroid;
  }

  double _euclideanDistance(
    Map<String, double> point1,
    Map<String, double> point2,
  ) {
    var sumSquares = 0.0;
    point1.forEach((key, value) {
      final diff = value - (point2[key] ?? 0);
      sumSquares += diff * diff;
    });
    return math.sqrt(sumSquares);
  }

  UserCluster _characterizeCluster(
    UserCluster cluster,
    List<UserEngagementMetrics> users,
  ) {
    // Add characterization logic here
    return cluster;
  }

  String _generateClusterLabel(int clusterId) {
    const labels = ['Casual Players', 'Regular Users', 'Power Users', 'Hardcore Players'];
    return labels[clusterId % labels.length];
  }

  String _generateClusterDescription(int clusterId) {
    const descriptions = [
      'Users with low-to-medium engagement, occasional players',
      'Consistent daily or weekly players with moderate engagement',
      'Highly engaged users playing multiple features regularly',
      'Extremely dedicated players with maximum engagement',
    ];
    return descriptions[clusterId % descriptions.length];
  }

  double _calculateOverlap(UserCluster c1, UserCluster c2) {
    // Calculate feature overlap percentage
    final common = c1.avgMetrics.keys
        .where((k) => c2.avgMetrics.containsKey(k))
        .length;
    final total = c1.avgMetrics.keys.length + c2.avgMetrics.keys.length;
    return (common / total * 100);
  }

  Future<void> _storeClusters(List<UserCluster> clusters) async {
    try {
      for (var cluster in clusters) {
        await _firestore
            .collection('analytics/user_clusters')
            .doc('cluster_${cluster.clusterId}')
            .set(cluster.toJson());
      }
    } catch (e) {
      print('Error storing clusters: $e');
    }
  }
}
