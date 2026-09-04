import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_state.dart';
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

/// Écran d'accueil (§20.1).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gameControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final skin = TenkSkin.of(context);

    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            Positioned.fill(child: FallingDice(emojis: skin.fallingEmojis)),
            // Voile flou : transforme les dés en silhouettes douces derrière.
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
                  error: (e, _) => Center(child: Text('Erreur : $e')),
                  data: (game) => _content(context, ref, game),
                ),
              ),
            ),
            // Bascule jour/nuit dans le coin haut-gauche : la nuit on voit un
            // soleil (pour passer au jour), le jour une lune (pour passer à la
            // nuit).
            Positioned(
              top: 0,
              left: 4,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
                  iconSize: 28,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                  tooltip: dark ? 'Passer en mode jour' : 'Passer en mode nuit',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                ),
              ),
            ),
            // Alias & profils, puis le petit « ? » : aide, règles et à propos.
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
                      tooltip: 'Alias & profils',
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
                      tooltip: 'Aide & règles du jeu',
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
      // Le logo est dimensionné par la LARGEUR disponible (`FittedBox` +
      // `widthFactor`), pour rester cohérent d'un téléphone à l'autre. En
      // paysage, la largeur de l'écran ne veut plus rien dire pour cet usage
      // (elle est démesurée par rapport à la hauteur, courte) : on borne alors
      // le logo à une largeur absolue plutôt qu'à une fraction de l'écran —
      // sinon le titre grossissait sans limite et faisait déborder la page
      // (c'est ce qui rendait l'accueil illisible en paysage avant que la
      // rotation ne soit simplement bloquée).
      child: landscape
          ? const SizedBox(width: 260, child: _LogoStack())
          : FractionallySizedBox(widthFactor: 0.585, child: const _LogoStack()),
    );

    final tagline = Entrance(
      delay: const Duration(milliseconds: 340),
      child: Text(skin.trash ? Taunts.tagline : 'Compagnon de jeu du 10 000',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );

    final newGameButton = Entrance(
      delay: const Duration(milliseconds: 460),
      child: FilledButton(
        onPressed: () => _onNewGame(context, ref, hasActive),
        child: const Text('Nouvelle partie'),
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
                  ? 'Voir le résultat'
                  : 'Reprendre la partie'),
            ),
          );

    final statsButton = Entrance(
      delay: const Duration(milliseconds: 640),
      child: TextButton.icon(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
        icon: const Icon(Icons.emoji_events_outlined, size: 18),
        label: const Text('Stats & records'),
      ),
    );

    if (landscape) {
      // Écran large et court : les deux blocs se partagent la largeur au lieu
      // de s'empiler, ce qui évite tout risque de débordement vertical.
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
          title: const Text('Remplacer la partie en cours ?'),
          content: const Text(
              'Une partie est déjà en cours. En créer une nouvelle l\'effacera.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remplacer')),
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
      // Partie terminée : on renvoie directement vers le classement, pas vers
      // le plateau (qui, la partie finie, serait figé et sans issue).
      target = const GameResultScreen();
    } else {
      target = const GameBoardScreen();
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => target));
  }
}

/// Peint les stries du logo « 10K » à partir des 6 couleurs de l'habillage.
///
/// Chaque couleur est doublée avec des bornes identiques pour obtenir des
/// tranches franches (et non un dégradé fondu). La première et la dernière sont
/// un peu plus larges, pour bien remplir la pointe du 1 et celle du K.
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

/// Le logo « 10K » (+ le badge trash s'il y a lieu), dimensionné par son
/// parent (une `FractionallySizedBox` en portrait, une largeur fixe en
/// paysage — voir `HomeScreen._content`).
class _LogoStack extends StatelessWidget {
  const _LogoStack();

  @override
  Widget build(BuildContext context) {
    final skin = TenkSkin.of(context);
    // Le badge « TRASH » se pose en travers du logo, comme un autocollant
    // collé après coup : on empile donc les deux, en laissant le badge
    // déborder légèrement du cadre (`Clip.none`).
    //
    // `passthrough` est essentiel : sans lui, la pile relâcherait les
    // contraintes et le `FittedBox` se contenterait de la taille naturelle du
    // texte — le logo rapetissait. Ici, la largeur imposée par le parent
    // traverse la pile telle quelle et le titre garde sa pleine taille.
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        FittedBox(
          fit: BoxFit.fitWidth,
          // On peint le dégradé DIRECTEMENT dans les lettres (via
          // `foreground`) plutôt qu'avec un ShaderMask par-dessus un texte
          // blanc : ainsi il n'y a plus de blanc dessous qui « perce » au
          // bout du 1 et du K en mode sombre. Les stries viennent de
          // l'habillage : arc-en-ciel d'origine, ou néon en mode trash.
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
/// Fond très sombre plutôt que teinté : le rose ressort alors franchement, au
/// lieu de se mélanger au dégradé du logo derrière (ce qui virait au vert
/// sale). La lueur reste **à l'extérieur** du badge, jamais dans le texte.
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
          // Une ombre portée franche décolle l'autocollant du logo.
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

/// Le grand dé de l'accueil, qui flotte doucement (montée/descente + légère
/// bascule) pour égayer la page.
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
