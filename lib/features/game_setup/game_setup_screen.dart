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
            child: Text(
              player.displayName,
              style: TextStyle(
                  color: fg, fontSize: 20, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
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

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
