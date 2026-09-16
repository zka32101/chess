import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/phase_m_analytics_providers.dart';
import '../../widgets/analytics_charts.dart';

class CompetitiveFeaturesDashboard extends ConsumerWidget {
  final int days;

  const CompetitiveFeaturesDashboard({Key? key, this.days = 7}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Analytics'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeatureSectionTitle(days: days),
              const SizedBox(height: 16),
              _FeatureOverviewCards(),
              const SizedBox(height: 24),
              Text(
                'Feature Adoption Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _CompetitiveFeaturesList(days: days),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureSectionTitle extends StatelessWidget {
  final int days;

  const _FeatureSectionTitle({required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Last $days Days',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        PopupMenuButton<int>(
          onSelected: (int result) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CompetitiveFeaturesDashboard(days: result),
              ),
            );
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
            const PopupMenuItem<int>(
              value: 7,
              child: Text('Last 7 Days'),
            ),
            const PopupMenuItem<int>(
              value: 30,
              child: Text('Last 30 Days'),
            ),
            const PopupMenuItem<int>(
              value: 90,
              child: Text('Last 90 Days'),
            ),
          ],
          child: const Chip(label: Text('View Options')),
        ),
      ],
    );
  }
}

class _FeatureOverviewCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: KPICard(
                label: 'Active Leaderboard Users',
                value: '1,245',
                unit: 'users',
                trend: '↑ 12%',
                trendColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KPICard(
                label: 'Challenge Participants',
                value: '3,456',
                unit: 'users',
                trend: '↑ 5%',
                trendColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: KPICard(
                label: 'Tournament Entries',
                value: '892',
                unit: 'users',
                trend: '↓ 2%',
                trendColor: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KPICard(
                label: 'Avg Interactions',
                value: '4.2',
                unit: 'per user',
                trend: '↑ 0.3',
                trendColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompetitiveFeaturesList extends ConsumerWidget {
  final int days;

  const _CompetitiveFeaturesList({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresAsync = ref.watch(competitiveFeatureStatsProvider(days));

    return featuresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (features) {
        if (features.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No feature data available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return Column(
          children: [
            ...features.map((stats) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FeatureAdoptionCard(stats: stats),
            )),
          ],
        );
      },
    );
  }
}
