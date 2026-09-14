import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feedback_service.dart';
import '../services/analytics_service.dart';

/// Beta participation tracking
class BetaParticipant {
  final String trackingId;
  final String? betaChannel;
  final DateTime joinedAt;

  BetaParticipant({
    required this.trackingId,
    this.betaChannel,
    required this.joinedAt,
  });
}

// Feedback service provider
final feedbackServiceProvider = Provider((ref) {
  // In real implementation, inject AnalyticsService
  return FeedbackService.instance;
});

// Track feedback submission
final submitFeedbackProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, feedbackData) async {
  final feedbackService = ref.watch(feedbackServiceProvider);

  await feedbackService.submitFeedback(
    category: feedbackData['category'] as String,
    title: feedbackData['title'] as String,
    description: feedbackData['description'] as String,
    rating: feedbackData['rating'] as double?,
    metadata: feedbackData['metadata'] as Map<String, dynamic>?,
  );
});

// Get user's feedback history
final userFeedbackProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final feedbackService = ref.watch(feedbackServiceProvider);
  return feedbackService.getUserFeedback();
});

// Beta tester status
final betaTesterStatusProvider = FutureProvider<BetaParticipant?>((ref) async {
  final feedbackService = ref.watch(feedbackServiceProvider);
  final status = await feedbackService.getBetaTesterStatus();

  if (status == null) return null;

  return BetaParticipant(
    trackingId: status['trackingId'] as String? ?? '',
    betaChannel: status['betaChannel'] as String?,
    joinedAt: status['joinedAt'] as DateTime? ?? DateTime.now(),
  );
});

// Feedback summary for analytics dashboard
final feedbackSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final feedbackService = ref.watch(feedbackServiceProvider);
  return feedbackService.getFeedbackSummary();
});

// Track when to show rating prompt
final ratingPromptTriggerProvider = StateProvider<bool>((ref) {
  return false;
});

// Feedback form state management
final feedbackFormProvider = StateNotifierProvider<FeedbackFormNotifier, FeedbackFormState>(
  (ref) => FeedbackFormNotifier(),
);

class FeedbackFormState {
  final String category;
  final String title;
  final String description;
  final double? rating;
  final String? selectedSeverity;
  final bool isSubmitting;
  final String? errorMessage;

  FeedbackFormState({
    this.category = 'feedback',
    this.title = '',
    this.description = '',
    this.rating,
    this.selectedSeverity,
    this.isSubmitting = false,
    this.errorMessage,
  });

  FeedbackFormState copyWith({
    String? category,
    String? title,
    String? description,
    double? rating,
    String? selectedSeverity,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return FeedbackFormState(
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      selectedSeverity: selectedSeverity ?? this.selectedSeverity,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isValid => title.isNotEmpty && description.isNotEmpty;
}

class FeedbackFormNotifier extends StateNotifier<FeedbackFormState> {
  FeedbackFormNotifier() : super(FeedbackFormState());

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateRating(double rating) {
    state = state.copyWith(rating: rating);
  }

  void updateSeverity(String severity) {
    state = state.copyWith(selectedSeverity: severity);
  }

  void setSubmitting(bool submitting) {
    state = state.copyWith(isSubmitting: submitting);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  void reset() {
    state = FeedbackFormState();
  }
}
