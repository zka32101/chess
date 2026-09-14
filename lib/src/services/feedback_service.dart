import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';

/// Service for managing user feedback and beta testing
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics;

  FeedbackService._(this._analytics);

  static FeedbackService get instance => _instance;

  /// Submit user feedback
  Future<void> submitFeedback({
    required String category,
    required String title,
    required String description,
    double? rating,
    String? screenshotPath,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to submit feedback');
    }

    try {
      final feedbackDoc = {
        'userId': user.uid,
        'category': category,
        'title': title,
        'description': description,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0',
        'status': 'new',
        'metadata': metadata ?? {},
      };

      await _firestore.collection('beta_feedback').add(feedbackDoc);

      // Track in analytics
      await _analytics.logEvent(
        'feedback_submitted',
        parameters: {
          'category': category,
          'rating': rating?.toInt() ?? 0,
        },
      );
    } catch (e) {
      print('Error submitting feedback: $e');
      rethrow;
    }
  }

  /// Submit a bug report
  Future<void> submitBugReport({
    required String title,
    required String description,
    required String severity,
    String? screenshotPath,
    Map<String, dynamic>? gameState,
  }) async {
    await submitFeedback(
      category: 'bug_report',
      title: title,
      description: description,
      metadata: {
        'severity': severity,
        'gameState': gameState,
        'screenshotPath': screenshotPath,
      },
    );

    // Log to analytics for tracking
    await _analytics.logEvent(
      'bug_reported',
      parameters: {
        'severity': severity,
        'title': title,
      },
    );
  }

  /// Submit a feature request
  Future<void> submitFeatureRequest({
    required String title,
    required String description,
    int? priority,
  }) async {
    await submitFeedback(
      category: 'feature_request',
      title: title,
      description: description,
      metadata: {
        'priority': priority ?? 3,
      },
    );

    await _analytics.logEvent(
      'feature_requested',
      parameters: {
        'title': title,
      },
    );
  }

  /// Rate the app
  Future<void> rateApp({
    required int stars,
    String? comment,
  }) async {
    await submitFeedback(
      category: 'app_rating',
      title: 'App Rating',
      description: comment ?? 'User rated the app',
      rating: stars.toDouble(),
    );

    await _analytics.logEvent(
      'app_rated',
      parameters: {
        'stars': stars,
        'hasComment': comment != null,
      },
    );
  }

  /// Get user's feedback history
  Future<List<Map<String, dynamic>>> getUserFeedback() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('beta_feedback')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching user feedback: $e');
      return [];
    }
  }

  /// Check if user should see rating prompt
  bool shouldShowRatingPrompt({
    required int gameCount,
    required DateTime lastPromptDate,
  }) {
    // Show after every 3 games, with minimum 7 day gap
    final daysSinceLastPrompt = DateTime.now().difference(lastPromptDate).inDays;
    return gameCount % 3 == 0 && daysSinceLastPrompt >= 7;
  }

  /// Track beta participation
  Future<void> trackBetaParticipation({
    required String trackingId,
    String? betaChannel,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('beta_participants')
          .doc(user.uid)
          .set({
            'trackingId': trackingId,
            'betaChannel': betaChannel,
            'joinedAt': FieldValue.serverTimestamp(),
            'metadata': metadata ?? {},
          }, SetOptions(merge: true));

      await _analytics.setUserProperty(
        name: 'beta_participant',
        value: 'true',
      );
    } catch (e) {
      print('Error tracking beta participation: $e');
    }
  }

  /// Get beta tester status
  Future<Map<String, dynamic>?> getBetaTesterStatus() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('beta_participants')
          .doc(user.uid)
          .get();

      return doc.data();
    } catch (e) {
      print('Error fetching beta tester status: $e');
      return null;
    }
  }

  /// Report performance issue
  Future<void> reportPerformanceIssue({
    required String description,
    required double startupTime,
    required double navigationTime,
    required int memoryUsageMB,
  }) async {
    await submitFeedback(
      category: 'performance_issue',
      title: 'Performance Report',
      description: description,
      metadata: {
        'startupTime': startupTime,
        'navigationTime': navigationTime,
        'memoryUsageMB': memoryUsageMB,
      },
    );

    await _analytics.logEvent(
      'performance_issue_reported',
      parameters: {
        'startupTime': startupTime.toInt(),
        'memoryUsageMB': memoryUsageMB,
      },
    );
  }

  /// Get feedback summary for dashboard
  Future<Map<String, int>> getFeedbackSummary() async {
    try {
      final snapshot = await _firestore
          .collection('beta_feedback')
          .snapshots()
          .first;

      final summary = <String, int>{};
      
      for (final doc in snapshot.docs) {
        final category = doc['category'] as String? ?? 'unknown';
        summary[category] = (summary[category] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      print('Error fetching feedback summary: $e');
      return {};
    }
  }
}
