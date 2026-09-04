import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/services/game_stats.dart';
import '../../shared/widgets/app_background.dart';

/// Statistiques et fun facts, calculés à partir de **toutes** les parties
/// terminées conservées sur l'appareil (§ évolution « stats & fun facts »).
///
/// Rien n'est stocké en plus : tout se recalcule à la demande (voir
/// [GameStats]) à partir des fichiers de parties déjà là — une partie
/// terminée n'est plus jamais effacée (voir `GameController.newGame`).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(finishedGamesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Stats & records')),
      body: AppBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (games) => _body(context, GameStats.of(games)),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, GameStats stats) {
    if (!stats.hasData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '🏆\n\nPas encore de partie terminée.\nReviens ici après ta '
            'première victoire !',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final cards = <Widget>[
      _FactCard(
        emoji: '🎲',
        title: 'Parties jouées',
        value: '${stats.gamesPlayed}',
      ),
      _FactCard(
        emoji: '⏱️',
        title: 'Temps de jeu cumulé',
        value: _formatDuration(stats.totalPlayTime),
      ),
      _FactCard(
        emoji: '✋',
        title: 'Tours joués',
        value: '${stats.totalTurnsPlayed}',
        subtitle: stats.totalEncounters == 0
            ? null
            : 'dont ${stats.totalEncounters} rencontre'
                '${stats.totalEncounters > 1 ? 's' : ''}',
      ),
      if (stats.averageRoundsByTarget.isNotEmpty)
        _FactCard(
          emoji: '📊',
          title: 'Manches en moyenne',
          value: '',
          subtitle: [
            for (final entry in stats.averageRoundsByTarget.entries)
              '${entry.key} pts : ${entry.value.toStringAsFixed(1)} manches',
          ].join('\n'),
        ),
      if (stats.biggestHit != null)
        _FactCard(
          emoji: '💥',
          title: 'Plus gros carton',
          value: '+${stats.biggestHit!.value}',
          subtitle: stats.biggestHit!.name,
        ),
      if (stats.topWinner != null)
        _FactCard(
          emoji: '👑',
          title: 'Le plus titré',
          value: stats.topWinner!.name,
          subtitle: '${stats.topWinner!.value} victoire'
              '${stats.topWinner!.value > 1 ? 's' : ''}',
        ),
      if (stats.longestGameRounds != null)
        _FactCard(
          emoji: '🐢',
          title: 'Partie la plus longue',
          value: '${stats.longestGameRounds} manches',
          subtitle: '${stats.longestGameTarget} pts',
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: cards,
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return 'moins d\'une minute';
    if (d.inHours < 1) return '${d.inMinutes} min';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
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
