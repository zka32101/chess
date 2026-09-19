import 'package:flutter/material.dart';
import 'package:chess_tactics_master/src/models/match_record.dart';

/// Visual timeline representation of recent matches
class MatchHistoryTimeline extends StatelessWidget {
  final List<MatchRecord> matches;
  final int maxDisplay;

  const MatchHistoryTimeline({
    Key? key,
    required this.matches,
    this.maxDisplay = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'マッチ履歴がありません',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final displayMatches = matches.take(maxDisplay).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近のマッチ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayMatches.length,
            itemBuilder: (context, index) {
              final match = displayMatches[index];
              return _buildTimelineItem(context, match, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      BuildContext context, MatchRecord match, int index) {
    final isWin = match.playerWon;
    final isDraw = !isWin && match.opponentWon == false;

    final resultColor = isWin
        ? Colors.green
        : (match.opponentWon)
            ? Colors.red
            : Colors.orange;

    final resultLabel = isWin ? 'W' : (match.opponentWon ? 'L' : 'D');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: resultColor,
                ),
                child: Center(
                  child: Text(
                    resultLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              if (index < 20)
                Container(
                  width: 2,
                  height: 20,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Match details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match.opponentName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDate(match.date),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match.timeControl,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      _formatRatingChange(
                        match.playerRatingBefore,
                        match.playerRatingAfter,
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getRatingChangeColor(
                              match.playerRatingBefore,
                              match.playerRatingAfter,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今日';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}週前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  String _formatRatingChange(int before, int after) {
    final change = after - before;
    if (change > 0) {
      return '+$change';
    } else if (change < 0) {
      return '$change';
    } else {
      return '±0';
    }
  }

  Color _getRatingChangeColor(int before, int after) {
    final change = after - before;
    if (change > 0) {
      return Colors.green;
    } else if (change < 0) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }
}
