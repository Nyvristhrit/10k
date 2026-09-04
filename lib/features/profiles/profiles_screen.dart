import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/models/alias_profile.dart';
import '../../domain/services/game_stats.dart';
import '../../shared/widgets/app_background.dart';

/// Écran « Alias & profils » (§ évolution « alias joueur ») : bilan par
/// personne (victoires) plutôt que par totem tiré au hasard, avec couleur
/// perso et renommage — répercuté sur tout l'historique des parties.
class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(aliasProfilesProvider);
    final gamesAsync = ref.watch(finishedGamesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Alias & profils')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _CreateAliasDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel alias'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: profiles.isEmpty
              ? const _EmptyHint()
              : gamesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur : $e')),
                  data: (games) {
                    final stats = GameStats.of(games);
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        for (final profile in profiles)
                          _ProfileCard(
                            profile: profile,
                            wins: stats.winsByIdentity[profile.alias] ?? 0,
                          ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          '👤\n\nAucun alias pour l\'instant.\nCrée-en un avec le bouton '
          'ci-dessous.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile, required this.wins});

  final AliasProfile profile;
  final int wins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(profile.colorArgb);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openEditor(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: color, child: Icon(Icons.person, color: onColor)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.alias,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        wins == 0
                            ? 'Aucune victoire pour l\'instant'
                            : '$wins victoire${wins > 1 ? 's' : ''}',
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ProfileEditorDialog(profile: profile),
    );
  }
}

/// Renommer, changer de couleur, ou supprimer un profil. Le renommage est
/// répercuté sur toutes les parties déjà enregistrées (voir
/// `AliasProfilesController.rename`).
class _ProfileEditorDialog extends ConsumerStatefulWidget {
  const _ProfileEditorDialog({required this.profile});

  final AliasProfile profile;

  @override
  ConsumerState<_ProfileEditorDialog> createState() =>
      _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends ConsumerState<_ProfileEditorDialog> {
  late final _controller =
      TextEditingController(text: widget.profile.alias.replaceFirst('@', ''));
  late Color _color = Color(widget.profile.colorArgb);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final notifier = ref.read(aliasProfilesProvider.notifier);
    final newName = _controller.text.trim();
    if (newName.isNotEmpty) {
      await notifier.rename(widget.profile.alias, newName);
    }
    notifier.setColor(
        newName.isEmpty ? widget.profile.alias : '@$newName', _color);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Modifier le profil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 20,
              decoration:
                  const InputDecoration(prefixText: '@', counterText: ''),
            ),
            const SizedBox(height: 6),
            Text('Un renommage s\'applique à tout l\'historique des parties.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text('Couleur',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            _ColorSwatchPicker(
              selected: _color,
              onSelected: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(aliasProfilesProvider.notifier).remove(widget.profile.alias);
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: const Text('Supprimer'),
        ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }
}

/// Une ligne de pastilles de couleur à choisir (palette d'accent de
/// l'appli), avec une coche sur celle sélectionnée.
class _ColorSwatchPicker extends StatelessWidget {
  const _ColorSwatchPicker({required this.selected, required this.onSelected});

  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final seed in AppTheme.accentSeeds)
          GestureDetector(
            onTap: () => onSelected(seed),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: seed,
              child: selected.toARGB32() == seed.toARGB32()
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Création directe d'un alias depuis l'écran « Alias & profils » (bouton
/// « Nouvel alias »), sans passer par la préparation d'une partie.
class _CreateAliasDialog extends ConsumerStatefulWidget {
  const _CreateAliasDialog();

  @override
  ConsumerState<_CreateAliasDialog> createState() =>
      _CreateAliasDialogState();
}

class _CreateAliasDialogState extends ConsumerState<_CreateAliasDialog> {
  final _controller = TextEditingController();
  Color _color = AppTheme.accentSeeds.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _create() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final alias = '@$name';
    ref.read(aliasProfilesProvider.notifier)
      ..register(alias)
      ..setColor(alias, _color);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Nouvel alias'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(
                  prefixText: '@', hintText: 'alias', counterText: ''),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 16),
            Text('Couleur',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            _ColorSwatchPicker(
              selected: _color,
              onSelected: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        FilledButton(onPressed: _create, child: const Text('Créer')),
      ],
    );
  }
}
