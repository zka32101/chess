import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chess_lessons_service.dart';
import '../providers/phase_i_providers.dart';

/// Interactive lesson board displaying PGN moves step-by-step
class InteractiveLessonBoard extends StatefulWidget {
  const InteractiveLessonBoard({
    required this.lesson,
    Key? key,
    this.onComplete,
  }) : super(key: key);
  final ChessLesson lesson;
  final VoidCallback? onComplete;

  @override
  State<InteractiveLessonBoard> createState() => _InteractiveLessonBoardState();
}

class _InteractiveLessonBoardState extends State<InteractiveLessonBoard> {
  int currentMoveIndex = 0;
  late List<String> moves;

  @override
  void initState() {
    super.initState();
    // Parse PGN to extract moves
    moves = _parseMoves(widget.lesson.pgn);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Lesson title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.lesson.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Chess board visualization (placeholder)
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Move ${currentMoveIndex + 1} / ${moves.length}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Key points for current move
          if (widget.lesson.keyPoints.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Points',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ...widget.lesson.keyPoints.map((point) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• $point',
                            style: Theme.of(context).textTheme.bodySmall),
                      )),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: currentMoveIndex > 0 ? _previousMove : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _resetBoard,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed:
                    currentMoveIndex < moves.length - 1 ? _nextMove : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Complete lesson button
          if (currentMoveIndex == moves.length - 1)
            ElevatedButton(
              onPressed: () {
                widget.onComplete?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lesson completed!')),
                );
              },
              child: const Text('Mark as Complete'),
            ),
        ],
      );

  void _nextMove() {
    if (currentMoveIndex < moves.length - 1) {
      setState(() => currentMoveIndex++);
    }
  }

  void _previousMove() {
    if (currentMoveIndex > 0) {
      setState(() => currentMoveIndex--);
    }
  }

  void _resetBoard() {
    setState(() => currentMoveIndex = 0);
  }

  List<String> _parseMoves(String pgn) {
    // Simplified parsing - extract moves from PGN
    if (pgn.isEmpty) return [];
    return pgn.split(' ').where((move) => move.isNotEmpty).toList();
  }
}

/// Card showing lesson completion progress
class LessonCompletionCard extends ConsumerWidget {
  const LessonCompletionCard({
    required this.progress,
    Key? key,
    this.onContinue,
  }) : super(key: key);
  final UserLessonProgress progress;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${(progress.percentageComplete * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.percentageComplete,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(progress.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  progress.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Times reviewed
              Text(
                'Reviewed ${progress.timesReviewed} time${progress.timesReviewed != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: const Text('Continue Learning'),
                ),
              ),
            ],
          ),
        ),
      );

  Color _getStatusColor(String status) {
    switch (status) {
      case 'not_started':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'reviewed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// Widget displaying opening statistics
class OpeningStatisticsWidget extends StatelessWidget {
  const OpeningStatisticsWidget({
    required this.opening,
    Key? key,
  }) : super(key: key);
  final OpeningExplanation opening;

  @override
  Widget build(BuildContext context) {
    final winRates = opening.winRates;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opening Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'White Win Rate',
              '${(winRates['white'] ?? 0).toStringAsFixed(1)}%',
              Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Black Win Rate',
              '${(winRates['black'] ?? 0).toStringAsFixed(1)}%',
              Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Draw Rate',
              '${(winRates['draws'] ?? 0).toStringAsFixed(1)}%',
              Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Total Games: ${opening.totalGames}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
        ],
      );
}

/// Card displaying tactic pattern
class TacticsPatternCard extends StatelessWidget {
  const TacticsPatternCard({
    required this.pattern,
    Key? key,
  }) : super(key: key);
  final TacticsPattern pattern;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pattern.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildDifficultyBadge(context, pattern.difficulty),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pattern.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // Motifs
              if (pattern.motifs.isNotEmpty) ...[
                Text(
                  'Tactical Motifs',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: pattern.motifs
                      .map((motif) => Chip(label: Text(motif)))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              // Execution steps
              if (pattern.executionSteps.isNotEmpty) ...[
                Text(
                  'How to Execute',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  pattern.executionSteps,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildDifficultyBadge(BuildContext context, int difficulty) {
    final colors = [
      Colors.grey,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.red
    ];
    final labels = ['?', 'Easy', 'Medium', 'Hard', 'Expert'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors[difficulty].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[difficulty].withOpacity(0.3)),
      ),
      child: Text(
        labels[difficulty],
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors[difficulty],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Widget showing user's learning progress
class LessonProgressWidget extends ConsumerWidget {
  const LessonProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsSummary = ref.watch(lessonStatsSummaryProvider);

    return statsSummary.when(
      data: (stats) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatTile(
                    context,
                    'Lessons',
                    '${stats.totalLessonsCompleted}',
                    Icons.school,
                  ),
                  _buildStatTile(
                    context,
                    'Streak',
                    '${stats.currentStreak}',
                    Icons.local_fire_department,
                  ),
                  _buildStatTile(
                    context,
                    'Progress',
                    '${(stats.overallProgress * 100).toInt()}%',
                    Icons.trending_up,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Topics mastered
              if (stats.topicsMastered > 0) ...[
                Text(
                  'Topics Mastered (${stats.topicsMastered})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Great! You\'ve mastered ${stats.topicsMastered} topic${stats.topicsMastered != 1 ? 's' : ''}. Keep practicing!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Topics to improve
              if (stats.topicsToImprove > 0) ...[
                Text(
                  'Topics to Improve (${stats.topicsToImprove})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Focus on ${stats.topicsToImprove} topic${stats.topicsToImprove != 1 ? 's' : ''} to improve your skills.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) =>
      Column(
        children: [
          Icon(icon, size: 28, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
}
