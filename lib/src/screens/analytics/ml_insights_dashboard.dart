import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/phase_n_ml_providers.dart';
import '../../widgets/ml_analytics_charts.dart';

class MLInsightsDashboard extends ConsumerWidget {
  const MLInsightsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(mlInsightsSummaryProvider);
    final alertsAsync = ref.watch(mlAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ML Insights'), elevation: 0),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (summary) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MLSummaryCards(summary: summary),
                const SizedBox(height: 24),
                _AnomalyAlertsSection(alertsAsync: alertsAsync),
                const SizedBox(height: 24),
                _RecommendationsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MLSummaryCards extends StatelessWidget {
  final MLInsightsSummary summary;

  const _MLSummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _MetricCard(
          label: 'Active Anomalies',
          value: '${summary.activeAnomalies}',
          color: summary.criticalAlerts > 0 ? Colors.red : Colors.orange,
        ),
        _MetricCard(
          label: 'High-Risk Users',
          value: '${summary.highRiskUsers}',
          color: Colors.red,
        ),
        _MetricCard(
          label: 'Critical Alerts',
          value: '${summary.criticalAlerts}',
          color: Colors.deepOrange,
        ),
        _MetricCard(
          label: 'Warnings',
          value: '${summary.warningAlerts}',
          color: Colors.amber,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnomalyAlertsSection extends ConsumerWidget {
  final AsyncValue<List<AnomalyAlert>> alertsAsync;

  const _AnomalyAlertsSection({required this.alertsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Anomalies',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        alertsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (alerts) {
            if (alerts.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No anomalies detected',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            return Column(
              children: alerts.take(5).map((alert) {
                return AnomalyAlertCard(alert: alert);
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RecommendationsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendedActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        recommendationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (actions) {
            if (actions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No actions recommended',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            return Column(
              children: actions.map((action) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
