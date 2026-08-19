import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../data/catalogs/adjective_catalog.dart';

/// Section des réglages qui laisse la table ajouter ses propres épithètes
/// trash (blagues, références perso), piochées en plus du catalogue de base
/// quand un nom par défaut est tiré en mode trash. Visible seulement quand le
/// mode trash est actif — pas verrouillée par la partie en cours : c'est un
/// réglage général, pas une règle du jeu.
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
    ref.read(customTrashAdjectivesProvider.notifier).add(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final custom = ref.watch(customTrashAdjectivesProvider);

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
                  'Ajoute tes propres épithètes (blagues, private jokes…). '
                  'Elles s\'ajoutent aux ${AdjectiveCatalog.trash.length} '
                  'épithètes de base, piochées au hasard à la création d\'un '
                  'joueur sans nom personnalisé.',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: 24,
                        decoration: const InputDecoration(
                          hintText: 'Nouvelle épithète',
                          counterText: '',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _add,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (custom.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final adjective in custom)
                        InputChip(
                          label: Text(adjective),
                          onDeleted: () => ref
                              .read(customTrashAdjectivesProvider.notifier)
                              .remove(adjective),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
