import 'package:riverpod/riverpod.dart';
import '../services/streaming_service.dart';

final streamingServiceProvider = Provider((ref) => StreamingService());

final liveStreamsProvider = FutureProvider((ref) {
  return ref.watch(streamingServiceProvider).getLiveStreams();
});

final videoTutorialsProvider = FutureProvider.family<List<VideoContent>, int>((ref, limit) {
  return ref.watch(streamingServiceProvider).getVideoTutorials(limit);
});

final streamAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, streamId) {
  return ref.watch(streamingServiceProvider).getStreamAnalytics(streamId);
});
