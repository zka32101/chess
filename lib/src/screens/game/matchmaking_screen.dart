import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/matchmaking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/animations.dart';
import 'online_game_screen.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  String? _queueEntryId;
  String _selectedTimeControl = '5+3';

  @override
  void dispose() {
    // Clean up queue entry if screen is closed
    if (_queueEntryId != null) {
      ref.read(matchmakingServiceProvider).leaveQueue(_queueEntryId!);
    }
    super.dispose();
  }

  Future<void> _startSearching() async {
    try {
      final queueEntryId = await ref
          .read(matchmakingServiceProvider)
          .joinQueue(timeControl: _selectedTimeControl);

      setState(() {
        _queueEntryId = queueEntryId;
      });

      ref
          .read(matchmakingStatusProvider.notifier)
          .setStatus(MatchmakingStatus.searching);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining queue: $e')),
        );
      }
    }
  }

  Future<void> _cancelSearch() async {
    if (_queueEntryId != null) {
      try {
        await ref.read(matchmakingServiceProvider).leaveQueue(_queueEntryId!);
        setState(() {
          _queueEntryId = null;
        });
        ref.read(matchmakingStatusProvider.notifier).reset();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error leaving queue: $e')),
          );
        }
      }
    }
  }

  Future<void> _acceptMatch(String matchId) async {
    try {
      await ref.read(matchmakingServiceProvider).acceptMatch(matchId);
      ref
          .read(matchmakingStatusProvider.notifier)
          .setStatus(MatchmakingStatus.found);

      if (mounted) {
        // Navigate to online game screen
        Navigator.of(context).pushReplacement(
          SmoothPageTransition(
            page: OnlineGameScreen(gameId: matchId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting match: $e')),
        );
      }
    }
  }

  Future<void> _declineMatch(String matchId) async {
    try {
      await ref.read(matchmakingServiceProvider).declineMatch(matchId);
      ref
          .read(matchmakingStatusProvider.notifier)
          .setStatus(MatchmakingStatus.declined);

      // Continue searching after a short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && _queueEntryId != null) {
        ref
            .read(matchmakingStatusProvider.notifier)
            .setStatus(MatchmakingStatus.searching);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining match: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchmakingStatus = ref.watch(matchmakingStatusProvider);
    final pendingMatch = ref.watch(pendingMatchStreamProvider);
    final stats = ref.watch(matchmakingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Opponent'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header and status
              Column(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(matchmakingStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(matchmakingStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time control selector (only when idle)
                  if (matchmakingStatus == MatchmakingStatus.idle)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Time Control',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: ['3+0', '5+3', '10+5', '15+10']
                              .map((tc) => ChoiceChip(
                                    label: Text(tc),
                                    selected: _selectedTimeControl == tc,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedTimeControl = tc;
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                ],
              ),

              // Main content area
              Expanded(
                child: matchmakingStatus == MatchmakingStatus.idle
                    ? _buildIdleState()
                    : matchmakingStatus == MatchmakingStatus.searching
                        ? _buildSearchingState(stats)
                        : matchmakingStatus == MatchmakingStatus.found
                            ? pendingMatch.when(
                                data: _buildMatchFoundState,
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (error, stack) => Center(
                                  child: Text('Error: $error'),
                                ),
                              )
                            : const Center(
                                child: Text('Waiting...'),
                              ),
              ),

              // Action buttons
              if (matchmakingStatus == MatchmakingStatus.idle)
                FilledButton(
                  onPressed: _startSearching,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'Start Searching',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              else if (matchmakingStatus == MatchmakingStatus.searching)
                OutlinedButton(
                  onPressed: _cancelSearch,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Cancel Search'),
                )
              else if (matchmakingStatus == MatchmakingStatus.found)
                pendingMatch.when(
                  data: (match) => Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _declineMatch(match?['matchId'] ?? ''),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              _acceptMatch(match?['matchId'] ?? ''),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake,
            size: 80,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Play?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Find a player and start a real-time game',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildSearchingState(AsyncValue stats) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Searching for Opponent',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          stats.when(
            data: (data) => Text(
              'Players in queue: ${data['queueSize'] ?? 0}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text(''),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waiting for a suitable opponent...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildMatchFoundState(Map<String, dynamic>? match) {
    if (match == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final opponentName =
        match['whiteId'] == ref.read(currentUserProvider).value?.uid
            ? match['blackName']
            : match['whiteName'];
    final opponentRating =
        match['whiteId'] == ref.read(currentUserProvider).value?.uid
            ? match['blackRating']
            : match['whiteRating'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Match Found!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  (opponentName as String?)?.substring(0, 1).toUpperCase() ??
                      '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                opponentName ?? 'Unknown Player',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rating: ${opponentRating ?? 1600}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(MatchmakingStatus status) {
    switch (status) {
      case MatchmakingStatus.idle:
        return Colors.grey;
      case MatchmakingStatus.searching:
        return Colors.orange;
      case MatchmakingStatus.found:
        return Colors.green;
      case MatchmakingStatus.declined:
        return Colors.red;
      case MatchmakingStatus.timeout:
        return Colors.red;
      case MatchmakingStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText(MatchmakingStatus status) {
    switch (status) {
      case MatchmakingStatus.idle:
        return 'Idle';
      case MatchmakingStatus.searching:
        return 'Searching...';
      case MatchmakingStatus.found:
        return 'Match Found!';
      case MatchmakingStatus.declined:
        return 'Match Declined';
      case MatchmakingStatus.timeout:
        return 'Search Timeout';
      case MatchmakingStatus.error:
        return 'Error';
    }
  }
}
