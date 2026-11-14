import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/errors/game_rule_violation.dart';
import '../../domain/models/player.dart';
import '../../domain/services/game_transition.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../l10n/l10n.dart';

/// Fait passer le tour d'un joueur, avec confirmation du troisième échec.
Future<void> handlePass(
    BuildContext context, WidgetRef ref, Player player) async {
  final controller = ref.read(gameControllerProvider.notifier);
  var result = await controller.passTurn(player.id);

  if (result is Failure &&
      result.violation.code ==
          GameRuleViolationCode.confirmationRequiredForThirdMiss) {
    if (!context.mounted) return;
    final last = player.lastActiveGain;
    final trash = TenkSkin.of(context).trash;
    final name = player.displayName;
    // Pique tirée une seule fois, pour ne pas changer à chaque rebuild.
    final title =
        trash ? Taunts.thirdMissTitle(name) : tr('Troisième échec de $name', '$name\'s third miss');
    final body = trash
        ? Taunts.thirdMissBody(name, last?.amount)
        : (last == null
            ? tr('Son dernier gain sera annulé.', 'Their last gain will be cancelled.')
            : tr('Son dernier gain de ${last.amount} points sera annulé.', 'Their last gain of ${last.amount} points will be cancelled.'));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(trash ? Taunts.thirdMissCancel : tr('Annuler', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                  trash ? Taunts.thirdMissAccept : tr('Confirmer l\'échec', 'Confirm the miss'))),
        ],
      ),
    );
    if (confirmed == true) {
      result = await controller.passTurn(player.id, confirmed: true);
    }
  }
}
