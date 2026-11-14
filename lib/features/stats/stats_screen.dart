import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/services/game_stats.dart';
import '../../shared/widgets/app_background.dart';
import '../../l10n/l10n.dart';

/// Statistiques et fun facts sur toutes les parties terminées (voir
/// [GameStats]).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(finishedGamesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(tr('Stats & records', 'Stats & records'))),
      body: AppBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(tr('Erreur : $e', 'Error: $e'))),
            data: (games) => _body(context, GameStats.of(games)),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, GameStats stats) {
    if (!stats.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            tr(
                '🏆\n\nPas encore de partie terminée.\nReviens ici après ta '
                    'première victoire !',
                '🏆\n\nNo finished games yet.\nCome back after your '
                    'first win!'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final cards = <Widget>[
      _FactCard(
        emoji: '🎲',
        title: tr('Parties jouées', 'Games played'),
        value: '${stats.gamesPlayed}',
      ),
      _FactCard(
        emoji: '⏱️',
        title: tr('Temps de jeu cumulé', 'Total play time'),
        value: _formatDuration(stats.totalPlayTime),
      ),
      _FactCard(
        emoji: '✋',
        title: tr('Tours joués', 'Turns played'),
        value: '${stats.totalTurnsPlayed}',
        subtitle: stats.totalEncounters == 0
            ? null
            : tr(
                'dont ${stats.totalEncounters} rencontre'
                    '${stats.totalEncounters > 1 ? 's' : ''}',
                'including ${stats.totalEncounters} encounter'
                    '${stats.totalEncounters > 1 ? 's' : ''}'),
      ),
      if (stats.averageRoundsByTarget.isNotEmpty)
        _FactCard(
          emoji: '📊',
          title: tr('Manches en moyenne', 'Average rounds'),
          value: '',
          subtitle: [
            for (final entry in stats.averageRoundsByTarget.entries)
              tr('${entry.key} pts : ${entry.value.toStringAsFixed(1)} manches', '${entry.key} pts: ${entry.value.toStringAsFixed(1)} rounds'),
          ].join('\n'),
        ),
      if (stats.biggestHit != null)
        _FactCard(
          emoji: '💥',
          title: tr('Plus gros carton', 'Biggest hit'),
          value: '+${stats.biggestHit!.value}',
          subtitle: stats.biggestHit!.name,
        ),
      if (stats.topWinner != null)
        _FactCard(
          emoji: '👑',
          title: tr('Le plus titré', 'Most wins'),
          value: stats.topWinner!.name,
          subtitle: tr(
              '${stats.topWinner!.value} victoire'
                  '${stats.topWinner!.value > 1 ? 's' : ''}',
              '${stats.topWinner!.value} win'
                  '${stats.topWinner!.value > 1 ? 's' : ''}'),
        ),
      if (stats.longestGameRounds != null)
        _FactCard(
          emoji: '🐢',
          title: tr('Partie la plus longue', 'Longest game'),
          value: tr('${stats.longestGameRounds} manches', '${stats.longestGameRounds} rounds'),
          subtitle: '${stats.longestGameTarget} pts',
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: cards,
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return tr('moins d\'une minute', 'less than a minute');
    if (d.inHours < 1) return '${d.inMinutes} min';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return minutes == 0
        ? tr('$hours h', '$hours h')
        : tr('$hours h $minutes min', '$hours h $minutes min');
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.emoji,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String emoji;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant)),
                if (value.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 13.5, color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
