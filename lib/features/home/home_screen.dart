import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../data/catalogs/whats_new_catalog.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_state.dart';
import '../../l10n/l10n.dart';
import '../../shared/animations/entrance.dart';
import '../../shared/animations/falling_dice.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../shared/widgets/app_background.dart';
import '../game_board/game_board_screen.dart';
import '../game_result/game_result_screen.dart';
import '../game_setup/game_setup_screen.dart';
import '../info/info_screen.dart';
import '../profiles/profiles_screen.dart';
import '../stats/stats_screen.dart';
import 'whats_new_dialog.dart';

/// Écran d'accueil.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Après le premier rendu, pour ouvrir le dialogue sur un contexte prêt.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWhatsNew());
  }

  /// Montre « Quoi de neuf » une fois par version notable, jamais au premier
  /// lancement.
  Future<void> _maybeShowWhatsNew() async {
    if (!mounted) return;
    final repo = ref.read(settingsRepositoryProvider);
    final latest = WhatsNewCatalog.releases.last;
    final lastSeen = repo.loadLastSeenWhatsNewVersion();
    if (lastSeen == latest.version) return;

    // Aucun réglage enregistré : premier lancement, on mémorise juste la version.
    final firstEverLaunch = lastSeen == null && !repo.hasAnySettings();

    final unseen = firstEverLaunch
        ? const <WhatsNewRelease>[]
        : lastSeen == null
            // Utilisateur existant sans version vue enregistrée : on montre
            // tout l'historique notable, pas seulement la dernière version.
            ? WhatsNewCatalog.releases
            : WhatsNewCatalog.since(lastSeen);

    repo.saveLastSeenWhatsNewVersion(latest.version);
    if (unseen.isEmpty || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => WhatsNewDialog(releases: unseen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(gameControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final skin = TenkSkin.of(context);

    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            Positioned.fill(child: FallingDice(emojis: skin.fallingEmojis)),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: skin.trash ? 4 : 7, sigmaY: skin.trash ? 4 : 7),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: (dark ? Colors.black : Colors.white)
                        .withValues(alpha: dark ? 0.14 : 0.32),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(tr('Erreur : $e', 'Error: $e'))),
                  data: (game) => _content(context, ref, game),
                ),
              ),
            ),
            // Bascules jour/nuit et langue : chaque bouton montre l'état vers
            // lequel on passe (soleil la nuit, « EN » en français).
            Positioned(
              top: 0,
              left: 4,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
                      iconSize: 28,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                      tooltip: dark
                          ? tr('Passer en mode jour', 'Switch to day mode')
                          : tr('Passer en mode nuit', 'Switch to night mode'),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                    ),
                    const _LanguageButton(),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 4,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people_alt_outlined),
                      iconSize: 27,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      tooltip: tr('Alias & profils', 'Aliases & profiles'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilesScreen()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      iconSize: 30,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      tooltip: tr('Aide & règles du jeu', 'Help & game rules'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InfoScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, GameState? game) {
    final theme = Theme.of(context);
    final skin = TenkSkin.of(context);
    final hasActive = game != null;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final dice = Entrance(
        delay: const Duration(milliseconds: 80),
        child: _BobbingDice(emoji: skin.trash ? '💀' : '🎲'));

    final title = Entrance(
      delay: const Duration(milliseconds: 220),
      // Le logo suit la largeur de l'écran ; en paysage on le borne à une
      // largeur fixe pour qu'il ne déborde pas.
      child: landscape
          ? const SizedBox(width: 260, child: _LogoStack())
          : FractionallySizedBox(widthFactor: 0.585, child: const _LogoStack()),
    );

    final tagline = Entrance(
      delay: const Duration(milliseconds: 340),
      child: Text(
          skin.trash
              ? Taunts.tagline
              : tr('Compagnon de jeu du 10 000', 'Your 10,000 dice game companion'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );

    final newGameButton = Entrance(
      delay: const Duration(milliseconds: 460),
      child: FilledButton(
        onPressed: () => _onNewGame(context, ref, hasActive),
        child: Text(tr('Nouvelle partie', 'New game')),
      ),
    );

    final resumeButton = !hasActive
        ? null
        : Entrance(
            delay: const Duration(milliseconds: 560),
            child: OutlinedButton(
              style:
                  OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: () => _openGame(context, game),
              child: Text(_isOver(game.status)
                  ? tr('Voir le résultat', 'See the results')
                  : tr('Reprendre la partie', 'Resume game')),
            ),
          );

    final statsButton = Entrance(
      delay: const Duration(milliseconds: 640),
      child: TextButton.icon(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
        icon: const Icon(Icons.emoji_events_outlined, size: 18),
        label: Text(tr('Stats & records', 'Stats & records')),
      ),
    );

    if (landscape) {
      // Écran large et court : blocs côte à côte pour éviter le débordement.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [dice, const SizedBox(height: 10), title],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                tagline,
                const SizedBox(height: 24),
                newGameButton,
                if (resumeButton != null) ...[
                  const SizedBox(height: 14),
                  resumeButton,
                ],
                const SizedBox(height: 8),
                statsButton,
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Spacer(flex: 2),
        dice,
        const SizedBox(height: 12),
        title,
        const SizedBox(height: 8),
        tagline,
        const Spacer(flex: 3),
        newGameButton,
        if (resumeButton != null) ...[
          const SizedBox(height: 14),
          resumeButton,
        ],
        const SizedBox(height: 8),
        statsButton,
        const Spacer(flex: 2),
      ],
    );
  }

  Future<void> _onNewGame(
      BuildContext context, WidgetRef ref, bool hasActive) async {
    HapticFeedback.mediumImpact();
    final navigator = Navigator.of(context);
    if (hasActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Remplacer la partie en cours ?',
              'Replace the current game?')),
          content: Text(tr(
              'Une partie est déjà en cours. En créer une nouvelle l\'effacera.',
              'A game is already in progress. Starting a new one will erase it.')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('Annuler', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('Remplacer', 'Replace'))),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(gameControllerProvider.notifier).newGame();
    navigator.push(
        MaterialPageRoute(builder: (_) => const GameSetupScreen()));
  }

  /// Une partie déjà jouée jusqu'au bout (gagnant désigné, ou archivée).
  bool _isOver(GameStatus status) =>
      status == GameStatus.finished || status == GameStatus.archived;

  void _openGame(BuildContext context, GameState game) {
    HapticFeedback.selectionClick();
    final Widget target;
    if (game.status == GameStatus.setup) {
      target = const GameSetupScreen();
    } else if (_isOver(game.status)) {
      // Partie terminée : on ouvre le classement plutôt que le plateau figé.
      target = const GameResultScreen();
    } else {
      target = const GameBoardScreen();
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => target));
  }
}

