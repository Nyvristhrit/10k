import 'package:flutter/material.dart';

import '../../data/catalogs/whats_new_catalog.dart';

/// Popup « Quoi de neuf » montrée une fois à l'ouverture de l'appli après une
/// mise à jour, listant les versions notables ratées depuis la dernière
/// ouverture (la plus récente en tête). Purement informatif : un seul bouton
/// pour fermer.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key, required this.releases});

  /// Du plus ancien au plus récent (voir `WhatsNewCatalog.since`) — affiché
  /// à l'envers, la nouveauté la plus récente en premier.
  final List<WhatsNewRelease> releases;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ordered = releases.reversed.toList();

    return AlertDialog(
      icon: const Text('🎉', style: TextStyle(fontSize: 36)),
      title: const Text('Quoi de neuf'),
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
                for (final item in release.items)
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
          child: const Text('Super !'),
        ),
      ],
    );
  }
}
