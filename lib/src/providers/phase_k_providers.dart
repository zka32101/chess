import 'package:riverpod/riverpod.dart';
import '../services/ranking_service.dart';
import '../services/achievement_service.dart';
import '../services/game_sharing_service.dart';
import '../services/social_network_service.dart';
import '../services/challenge_service.dart';

// Service Providers
final rankingServiceProvider = Provider((ref) => RankingService());
final achievementServiceProvider = Provider((ref) => AchievementService());
final gameSharingServiceProvider = Provider((ref) => GameSharingService());
final socialNetworkServiceProvider = Provider((ref) => SocialNetworkService());
final challengeServiceProvider = Provider((ref) => ChallengeService());

// Ranking Providers
final globalRankingsProvider =
    FutureProvider.family<List<PlayerRanking>, int>((ref, limit) {
  return ref.watch(rankingServiceProvider).getGlobalRankings(limit);
});

final regionalRankingsProvider = FutureProvider.family<List<PlayerRanking>,
    (String, int)>((ref, params) {
  final (region, limit) = params;
  return ref.watch(rankingServiceProvider).getRegionalRankings(region, limit);
});

final userRankPositionProvider =
    FutureProvider.family<int, String>((ref, userId) {
  return ref.watch(rankingServiceProvider).getUserRankPosition(userId);
});

final friendRankingsProvider =
    FutureProvider.family<List<PlayerRanking>, String>((ref, userId) {
  return ref.watch(rankingServiceProvider).getFriendRankings(userId);
});

final rankingStatisticsProvider = FutureProvider((ref) {
  return ref.watch(rankingServiceProvider).getRankingStatistics();
});

// Achievement Providers
final userAchievementsProvider =
    FutureProvider.family<List<UserAchievement>, String>((ref, userId) {
  return ref.watch(achievementServiceProvider).getUserAchievements(userId);
});

final allAchievementsProvider = FutureProvider((ref) {
  return ref.watch(achievementServiceProvider).getAllAchievements();
});

final nearbyAchievementsProvider =
    FutureProvider.family<List<NearbyAchievement>, String>((ref, userId) {
  return ref.watch(achievementServiceProvider).getNearbyAchievements(userId);
});

final achievementProgressProvider = FutureProvider.family<AchievementProgress,
    (String, String)>((ref, params) {
  final (userId, achievementId) = params;
  return ref
      .watch(achievementServiceProvider)
      .getAchievementProgress(userId, achievementId);
});

// Game Sharing Providers
final publicGamesProvider =
    FutureProvider.family<List<SharedGame>, int>((ref, limit) {
  return ref.watch(gameSharingServiceProvider).getPublicGames(limit);
});

final gameViewerDataProvider =
    FutureProvider.family<GameViewerData, String>((ref, gameId) {
  return ref.watch(gameSharingServiceProvider).getGameViewerData(gameId);
});

// Social Network Providers
final friendsProvider =
    FutureProvider.family<List<Friend>, String>((ref, userId) {
  return ref.watch(socialNetworkServiceProvider).getFriends(userId);
});

final socialFeedProvider = FutureProvider.family<List<FeedItem>,
    (String, int)>((ref, params) {
  final (userId, limit) = params;
  return ref.watch(socialNetworkServiceProvider).getSocialFeed(userId, limit);
});

final userProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, userId) {
  return ref.watch(socialNetworkServiceProvider).getUserProfile(userId);
});

// Challenge Providers
final activeChallengesProvider =
    FutureProvider.family<List<Challenge>, String>((ref, userId) {
  return ref.watch(challengeServiceProvider).getUserActiveChallenges(userId);
});

final challengeLeaderboardProvider = FutureProvider.family<
    List<ChallengeLeaderboard>, String>((ref, challengeId) {
  return ref
      .watch(challengeServiceProvider)
      .getChallengeLeaderboard(challengeId);
});

// State Providers
final selectedRankingFilterProvider =
    StateProvider<String>((ref) => 'global');

final achievementFilterProvider = StateProvider<String>((ref) => 'all');

final activeChallengeFilterProvider =
    StateProvider<String>((ref) => 'all');

// Computed Providers
final totalFriendsProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final friends = await ref.watch(friendsProvider(userId).future);
  return friends.length;
});

final unlockedAchievementCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final achievements = await ref.watch(userAchievementsProvider(userId).future);
  return achievements.length;
});

final achievementCompletionPercentageProvider =
    FutureProvider.family<double, String>((ref, userId) async {
  final all = await ref.watch(allAchievementsProvider.future);
  final unlocked = await ref.watch(userAchievementsProvider(userId).future);
  return all.isNotEmpty ? (unlocked.length / all.length * 100) : 0;
});

final userRankProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return ref.watch(rankingServiceProvider).getUserRankPosition(userId);
});

final hasChallengesProvider =
    FutureProvider.family<bool, String>((ref, userId) async {
  final challenges = await ref.watch(activeChallengesProvider(userId).future);
  return challenges.isNotEmpty;
});

final socialStatsProvider = FutureProvider.family<SocialStats, String>((ref, userId) async {
  final friends = await ref.watch(friendsProvider(userId).future);
  final achievements = await ref.watch(userAchievementsProvider(userId).future);
  final challenges = await ref.watch(activeChallengesProvider(userId).future);

  return SocialStats(
    friendCount: friends.length,
    achievementCount: achievements.length,
    activeChallengeCount: challenges.length,
  );
});

// Helper class for social statistics
class SocialStats {
  final int friendCount;
  final int achievementCount;
  final int activeChallengeCount;

  SocialStats({
    required this.friendCount,
    required this.achievementCount,
    required this.activeChallengeCount,
  });
}
