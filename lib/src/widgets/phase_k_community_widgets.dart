import 'package:flutter/material.dart';
import '../providers/phase_k_providers.dart';
import '../services/ranking_service.dart';
import '../services/achievement_service.dart';
import '../services/game_sharing_service.dart';
import '../services/social_network_service.dart';
import '../services/challenge_service.dart';

// Ranking Widgets
class RankingCard extends StatelessWidget {
  final PlayerRanking ranking;
  final VoidCallback? onTap;

  const RankingCard({
    required this.ranking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text('${ranking.rank}'),
        ),
        title: Text(ranking.username),
        subtitle: Text('${ranking.wins}W - ${ranking.losses}L'),
        trailing: Text('${ranking.rating}', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class RankingListView extends StatelessWidget {
  final List<PlayerRanking> rankings;
  final VoidCallback? onRefresh;

  const RankingListView({
    required this.rankings,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: ListView.builder(
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          return RankingCard(ranking: rankings[index]);
        },
      ),
    );
  }
}

// Achievement Widgets
class AchievementBadge extends StatelessWidget {
  final AchievementDefinition achievement;
  final bool isUnlocked;

  const AchievementBadge({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: achievement.name,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked ? Colors.amber : Colors.grey[300],
          border: Border.all(
            color: isUnlocked ? Colors.orange : Colors.grey,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.star,
            color: isUnlocked ? Colors.white : Colors.grey,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class AchievementGrid extends StatelessWidget {
  final List<AchievementDefinition> achievements;
  final List<UserAchievement> unlockedAchievements;

  const AchievementGrid({
    required this.achievements,
    required this.unlockedAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = unlockedAchievements
            .any((ua) => ua.achievementId == achievement.achievementId);
        
        return AchievementBadge(
          achievement: achievement,
          isUnlocked: isUnlocked,
        );
      },
    );
  }
}

class AchievementProgressCard extends StatelessWidget {
  final AchievementDefinition achievement;
  final AchievementProgress progress;

  const AchievementProgressCard({
    required this.achievement,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(achievement.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (progress.isUnlocked)
                  Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            SizedBox(height: 8),
            Text(achievement.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progressPercentage / 100,
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Text(
              '${progress.currentValue} / ${progress.targetValue}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Game Sharing Widgets
class GameShareDialog extends StatelessWidget {
  final String gameId;
  final VoidCallback onShare;

  const GameShareDialog({
    required this.gameId,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share Game'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Share Link',
              hintText: 'https://chesstacticsmaster.app/game/...',
              suffixIcon: IconButton(
                icon: Icon(Icons.copy),
                onPressed: () {
                  // Copy to clipboard
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onShare();
            Navigator.pop(context);
          },
          child: Text('Share'),
        ),
      ],
    );
  }
}

class GameViewerWidget extends StatelessWidget {
  final GameViewerData gameData;

  const GameViewerWidget({required this.gameData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PGN:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(gameData.pgn, style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(12),
            child: Text('Comments (${gameData.comments.length})', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (gameData.comments.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              itemCount: gameData.comments.length,
              itemBuilder: (context, index) {
                final comment = gameData.comments[index];
                return ListTile(
                  title: Text(comment.username),
                  subtitle: Text(comment.content),
                  trailing: Text('Move ${comment.moveNumber}'),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Social Widgets
class FriendListCard extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;

  const FriendListCard({
    required this.friend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: friend.isOnline ? Colors.green : Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(friend.username),
        subtitle: Text('Rating: ${friend.rating}'),
        trailing: Text(
          friend.isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            color: friend.isOnline ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class SocialFeedWidget extends StatelessWidget {
  final List<FeedItem> feedItems;

  const SocialFeedWidget({required this.feedItems});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: feedItems.length,
      itemBuilder: (context, index) {
        final item = feedItems[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(_actionTypeToString(item.actionType)),
            subtitle: Text(item.actionData),
            trailing: Text(
              _timeAgoString(item.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  String _actionTypeToString(String type) {
    switch (type) {
      case 'game_played':
        return 'Played a game';
      case 'achievement_unlocked':
        return 'Unlocked an achievement';
      case 'lesson_completed':
        return 'Completed a lesson';
      default:
        return type;
    }
  }

  String _timeAgoString(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${difference.inDays ~/ 7}w ago';
  }
}

// Challenge Widgets
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final int participantCount;
  final VoidCallback? onJoin;

  const ChallengeCard({
    required this.challenge,
    required this.participantCount,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(challenge.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(challenge.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Participants: $participantCount'),
                Text('Target: ${challenge.targetCount}'),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: participantCount / challenge.targetCount.clamp(1, double.infinity),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onJoin,
              child: Text('Join Challenge'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChallengeLeaderboardWidget extends StatelessWidget {
  final List<ChallengeLeaderboard> leaderboard;

  const ChallengeLeaderboardWidget({required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final entry = leaderboard[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${entry.rank}'),
            ),
            title: Text(entry.username),
            subtitle: Text('${entry.progress} completed'),
            trailing: Text('${entry.score} pts', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

// User Profile Widget
class UserProfileCard extends StatelessWidget {
  final UserProfile profile;

  const UserProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(profile.username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(profile.bio, style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Rating', '${profile.rating}'),
                _buildStat('Wins', '${profile.wins}'),
                _buildStat('Achievements', '${profile.achievements.length}'),
              ],
            ),
            SizedBox(height: 16),
            Text('Win Rate: ${(profile.winRate * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
