import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_leaderboard.freezed.dart';
part 'player_leaderboard.g.dart';

/// Player leaderboard entry
@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String playerId,
    required String playerName,
    required int rating,
    required int rank,
    required int totalGamesPlayed,
    required int wins,
    required int losses,
    required int draws,
    required double winRate,
    required DateTime updatedAt,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}

/// Leaderboard filters
enum LeaderboardFilter {
  allTime('All Time'),
  weekly('This Week'),
  monthly('This Month'),
  blitz('Blitz'),
  rapid('Rapid'),
  classical('Classical');

  final String label;
  const LeaderboardFilter(this.label);
}

/// Player statistics for ranking
@freezed
class PlayerStatistics with _$PlayerStatistics {
  const factory PlayerStatistics({
    required String playerId,
    required String playerName,
    required int rating,
    required int ratingPeak,
    required int totalGames,
    required int wins,
    required int losses,
    required int draws,
    required double winRate,
    required double drawRate,
    required double lossRate,
    required int currentStreak,
    required String currentStreakType, // win, loss, draw
    required DateTime lastGameAt,
    required DateTime createdAt,
  }) = _PlayerStatistics;

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatisticsFromJson(json);

  /// Calculate win rate from wins and total games
  static double calculateWinRate(int wins, int total) {
    if (total == 0) return 0;
    return (wins / total) * 100;
  }

  /// Get rating category based on rating value
  static String getRatingCategory(int rating) {
    if (rating < 1000) return 'Beginner';
    if (rating < 1200) return 'Novice';
    if (rating < 1400) return 'Intermediate';
    if (rating < 1600) return 'Advanced';
    if (rating < 1800) return 'Expert';
    if (rating < 2000) return 'Master';
    if (rating < 2200) return 'International Master';
    return 'Grandmaster';
  }

  /// Get rating badge color
  static String getRatingBadgeColor(int rating) {
    if (rating < 1000) return '#CCCCCC'; // Gray
    if (rating < 1200) return '#0066FF'; // Blue
    if (rating < 1400) return '#00CC00'; // Green
    if (rating < 1600) return '#FFAA00'; // Orange
    if (rating < 1800) return '#FF5500'; // Red-Orange
    if (rating < 2000) return '#FF0000'; // Red
    if (rating < 2200) return '#8800FF'; // Purple
    return '#FFFF00'; // Gold
  }
}

/// Leaderboard data with entries
@freezed
class Leaderboard with _$Leaderboard {
  const factory Leaderboard({
    required List<LeaderboardEntry> entries,
    required LeaderboardFilter filter,
    required int totalPlayers,
    required DateTime updatedAt,
  }) = _Leaderboard;
  const Leaderboard._();

  factory Leaderboard.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardFromJson(json);

  /// Get player rank
  int? getPlayerRank(String playerId) {
    try {
      return entries.firstWhere((e) => e.playerId == playerId).rank;
    } catch (e) {
      return null;
    }
  }

  /// Get player entry
  LeaderboardEntry? getPlayerEntry(String playerId) {
    try {
      return entries.firstWhere((e) => e.playerId == playerId);
    } catch (e) {
      return null;
    }
  }
}
