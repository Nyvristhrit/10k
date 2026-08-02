import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/errors/game_rule_violation.dart';
import '../../domain/models/player.dart';
import '../../domain/services/game_transition.dart';
import '../../shared/trash/trash_taunts.dart';

/// Fait passer le tour d'un joueur, en gérant la confirmation du troisième
/// échec (§12.5). Utilisé par le plateau et par la modale de saisie.
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
    // On tire la pique une bonne fois pour toutes : elle ne doit pas changer à
    // chaque reconstruction de la pop-up.
    final title =
        trash ? Taunts.thirdMissTitle(name) : 'Troisième échec de $name';
    final body = trash
        ? Taunts.thirdMissBody(name, last?.amount)
        : (last == null
            ? 'Son dernier gain sera annulé.'
            : 'Son dernier gain de ${last.amount} points sera annulé.');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(trash ? Taunts.thirdMissCancel : 'Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                  trash ? Taunts.thirdMissAccept : 'Confirmer l\'échec')),
        ],
      ),
    );
    if (confirmed == true) {
      result = await controller.passTurn(player.id, confirmed: true);
    }
  }
}
