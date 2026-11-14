import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_rules.dart';
import '../../domain/models/game_state.dart';
import '../../shared/widgets/app_background.dart';

import 'trash_adjectives_editor.dart';
import '../../l10n/l10n.dart';

/// Paramètres de la partie, modifiables seulement avant le démarrage.
/// Chaque changement est enregistré immédiatement.
class GameSettingsScreen extends ConsumerWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(tr('Paramètres de la partie', 'Game settings'))),
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
          title: tr('Objectif', 'Target'),
          children: [
            _ChoiceTile<int>(
              label: tr('Score à atteindre', 'Score to reach'),
              value: rules.targetScore,
              options: {
                5000: tr('5 000', '5,000'),
                10000: tr('10 000', '10,000'),
                15000: tr('15 000', '15,000'),
              },
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(targetScore: v)),
            ),
            _SwitchTile(
              label: tr('Tomber pile', 'Land exactly'),
              subtitle:
                  tr('Il faut atteindre le score exact. Le dépasser compte comme un raté.', 'You must hit the exact score. Going past it counts as a miss.'),
              value: rules.exactTargetRequired,
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(exactTargetRequired: v)),
            ),
          ],
        ),
        _Section(
          title: tr('Saisie des scores', 'Score entry'),
          children: [
            _ChoiceTile<int>(
              label: tr('Pas de saisie', 'Entry step'),
              subtitle: tr('Par tranches de combien on ajoute les points.', 'The increment used to add points.'),
              value: rules.scoreStep,
              options: const {50: '50', 100: '100'},
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(scoreStep: v)),
            ),
            _ChoiceTile<int>(
              label: tr('Minimum pour sortir', 'Minimum to get in'),
              subtitle: tr('Score minimum du tout premier tour réussi.', 'Minimum score of the very first successful turn.'),
              value: rules.minimumEntryScore,
              options: {
                0: tr('Aucun', 'None'),
                300: '300',
                500: '500',
                1000: tr('1 000', '1,000'),
              },
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(minimumEntryScore: v)),
            ),
          ],
        ),
        _Section(
          title: tr('Déroulé des tours', 'Turn order'),
          children: [
            _ChoiceTile<TurnMode>(
              label: tr('Mode de jeu', 'Game mode'),
              subtitle: rules.turnMode == TurnMode.guided
                  ? tr("L'appli désigne qui joue, chacun son tour.",
                      'The app picks who plays, one after the other.')
                  : tr('Tu choisis librement quel joueur marque.',
                      'You freely choose which player scores.'),
              value: rules.turnMode,
              options: {
                TurnMode.guided: tr('Guidé', 'Guided'),
                TurnMode.free: tr('Libre', 'Free'),
              },
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(turnMode: v)),
            ),
          ],
        ),
        _Section(
          title: tr('Vies', 'Lives'),
          children: [
            _ChoiceTile<int>(
              label: tr('Nombre de cœurs', 'Number of hearts'),
              value: rules.maxLives,
              options: const {1: '1', 2: '2', 3: '3', 4: '4', 5: '5'},
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(maxLives: v)),
            ),
            _SwitchTile(
              label: tr('Confirmer au 3ᵉ échec', 'Confirm on 3rd miss'),
              subtitle:
                  tr('Demander une confirmation avant d\'annuler le dernier gain.', 'Ask for confirmation before cancelling the last gain.'),
              value: rules.confirmThirdMiss,
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(confirmThirdMiss: v)),
            ),
          ],
        ),
        _Section(
          title: tr('Règles spéciales', 'Special rules'),
          children: [
            _SwitchTile(
              label: tr('Rencontre', 'Encounter'),
              subtitle:
                  tr('Si un joueur atteint le score exact d\'un autre, il le renvoie.', 'If a player lands on another\'s exact score, they knock them back.'),
              value: rules.encounterEnabled,
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(encounterEnabled: v)),
            ),
            _SwitchTile(
              label: tr('Alerte de rencontre', 'Encounter alert'),
              subtitle:
                  tr(
                      'Afficher un message à valider quand une rencontre se produit, '
                          'pour ne pas la manquer.',
                      'Show a message to confirm when an encounter happens, '
                          'so you don\'t miss it.'),
              value: rules.encounterAlertsEnabled,
              enabled: !locked && rules.encounterEnabled,
              onChanged: (v) =>
                  update(rules.copyWith(encounterAlertsEnabled: v)),
            ),
            _SwitchTile(
              label: tr('Dernière chance', 'Last chance'),
              subtitle:
                  tr('Quand un joueur gagne, les autres ont un dernier tour pour le rattraper.', 'When a player wins, the others get one last turn to catch up.'),
              value: rules.finalChanceEnabled,
              enabled: !locked,
              onChanged: (v) => update(rules.copyWith(finalChanceEnabled: v)),
            ),
          ],
        ),
        _Section(
          title: tr('Écran', 'Screen'),
          children: [
            _SwitchTile(
              label: tr('Garder l\'écran allumé', 'Keep the screen on'),
              subtitle:
                  tr(
                      'Actif seulement pendant la partie (pas au menu). '
                          'Désactive-le pour économiser la batterie.',
                      'Only during the game (not in the menus). '
                          'Turn it off to save battery.'),
              value: ref.watch(keepScreenOnEnabledProvider),
              onChanged: (v) =>
                  ref.read(keepScreenOnEnabledProvider.notifier).set(v),
            ),
          ],
        ),
        _Section(
          title: tr('Dés', 'Dice'),
          children: [
            _SwitchTile(
              label: tr('Dés dans l\'appli', 'In-app dice'),
              subtitle:
                  tr(
                      'Icône 🎲 sur le plateau pour lancer les dés directement '
                          'dans l\'appli. À désactiver si tu joues avec de vrais dés.',
                      '🎲 icon on the board to roll dice right in the app. '
                          'Turn it off if you play with real dice.'),
              value: ref.watch(diceTrayEnabledProvider),
              onChanged: (v) =>
                  ref.read(diceTrayEnabledProvider.notifier).set(v),
            ),
          ],
        ),
        if (ref.watch(trashModeProvider)) ...[
          _Section(
            title: tr('Le bon dernier 💩', 'The dead last 💩'),
            children: [
              _SwitchTile(
                label: tr('Prouts du bon dernier', 'Dead-last farts'),
                subtitle:
                    tr(
                        'Le bon dernier (le 💩) lâche un prout à chaque bouton '
                            'qu\'il touche en saisissant son score.',
                        'The dead last (the 💩) lets one rip on every button '
                            'they press while entering their score.'),
                value: ref.watch(cradoSettingsProvider).farts,
                onChanged: (v) =>
                    ref.read(cradoSettingsProvider.notifier).setFarts(v),
              ),
              _SwitchTile(
                label: tr('Taches du bon dernier', 'Dead-last stains'),
                subtitle:
                    tr(
                        'Chaque bouton touché lui fait une tache de plus sur sa '
                            'tuile. Le prochain bon dernier récupère toute la saleté.',
                        'Every button pressed adds one more stain to their '
                            'tile. The next dead last inherits all the filth.'),
                value: ref.watch(cradoSettingsProvider).stains,
                onChanged: (v) =>
                    ref.read(cradoSettingsProvider.notifier).setStains(v),
              ),
            ],
          ),
          const TrashAdjectivesSection(),
        ],
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
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFFFCD34D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('La partie a commencé : les règles ne sont plus modifiables.', 'The game has started: the rules can no longer be changed.'),
              style: const TextStyle(color: Color(0xFFFCD34D)),
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
