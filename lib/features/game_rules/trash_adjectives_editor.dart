import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/trash_adjectives_controller.dart';
import '../../application/providers/app_providers.dart';

/// Section des réglages où la table gère **toute** la liste des épithètes
/// du mode trash (v1.6.1, voir DECISIONS F-006) : retirer celles qui ne lui
/// plaisent pas, ajouter les siennes (blagues, références perso), ou revenir
/// à la liste par défaut. Visible seulement quand le mode trash est actif —
/// pas verrouillée par la partie en cours : c'est un réglage général, pas une
/// règle du jeu.
class TrashAdjectivesSection extends ConsumerStatefulWidget {
  const TrashAdjectivesSection({super.key});

  @override
  ConsumerState<TrashAdjectivesSection> createState() =>
      _TrashAdjectivesSectionState();
}

class _TrashAdjectivesSectionState
    extends ConsumerState<TrashAdjectivesSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    if (_atLimit) return;
    ref.read(trashAdjectivesProvider.notifier).add(_controller.text);
    _controller.clear();
  }

  bool get _atLimit => ref.read(trashAdjectivesProvider).length >=
      TrashAdjectivesController.maxCount;

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revenir à la liste d\'origine ?'),
        content: const Text(
            'Les épithètes que tu as ajoutées seront effacées, et celles que '
            'tu avais retirées reviendront.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Rétablir')),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(trashAdjectivesProvider.notifier).resetToDefaults();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final adjectives = ref.watch(trashAdjectivesProvider);
    final atLimit = adjectives.length >= TrashAdjectivesController.maxCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              'MODE TRASH — SURNOMS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: scheme.primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: scheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Les épithètes accolées à l\'animal quand un nom est tiré '
                  'en mode trash. Retire celles qui ne te plaisent pas '
                  '(croix), ajoute les tiennes : la liste reste sur ce '
                  'téléphone.',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: 24,
                        enabled: !atLimit,
                        decoration: InputDecoration(
                          hintText: atLimit
                              ? '${TrashAdjectivesController.maxCount} '
                                  'épithètes, le maximum'
                              : 'Écris une épithète ici',
                          counterText: '',
                          isDense: true,
                          filled: true,
                          fillColor: scheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: scheme.outline.withValues(alpha: 0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: scheme.outline.withValues(alpha: 0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: scheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: atLimit ? null : _add,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${adjectives.length} / ${TrashAdjectivesController.maxCount}',
                  style: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (adjectives.isEmpty)
                  Text(
                    'Liste vide : les noms tirés se limiteront à l\'animal.',
                    style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final adjective in adjectives)
                        InputChip(
                          label: Text(adjective),
                          onDeleted: () => ref
                              .read(trashAdjectivesProvider.notifier)
                              .remove(adjective),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _confirmReset,
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Rétablir la liste d\'origine'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
