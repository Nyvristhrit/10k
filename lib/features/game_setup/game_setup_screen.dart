import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/game_engine.dart';
import '../../domain/services/game_transition.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/player_visuals.dart';
import '../game_board/game_board_screen.dart';
import '../game_rules/game_settings_screen.dart';

/// Écran de préparation d'une partie (§20.2).
class GameSetupScreen extends ConsumerWidget {
  const GameSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gameControllerProvider);
    final game = async.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Préparation'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.16),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.tune, size: 20),
              label: const Text('Réglages',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameSettingsScreen()),
              ),
            ),
          ),
        ],
      ),
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
    final players = game.players;
    final canAdd = players.length < kMaxPlayers;
    final canStart = players.length >= 2;

    return Column(
      children: [
        Expanded(
          child: players.isEmpty
              ? _emptyHint(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: players.length,
                  itemBuilder: (_, i) =>
                      _playerRow(context, ref, players[i]),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                ),
        ),
        _footer(context, ref, canAdd: canAdd, canStart: canStart, count: players.length),
      ],
    );
  }

  Widget _emptyHint(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Ajoute au moins deux joueurs pour commencer.\nChacun reçoit un animal et une couleur au hasard.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );

  Widget _playerRow(BuildContext context, WidgetRef ref, Player player) {
    final color = colorFor(player, trash: TenkSkin.of(context).trash);
    final bg = AppTheme.fromArgb(color.backgroundArgb);
    final fg = AppTheme.fromArgb(color.foregroundArgb);
    // La couleur perso du profil (choisie dans l'écran « Alias & profils »)
    // teinte le bouton alias — sinon un simple survol clair du fond.
    Color? profileColor;
    if (player.alias != null) {
      final matches = ref
          .watch(aliasProfilesProvider)
          .where((p) => p.alias == player.alias);
      if (matches.isNotEmpty) profileColor = Color(matches.first.colorArgb);
    }
    final pillColor = profileColor ?? Colors.white.withValues(alpha: 0.22);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(emojiFor(player), style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.displayName,
                  style: TextStyle(
                      color: fg, fontSize: 20, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Le bouton alias : un peu plus clair que la carte par
                // défaut, ou dans la couleur perso choisie pour ce profil.
                GestureDetector(
                  onTap: () => _editAlias(context, ref, player),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      player.alias ?? '+ @alias',
                      style: TextStyle(
                          color: profileColor == null
                              ? fg.withValues(alpha: 0.8)
                              : (ThemeData.estimateBrightnessForColor(
                                          profileColor) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: fg),
            tooltip: 'Renommer',
            onPressed: () => _rename(context, ref, player),
          ),
          IconButton(
            icon: Icon(Icons.close, color: fg),
            tooltip: 'Retirer',
            onPressed: () =>
                ref.read(gameControllerProvider.notifier).removePlayer(player.id),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, WidgetRef ref,
      {required bool canAdd, required bool canStart, required int count}) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              style:
                  OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: canAdd
                  ? () => _add(context, ref)
                  : null,
              icon: const Icon(Icons.add),
              label: Text(canAdd
                  ? 'Ajouter un joueur ($count/12)'
                  : 'Maximum de 12 joueurs atteint'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: canStart ? () => _start(context, ref) : null,
              child: Text(canStart
                  ? 'Commencer la partie'
                  : 'Au moins 2 joueurs requis'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(gameControllerProvider.notifier).addPlayer();
    if (result is Failure && context.mounted) {
      _snack(context, 'Impossible d\'ajouter un joueur.');
    }
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final result = await ref.read(gameControllerProvider.notifier).startGame();
    if (result is Success) {
      navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const GameBoardScreen()));
    } else if (context.mounted) {
      _snack(context, 'Impossible de démarrer la partie.');
    }
  }

  Future<void> _rename(
      BuildContext context, WidgetRef ref, Player player) async {
    final controller = TextEditingController(text: player.displayName);
    try {
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Renommer'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 28,
            decoration: const InputDecoration(hintText: 'Nom du joueur'),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('Valider')),
          ],
        ),
      );
      if (newName != null && newName.trim().isNotEmpty) {
        await ref
            .read(gameControllerProvider.notifier)
            .renamePlayer(player.id, newName.trim());
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _editAlias(
      BuildContext context, WidgetRef ref, Player player) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _AliasDialog(currentAlias: player.alias),
    );
    if (result == null) return; // annulé
    final notifier = ref.read(gameControllerProvider.notifier);
    if (result.isEmpty) {
      await notifier.setPlayerAlias(player.id, null);
      return;
    }
    final normalized = result.startsWith('@') ? result : '@$result';
    await notifier.setPlayerAlias(player.id, normalized);
    ref.read(aliasProfilesProvider.notifier).register(normalized);
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Boîte de dialogue de l'alias : saisie d'un nouvel alias, ou choix parmi
/// tous ceux déjà utilisés sur l'appareil (§ évolution « alias joueur »).
class _AliasDialog extends ConsumerStatefulWidget {
  const _AliasDialog({this.currentAlias});

  final String? currentAlias;

  @override
  ConsumerState<_AliasDialog> createState() => _AliasDialogState();
}

class _AliasDialogState extends ConsumerState<_AliasDialog> {
  late final _controller = TextEditingController(
      text: (widget.currentAlias ?? '').replaceFirst('@', ''));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profiles = ref.watch(aliasProfilesProvider);

    return AlertDialog(
      title: const Text('Alias du joueur'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reste le même d\'une partie à l\'autre — utilisé pour les stats.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(
                  prefixText: '@', hintText: 'alias', counterText: ''),
              onSubmitted: (_) => _submit(),
            ),
            if (profiles.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Alias déjà utilisés',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final profile in profiles)
                    InputChip(
                      backgroundColor:
                          Color(profile.colorArgb).withValues(alpha: 0.22),
                      side: BorderSide(color: Color(profile.colorArgb)),
                      label: Text(profile.alias),
                      onPressed: () => Navigator.pop(context, profile.alias),
                      onDeleted: () => ref
                          .read(aliasProfilesProvider.notifier)
                          .remove(profile.alias),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.currentAlias != null)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Retirer'),
          ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: const Text('Valider')),
      ],
    );
  }
}
