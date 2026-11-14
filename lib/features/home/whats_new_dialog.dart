import 'package:flutter/material.dart';

import '../../data/catalogs/whats_new_catalog.dart';
import '../../l10n/l10n.dart';

/// Popup « Quoi de neuf » après une mise à jour : les versions notables pas
/// encore vues, la plus récente en tête.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key, required this.releases});

  /// Du plus ancien au plus récent (affiché à l'envers).
  final List<WhatsNewRelease> releases;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ordered = releases.reversed.toList();

    return AlertDialog(
      icon: const Text('🎉', style: TextStyle(fontSize: 36)),
      title: Text(tr('Quoi de neuf', 'What\'s new')),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final release in ordered) ...[
                Text('v${release.version}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        fontSize: 15)),
                const SizedBox(height: 6),
                for (final item in release.localizedItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
                if (release != ordered.last) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Super !', 'Great!')),
        ),
      ],
    );
  }
}
