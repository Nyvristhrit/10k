import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_rules.dart';
import '../../domain/models/game_state.dart';
import '../../shared/widgets/app_background.dart';

import 'trash_adjectives_editor.dart';

/// Écran des paramètres de la partie (§21).
///
/// Les réglages ne sont modifiables qu'avant le démarrage (en préparation).
/// Chaque changement est enregistré immédiatement via `updateRules`.
class GameSettingsScreen extends ConsumerWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Paramètres de la partie')),
      body: AppBackground(
        child: SafeArea(
          child: game == null
              ? const Center(child: CircularProgressIndicator())
              : _body(context, ref, game),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, GameState game) {
    final rules = game.rules;
    final locked = game.status != GameStatus.setup;

    void update(GameRules next) {
      ref.read(gameControllerProvider.notifier).updateRules(next);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (locked)
          const _LockedBanner(),
        _Section(
          title: 'Objectif',
          children: [
            _ChoiceTile<int>(
              label: 'Score à atteindre',
              value: rules.targetScore,
              options: const {5000: '5 000', 10000: '10 000', 15000: '15 000'},
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(targetScore: v)),
            ),
            _SwitchTile(
              label: 'Tomber pile',
              subtitle:
                  'Il faut atteindre le score exact. Le dépasser compte comme un raté.',
              value: rules.exactTargetRequired,
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(exactTargetRequired: v)),
            ),
          ],
        ),
        _Section(
          title: 'Saisie des scores',
          children: [
            _ChoiceTile<int>(
              label: 'Pas de saisie',
              subtitle: 'Par tranches de combien on ajoute les points.',
              value: rules.scoreStep,
              options: const {50: '50', 100: '100'},
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(scoreStep: v)),
            ),
            _ChoiceTile<int>(
              label: 'Minimum pour sortir',
              subtitle: 'Score minimum du tout premier tour réussi.',
              value: rules.minimumEntryScore,
              options: const {
                0: 'Aucun',
                300: '300',
                500: '500',
                1000: '1 000',
              },
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(minimumEntryScore: v)),
            ),
          ],
        ),
        _Section(
          title: 'Déroulé des tours',
          children: [
            _ChoiceTile<TurnMode>(
              label: 'Mode de jeu',
              subtitle: rules.turnMode == TurnMode.guided
                  ? "L'appli désigne qui joue, chacun son tour."
                  : 'Tu choisis librement quel joueur marque.',
              value: rules.turnMode,
              options: const {
                TurnMode.guided: 'Guidé',
                TurnMode.free: 'Libre',
              },
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(turnMode: v)),
            ),
          ],
        ),
        _Section(
          title: 'Vies',
          children: [
            _ChoiceTile<int>(
              label: 'Nombre de cœurs',
              value: rules.maxLives,
              options: const {1: '1', 2: '2', 3: '3', 4: '4', 5: '5'},
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(maxLives: v)),
            ),
            _SwitchTile(
              label: 'Confirmer au 3ᵉ échec',
              subtitle:
                  'Demander une confirmation avant d\'annuler le dernier gain.',
              value: rules.confirmThirdMiss,
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(confirmThirdMiss: v)),
            ),
          ],
        ),
        _Section(
          title: 'Règles spéciales',
          children: [
            _SwitchTile(
              label: 'Rencontre',
              subtitle:
                  'Si un joueur atteint le score exact d\'un autre, il le renvoie.',
              value: rules.encounterEnabled,
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(encounterEnabled: v)),
            ),
            _SwitchTile(
              label: 'Alerte de rencontre',
              subtitle:
                  'Afficher un message à valider quand une rencontre se produit, '
                  'pour ne pas la manquer.',
              value: rules.encounterAlertsEnabled,
              enabled: !locked && rules.encounterEnabled,
              onChanged: (v) =>
                  update(rules.copyWith(encounterAlertsEnabled: v)),
            ),
            _SwitchTile(
              label: 'Dernière chance',
              subtitle:
                  'Quand un joueur gagne, les autres ont un dernier tour pour le rattraper.',
              value: rules.finalChanceEnabled,
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(finalChanceEnabled: v)),
            ),
          ],
        ),
        _Section(
          title: 'Écran',
          children: [
            _SwitchTile(
              label: 'Garder l\'écran allumé',
              subtitle:
                  'Actif seulement pendant la partie (pas au menu). '
                  'Désactive-le pour économiser la batterie.',
              value: ref.watch(keepScreenOnEnabledProvider),
              onChanged: (v) =>
                  ref.read(keepScreenOnEnabledProvider.notifier).set(v),
            ),
          ],
        ),
        _Section(
          title: 'Dés',
          children: [
            _SwitchTile(
              label: 'Dés dans l\'appli',
              subtitle:
                  'Icône 🎲 sur le plateau pour lancer les dés directement '
                  'dans l\'appli. À désactiver si tu joues avec de vrais dés.',
              value: ref.watch(diceTrayEnabledProvider),
              onChanged: (v) =>
                  ref.read(diceTrayEnabledProvider.notifier).set(v),
            ),
          ],
        ),
        if (ref.watch(trashModeProvider)) const TrashAdjectivesSection(),
      ],
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7A5A22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFFFCD34D)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'La partie a commencé : les règles ne sont plus modifiables.',
              style: TextStyle(color: Color(0xFFFCD34D)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// Un réglage à choix multiple présenté sous forme de boutons segmentés.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String label;
  final String? subtitle;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [
                for (final entry in options.entries)
                  ButtonSegment<T>(
                      value: entry.key, label: Text(entry.value)),
              ],
              selected: {value},
              onSelectionChanged:
                  enabled ? (s) => onChanged(s.first) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un réglage oui/non.
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13)),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}