/// Stries du logo « 10K » à partir des 6 couleurs de l'habillage.
///
/// Chaque couleur est doublée pour obtenir des tranches nettes plutôt qu'un
/// dégradé.
Shader _stripeShader(List<Color> stripes) {
  const stops = <double>[
    0.0, 0.2059, // 1ʳᵉ couleur (élargie)
    0.2059, 0.3529,
    0.3529, 0.5,
    0.5, 0.6471,
    0.6471, 0.7941,
    0.7941, 1.0, // dernière couleur (élargie)
  ];
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      for (final c in stripes) ...[c, c]
    ],
    stops: stops,
  ).createShader(const Rect.fromLTWH(0, 0, 240, 120));
}

/// Le logo « 10K » (et le badge trash), dimensionné par son parent.
class _LogoStack extends StatelessWidget {
  const _LogoStack();

  @override
  Widget build(BuildContext context) {
    final skin = TenkSkin.of(context);
    // `passthrough` transmet la largeur du parent au `FittedBox` ; sans lui,
    // le logo prend sa taille naturelle et rapetisse.
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        FittedBox(
          fit: BoxFit.fitWidth,
          // Dégradé peint dans les lettres (`foreground`) plutôt qu'avec un
          // ShaderMask : évite un liseré blanc en mode sombre.
          child: Text('10K',
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                height: 1.0,
                foreground: Paint()..shader = _stripeShader(skin.titleStripes),
              )),
        ),
        if (skin.trash)
          Positioned(
            right: -18,
            bottom: -10,
            child: Transform.rotate(angle: -0.16, child: const _TrashBadge()),
          ),
      ],
    );
  }
}

/// L'étiquette « TRASH », posée en travers du logo comme un autocollant.
///
/// Fond très sombre pour que le rose ne se mélange pas au dégradé du logo.
class _TrashBadge extends StatelessWidget {
  const _TrashBadge();

  /// Prune presque noir : lisible sur le logo en ambiance jour comme nuit.
  static const Color _ink = Color(0xFF14001C);

  @override
  Widget build(BuildContext context) {
    final skin = TenkSkin.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: skin.neon, width: 2.5),
        boxShadow: [
          BoxShadow(
              color: skin.neon.withValues(alpha: 0.55),
              blurRadius: 20,
              spreadRadius: 1),
          const BoxShadow(
              color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        Taunts.badge,
        style: TextStyle(
          color: skin.neon,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 5,
          height: 1.15,
        ),
      ),
    );
  }
}

/// Bouton de langue : affiche la langue vers laquelle on bascule.
class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);
    return IconButton(
      tooltip: language == AppLanguage.fr
          ? 'Switch to English'
          : 'Passer en français',
      onPressed: () {
        HapticFeedback.selectionClick();
        ref.read(languageProvider.notifier).toggle();
      },
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          language == AppLanguage.fr ? 'EN' : 'FR',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

/// Le grand dé de l'accueil, qui flotte doucement.
class _BobbingDice extends StatefulWidget {
  const _BobbingDice({this.emoji = '🎲'});

  final String emoji;

  @override
  State<_BobbingDice> createState() => _BobbingDiceState();
}

class _BobbingDiceState extends State<_BobbingDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -10 + 20 * t),
          child: Transform.rotate(angle: (-0.06 + 0.12 * t), child: child),
        );
      },
      child: Text(widget.emoji, style: const TextStyle(fontSize: 82)),
    );
  }
}
