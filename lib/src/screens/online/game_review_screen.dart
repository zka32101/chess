import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess_tactics_master/src/models/online_game.dart';

/// Screen for reviewing/replaying completed games
class GameReviewScreen extends ConsumerStatefulWidget {
  final String gameId;
  final OnlineGame game;

  const GameReviewScreen({
    Key? key,
    required this.gameId,
    required this.game,
  }) : super(key: key);

  @override
  ConsumerState<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends ConsumerState<GameReviewScreen> {
  late int currentMoveIndex;
  late bool isAutoPlaying;
  late int autoPlaySpeed; // milliseconds between moves

  @override
  void initState() {
    super.initState();
    currentMoveIndex = -1; // Start before first move
    isAutoPlaying = false;
    autoPlaySpeed = 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Review'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGameInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGameHeader(),
            const SizedBox(height: 16),
            _buildChessBoard(),
            const SizedBox(height: 16),
            _buildControls(),
            const SizedBox(height: 24),
            _buildMoveList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Build game header with player info
  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildPlayerCard(
                  name: widget.game.whitePlayerName,
                  rating: widget.game.whiteRating,
                  isWhite: true,
                  won: widget.game.result == 'white_win',
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child:
                    Text('vs', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: _buildPlayerCard(
                  name: widget.game.blackPlayerName,
                  rating: widget.game.blackRating,
                  isWhite: false,
                  won: widget.game.result == 'black_win',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGameMetadata(),
        ],
      ),
    );
  }

  /// Build player card
  Widget _buildPlayerCard({
    required String name,
    required int rating,
    required bool isWhite,
    required bool won,
  }) {
    final backgroundColor = won ? Colors.green[100] : Colors.red[100];
    final textColor = won ? Colors.green[900] : Colors.red[900];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
          ),
          Text(
            '$rating',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }

  /// Build game metadata
  Widget _buildGameMetadata() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetadataItem('Type', widget.game.type),
        _buildMetadataItem('Time', widget.game.timeControl),
        _buildMetadataItem('Moves', '${widget.game.moves.length}'),
        _buildMetadataItem('Result', widget.game.resultReason ?? ''),
      ],
    );
  }

  /// Build metadata item
  Widget _buildMetadataItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  /// Build chess board placeholder
  Widget _buildChessBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.brown[100],
                border: Border.all(color: Colors.brown, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(8, (row) {
                  return Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(8, (col) {
                        final isLight = (row + col) % 2 == 0;
                        final backgroundColor =
                            isLight ? Colors.amber[100] : Colors.amber[700];

                        return Expanded(
                          child: Container(
                            color: backgroundColor,
                            child: Center(
                              child: _buildSquareContent(row, col),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Move ${currentMoveIndex + 1}/${widget.game.moves.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Build square content
  Widget _buildSquareContent(int row, int col) {
    // Placeholder - in real implementation, would show chess pieces
    return const SizedBox();
  }

  /// Build control buttons
  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _goToStart,
                tooltip: 'Go to start',
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: _previousMove,
                tooltip: 'Previous move',
              ),
              SizedBox(
                width: 50,
                child: IconButton(
                  icon: Icon(isAutoPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _toggleAutoPlay,
                  tooltip: isAutoPlaying ? 'Pause' : 'Play',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: _nextMove,
                tooltip: 'Next move',
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _goToEnd,
                tooltip: 'Go to end',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: currentMoveIndex.toDouble(),
            min: -1,
            max: (widget.game.moves.length - 1).toDouble(),
            onChanged: (value) {
              setState(() {
                currentMoveIndex = value.toInt();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Speed:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Slider(
                value: autoPlaySpeed.toDouble(),
                min: 500,
                max: 3000,
                divisions: 5,
                label: '${autoPlaySpeed}ms',
                onChanged: (value) {
                  setState(() {
                    autoPlaySpeed = value.toInt();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build move list
  Widget _buildMoveList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moves',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildMoveListContent(),
        ],
      ),
    );
  }

  /// Build move list content
  Widget _buildMoveListContent() {
    if (widget.game.moves.isEmpty) {
      return Center(
        child: Text(
          'No moves recorded',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(widget.game.moves.length, (index) {
        final move = widget.game.moves[index];
        final moveStr = move.promotion != null
            ? '${move.from}${move.to}=${move.promotion}'
            : '${move.from}${move.to}';
        final isSelected = index == currentMoveIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              currentMoveIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[100] : Colors.grey[200],
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              moveStr,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.blue[900] : null,
                  ),
            ),
          ),
        );
      }),
    );
  }

  // Control callbacks
  void _goToStart() {
    setState(() {
      currentMoveIndex = -1;
      isAutoPlaying = false;
    });
  }

  void _previousMove() {
    setState(() {
      if (currentMoveIndex > -1) {
        currentMoveIndex--;
      }
    });
  }

  void _nextMove() {
    setState(() {
      if (currentMoveIndex < widget.game.moves.length - 1) {
        currentMoveIndex++;
      }
    });
  }

  void _goToEnd() {
    setState(() {
      currentMoveIndex = widget.game.moves.length - 1;
      isAutoPlaying = false;
    });
  }

  void _toggleAutoPlay() {
    setState(() {
      isAutoPlaying = !isAutoPlaying;
    });

    if (isAutoPlaying) {
      _playMoves();
    }
  }

  Future<void> _playMoves() async {
    while (isAutoPlaying && currentMoveIndex < widget.game.moves.length - 1) {
      await Future.delayed(Duration(milliseconds: autoPlaySpeed));
      if (mounted) {
        setState(() {
          if (currentMoveIndex < widget.game.moves.length - 1) {
            currentMoveIndex++;
          } else {
            isAutoPlaying = false;
          }
        });
      }
    }
  }

  void _showGameInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Game ID', widget.game.gameId),
            _buildInfoRow('Type', widget.game.type),
            _buildInfoRow('Time Control', widget.game.timeControl),
            _buildInfoRow('Result', widget.game.result ?? ''),
            _buildInfoRow('Result Reason', widget.game.resultReason ?? ''),
            _buildInfoRow(
              'Duration',
              _formatDuration(
                widget.game.endedAt?.difference(
                        widget.game.startedAt ?? widget.game.createdAt) ??
                    Duration.zero,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
