import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_leaderboard.dart';

/// Leaderboard screen displaying player rankings
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late LeaderboardFilter selectedFilter;
  late List<LeaderboardEntry> mockEntries;

  @override
  void initState() {
    super.initState();
    selectedFilter = LeaderboardFilter.allTime;
    _initializeMockData();
  }

  /// Initialize mock leaderboard data
  void _initializeMockData() {
    mockEntries = [
      LeaderboardEntry(
        playerId: 'user_1',
        playerName: 'Magnus Carlsen',
        rating: 2820,
        rank: 1,
        totalGamesPlayed: 1250,
        wins: 850,
        losses: 150,
        draws: 250,
        winRate: (850 / 1250) * 100,
        updatedAt: DateTime.now(),
      ),
      LeaderboardEntry(
        playerId: 'user_2',
        playerName: 'Fabiano Caruana',
        rating: 2790,
        rank: 2,
        totalGamesPlayed: 1100,
        wins: 720,
        losses: 160,
        draws: 220,
        winRate: (720 / 1100) * 100,
        updatedAt: DateTime.now(),
      ),
      LeaderboardEntry(
        playerId: 'user_3',
        playerName: 'Ding Liren',
        rating: 2780,
        rank: 3,
        totalGamesPlayed: 950,
        wins: 630,
        losses: 170,
        draws: 150,
        winRate: (630 / 950) * 100,
        updatedAt: DateTime.now(),
      ),
      LeaderboardEntry(
        playerId: 'user_4',
        playerName: 'Alireza Firouzja',
        rating: 2770,
        rank: 4,
        totalGamesPlayed: 850,
        wins: 550,
        losses: 180,
        draws: 120,
        winRate: (550 / 850) * 100,
        updatedAt: DateTime.now(),
      ),
      LeaderboardEntry(
        playerId: 'user_5',
        playerName: 'Hikaru Nakamura',
        rating: 2760,
        rank: 5,
        totalGamesPlayed: 1500,
        wins: 950,
        losses: 250,
        draws: 300,
        winRate: (950 / 1500) * 100,
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: _buildLeaderboardList(),
            ),
          ],
        ),
      );

  /// Build filter chips
  Widget _buildFilterChips() => Container(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: LeaderboardFilter.values.map((filter) {
              final isSelected = filter == selectedFilter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.blue[100],
                  labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.blue[900] : Colors.grey[700],
                      ),
                ),
              );
            }).toList(),
          ),
        ),
      );

  /// Build leaderboard list
  Widget _buildLeaderboardList() {
    if (mockEntries.isEmpty) {
      return Center(
        child: Text(
          'No players found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      );
    }

    return ListView.builder(
      itemCount: mockEntries.length,
      itemBuilder: (context, index) {
        final entry = mockEntries[index];
        return _buildLeaderboardEntry(entry);
      },
    );
  }

  /// Build individual leaderboard entry
  Widget _buildLeaderboardEntry(LeaderboardEntry entry) {
    final ratingCategory = PlayerStatistics.getRatingCategory(entry.rating);
    final ratingBadgeColor = PlayerStatistics.getRatingBadgeColor(entry.rating);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getRankBadgeColor(entry.rank),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${entry.rank}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.playerName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(int.parse(
                                ratingBadgeColor.replaceFirst('#', '0xff'))),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ratingCategory,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.totalGamesPlayed} games',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.rating}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Row(
                    children: [
                      _buildStatBadge('W', entry.wins, Colors.green),
                      const SizedBox(width: 4),
                      _buildStatBadge('D', entry.draws, Colors.amber),
                      const SizedBox(width: 4),
                      _buildStatBadge('L', entry.losses, Colors.red),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build stat badge
  Widget _buildStatBadge(String label, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          '$label$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      );

  /// Get rank badge color
  Color _getRankBadgeColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.blue;
    }
  }
}

/// Player profile preview (tap on leaderboard entry)
class PlayerProfilePreview extends StatelessWidget {
  const PlayerProfilePreview({
    required this.entry,
    Key? key,
  }) : super(key: key);
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final ratingCategory = PlayerStatistics.getRatingCategory(entry.rating);
    final winRate = entry.winRate;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.playerName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildDetailedStats(),
          ],
        ),
      ),
    );
  }

  /// Build profile header
  Widget _buildProfileHeader() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                entry.playerName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${entry.rank} - ${entry.rating} Rating',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  /// Build stats grid
  Widget _buildStatsGrid() {
    final winRate =
        (entry.wins / entry.totalGamesPlayed * 100).toStringAsFixed(1);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
            'Total Games', entry.totalGamesPlayed.toString(), Colors.blue),
        _buildStatCard('Win Rate', '$winRate%', Colors.green),
        _buildStatCard('Wins', entry.wins.toString(), Colors.green),
        _buildStatCard('Losses', entry.losses.toString(), Colors.red),
      ],
    );
  }

  /// Build stat card
  Widget _buildStatCard(String label, String value, Color color) => Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );

  /// Build detailed stats
  Widget _buildDetailedStats() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Game Statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildStatRow('Total Games', entry.totalGamesPlayed.toString()),
              _buildStatRow('Wins',
                  '${entry.wins} (${(entry.wins / entry.totalGamesPlayed * 100).toStringAsFixed(1)}%)'),
              _buildStatRow('Draws',
                  '${entry.draws} (${(entry.draws / entry.totalGamesPlayed * 100).toStringAsFixed(1)}%)'),
              _buildStatRow('Losses',
                  '${entry.losses} (${(entry.losses / entry.totalGamesPlayed * 100).toStringAsFixed(1)}%)'),
              const SizedBox(height: 12),
              _buildStatRow('Rating', entry.rating.toString()),
              _buildStatRow('Rank', '#${entry.rank}'),
            ],
          ),
        ),
      );

  /// Build stat row
  Widget _buildStatRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
