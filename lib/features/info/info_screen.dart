import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../l10n/l10n.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../shared/widgets/app_background.dart';

/// Règles du jeu, aide et « À propos ».
///
/// Sept tapes sur la carte de dédicace basculent le mode trash, comme les
/// options développeur d'Android.
class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  int _tab = 0;
  int _taps = 0;

  /// Version de l'APK installé, `null` tant qu'elle n'est pas chargée.
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    }).catchError((_) {
      // Pas de version disponible : on laisse la ligne vide.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(tr('Aide & règles', 'Help & rules'))),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: 0, label: Text(tr('Règles', 'Rules'))),
                      ButtonSegment(
                          value: 1, label: Text(tr('L\'appli', 'The app'))),
                      ButtonSegment(
                          value: 2, label: Text(tr('À propos', 'About'))),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (s) => setState(() {
                      _tab = s.first;
                      _taps = 0; // on repart de zéro en changeant d'onglet
                    }),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: switch (_tab) {
                    0 => _rules(context),
                    1 => _app(context),
                    _ => _about(context),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Onglet Règles ────────────────────────────────────────────────────────
  List<Widget> _rules(BuildContext context) => [
        _Intro(
          emoji: '🎲',
          text: tr(
              'But du jeu : être le premier à atteindre exactement 10 000 points. '
                  'Chacun lance les dés à son tour et l\'appli tient les scores.',
              'Goal: be the first to reach exactly 10,000 points. '
                  'Everyone rolls the dice in turn and the app keeps score.'),
        ),
        _Rule(
          emoji: '🚪',
          title: tr('Sortir', 'Getting in'),
          text: tr(
              'Au premier tour réussi, il faut marquer au moins 300 points pour '
                  '« sortir » et entrer dans la partie. (Ce minimum est réglable.)',
              'On your first successful turn, you need at least 300 points to '
                  '“get in” and join the game. (This minimum can be changed.)'),
        ),
        _Rule(
          emoji: '➕',
          title: tr('Marquer', 'Scoring'),
          text: tr(
              'À chaque tour réussi, on ajoute les points marqués. Ils s\'empilent '
                  'les uns sur les autres : c\'est la « pile de gains ».',
              'Each successful turn adds the points scored. They pile up on top '
                  'of each other: that\'s the “gain stack”.'),
        ),
        _Rule(
          emoji: '❤️',
          title: tr('Les 3 cœurs', 'The 3 hearts'),
          text: tr(
              'Chaque joueur a 3 cœurs. Un tour raté fait perdre un cœur. Au 3ᵉ '
                  'échec, le dernier gain de la pile est annulé… puis les 3 cœurs '
                  'reviennent. Un tour réussi restaure aussi les 3 cœurs d\'un coup.',
              'Each player has 3 hearts. A missed turn costs one heart. On the '
                  '3rd miss, the last gain on the stack is cancelled… then the 3 '
                  'hearts come back. A successful turn also restores all 3 hearts '
                  'at once.'),
        ),
        _Rule(
          emoji: '🤝',
          title: tr('La rencontre', 'The encounter'),
          text: tr(
              'Si en marquant tu tombes exactement sur le total d\'un adversaire, '
                  'c\'est une « rencontre » : ce dernier perd son dernier gain. '
                  'Malin pour freiner celui qui mène !',
              'If your score lands exactly on an opponent\'s total, it\'s an '
                  '“encounter”: they lose their last gain. '
                  'A smart way to slow down the leader!'),
        ),
        _Rule(
          emoji: '🎯',
          title: tr('Tomber pile', 'Land exactly'),
          text: tr(
              'Il faut atteindre 10 000 pile. Un score qui te ferait dépasser '
                  '10 000 est refusé et compte comme un tour raté.',
              'You must reach exactly 10,000. A score that would take you past '
                  '10,000 is refused and counts as a missed turn.'),
        ),
        _Rule(
          emoji: '⏳',
          title: tr('Dernière chance', 'Last chance'),
          text: tr(
              'Dès qu\'un joueur atteint 10 000, tous les autres ont droit à un '
                  'ultime tour pour tenter de le rejoindre. Ensuite, on classe !',
              'As soon as a player reaches 10,000, everyone else gets one final '
                  'turn to try to catch up. Then, the rankings!'),
        ),
        _SectionTitle(tr('Combinaisons de dés 🎲', 'Dice combinations 🎲')),
        _Rule(
          emoji: '✋',
          title: tr('Main pleine', 'Full hand'),
          text: tr(
              'Si tous tes dés marquent des points, tu dois reprendre toute la '
                  'main et relancer, en cumulant les points, tant que ça marche.',
              'If all your dice score points, you must pick them all up and '
                  'roll again, adding up the points, for as long as it works.'),
        ),
        _Rule(
          emoji: '3️⃣',
          title: tr('Brelan (3 dés pareils)', 'Three of a kind'),
          text: tr(
              'À n\'importe quel lancer : tu gagnes la centaine du chiffre '
                  '(brelan de 3 = 300, de 6 = 600…). Le brelan de 1 est le plus '
                  'fort : 1000 points.',
              'On any roll: you score the face value in hundreds '
                  '(three 3s = 300, three 6s = 600…). Three 1s are the best: '
                  '1,000 points.'),
        ),
        _Rule(
          emoji: '4️⃣',
          title: tr('Carré (4 dés pareils)', 'Four of a kind'),
          text: tr(
              'Ça double la valeur des dés : carré de 3 = 600, carré de 5 = '
                  '1000… et le carré de 1 vaut 2000 points.',
              'It doubles the value of the dice: four 3s = 600, four 5s = '
                  '1,000… and four 1s are worth 2,000 points.'),
        ),
        _Rule(
          emoji: '🪜',
          title: tr('Les suites', 'Straights'),
          text: tr(
              'Au 1ᵉʳ lancer du tour seulement. Petite suite 1-2-3-4-5 = 500. '
                  'Grande suite 2-3-4-5-6 = 1000. Tous les dés comptent (main '
                  'pleine) : il faut tout relancer pour continuer.',
              'On the 1st roll of the turn only. Small straight 1-2-3-4-5 = 500. '
                  'Large straight 2-3-4-5-6 = 1,000. All dice count (full '
                  'hand): you must roll them all again to keep going.'),
        ),
        _Rule(
          emoji: '🎩',
          title: tr('Le sombrero malgache', 'The Malagasy sombrero'),
          text: tr(
              'Au 1ᵉʳ lancer seulement. Si tu as deux paires (ex. deux 3 et '
                  'deux 5) + un dé à part, tu peux relancer ce dé isolé. S\'il '
                  'retombe sur l\'une des deux valeurs, tu gagnes la somme des deux '
                  'en centaines (deux 5 + deux 3 → 500 + 300 = 800). '
                  'C\'est une main pleine → tu rejoues tous les dés.\n'
                  '⚠️ Il faut l\'annoncer haut et fort AVANT de relancer : toute la '
                  'table doit savoir qu\'un sombrero malgache est en cours. Pas '
                  'd\'annonce = pas de sombrero, même s\'il tombe. On ne le joue '
                  'pas dans son coin !\n'
                  'Le nom est libre : baptise-le comme tu veux !',
              'On the 1st roll only. If you have two pairs (e.g. two 3s and '
                  'two 5s) + one odd die, you may re-roll that lone die. If it '
                  'lands on one of the two values, you score the sum of both in '
                  'hundreds (two 5s + two 3s → 500 + 300 = 800). '
                  'It\'s a full hand → you roll all the dice again.\n'
                  '⚠️ You must announce it loud and clear BEFORE re-rolling: the '
                  'whole table must know a Malagasy sombrero is under way. No '
                  'announcement = no sombrero, even if it lands. No playing it '
                  'on the sly!\n'
                  'The name is up to you: call it whatever you like!'),
        ),
      ];

  // ── Onglet L'appli ───────────────────────────────────────────────────────
  List<Widget> _app(BuildContext context) => [
        _Intro(
          emoji: '📱',
          text: tr(
              '10K remplace la feuille de score : tu lances les vrais dés, '
                  'l\'appli s\'occupe des points, des cœurs et des règles.',
              '10K replaces the score sheet: you roll the real dice, '
                  'the app takes care of points, hearts and rules.'),
        ),
        _Rule(
          emoji: '👥',
          title: tr('Préparer', 'Setting up'),
          text: tr(
              'Ajoute les joueurs (chacun reçoit un animal et une couleur au '
                  'hasard). Touche le crayon pour renommer, la croix pour retirer.',
              'Add the players (each gets a random animal and color). Tap the '
                  'pencil to rename, the cross to remove.'),
        ),
        _Rule(
          emoji: '⚙️',
          title: tr('Régler la partie', 'Game settings'),
          text: tr(
              'Dans la préparation, le bouton « Réglages » (en haut à droite) '
                  'ouvre tous les paramètres : objectif, cœurs, mode de jeu, etc.',
              'During setup, the “Settings” button (top right) opens all the '
                  'options: target, hearts, game mode, etc.'),
        ),
        _Rule(
          emoji: '🔢',
          title: tr('Saisir un score', 'Entering a score'),
          text: tr(
              'Touche la tuile d\'un joueur : une fenêtre s\'ouvre. Empile +100, '
                  '+500, +1000 (le petit bouton rouge « − » corrige), puis Valider.',
              'Tap a player\'s tile: a window opens. Stack up +100, +500, '
                  '+1000 (the small red “−” button corrects), then Confirm.'),
        ),
        _Rule(
          emoji: '🚫',
          title: tr('Passer / faire quitter', 'Pass / remove a player'),
          text: tr(
              'Le bouton « Passer » saute le tour. Un appui long sur une tuile, '
                  'relâché sans bouger, permet de faire quitter un joueur (il '
                  'reste au classement).',
              'The “Pass” button skips the turn. A long-press on a tile, '
                  'released without moving, lets a player leave the game (they '
                  'stay in the rankings).'),
        ),
        _Rule(
          emoji: '🔀',
          title: tr('Changer un joueur de place', 'Moving a player'),
          text: tr(
              'Quelqu\'un change de place à table ? Appui long sur sa tuile, '
                  'puis glisse-la sur un autre joueur : il prend sa place, et le '
                  'tour suit le nouvel ordre. Celui qui est en train de jouer garde '
                  'la main.',
              'Someone switched seats at the table? Long-press their tile, '
                  'then drag it onto another player: they take that spot, and '
                  'turns follow the new order. Whoever is playing keeps their '
                  'turn.'),
        ),
        _Rule(
          emoji: '↩️',
          title: tr('Se tromper ? Annuler', 'Made a mistake? Undo'),
          text: tr(
              'La flèche « retour arrière » en haut du plateau annule la dernière '
                  'action (score, échec, départ…). Aucune erreur n\'est définitive.',
              'The “back” arrow at the top of the board undoes the last action '
                  '(score, miss, departure…). No mistake is permanent.'),
        ),
        _Rule(
          emoji: '🌍',
          title: tr('Langue', 'Language'),
          text: tr(
              'Le bouton « EN » en haut de l\'accueil passe l\'appli en anglais ; '
                  '« FR » la remet en français.',
              'The “FR” button at the top of the home screen switches the app '
                  'to French; “EN” switches it back to English.'),
        ),
      ];

  // ── Onglet À propos ──────────────────────────────────────────────────────
  List<Widget> _about(BuildContext context) => [
        const SizedBox(height: 8),
        Center(
          child: Text('🎲',
              style: TextStyle(fontSize: 56, height: 1.2)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('10K',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
        Center(
          child: Text(
              tr('Le compagnon du jeu de 10 000',
                  'The 10,000 dice game companion'),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 20),
        _Rule(
          emoji: '💡',
          title: tr('L\'idée', 'The idea'),
          text: tr(
              'Fini les feuilles de score : du papier au téléphone. 10K pose le '
                  'jeu au centre de la table, en grand et en couleurs, et applique '
                  'les règles à ta place.',
              'No more score sheets: from paper to phone. 10K puts the game in '
                  'the middle of the table, big and colorful, and applies the '
                  'rules for you.'),
        ),
        _Rule(
          emoji: '🔒',
          title: tr('100 % hors ligne', '100% offline'),
          text: tr(
              'Aucune connexion, aucun compte, aucune donnée envoyée. Tout reste '
                  'sur ton téléphone.',
              'No connection, no account, no data sent. Everything stays on '
                  'your phone.'),
        ),
        // Carte de dédicace : interrupteur caché du mode trash.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onDedicationTap,
          child: _DedicationCard(active: ref.watch(trashModeProvider)),
        ),
        if (ref.watch(trashModeProvider)) ...[
          const SizedBox(height: 4),
          const _TrashBanner(),
        ],
        const SizedBox(height: 12),
        Center(
          child: Text(
              _packageInfo == null ? ' ' : 'Version ${_packageInfo!.version}',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  fontSize: 12)),
        ),
        // Crédit exigé par la licence CC BY 4.0 des effets sonores. Toujours
        // affiché (voir DECISIONS A-013).
        const SizedBox(height: 6),
        Center(
          child: Text(
              tr(
                  'Effets sonores : Yle Arkisto (freesound.org/s/425594), '
                      'licence CC BY 4.0 — extraits découpés et mis à niveau.',
                  'Sound effects: Yle Arkisto (freesound.org/s/425594), '
                      'CC BY 4.0 license — clips trimmed and level-adjusted.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  fontSize: 11)),
        ),
      ];

  /// Compte les tapes sur la dédicace et bascule le mode trash à la septième.
  void _onDedicationTap() {
    final active = ref.read(trashModeProvider);
    _taps++;

    if (_taps >= Taunts.unlockTaps) {
      _taps = 0;
      HapticFeedback.heavyImpact();
      final nowActive = ref.read(trashModeProvider.notifier).toggle();
      _announce(nowActive);
      return;
    }

    final hint = Taunts.unlockHint(_taps, active: active);
    if (hint == null) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(hint),
        duration: const Duration(milliseconds: 1200),
      ));
  }

  /// L'écran de bascule, façon enseigne qui s'allume (ou qui s'éteint).
  void _announce(bool active) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final skin = TenkSkin.of(ctx);
        return AlertDialog(
          icon: Text(active ? '☠️' : '🌈', style: const TextStyle(fontSize: 44)),
          title: Text(
            active ? Taunts.unlockedTitle : Taunts.lockedTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: active ? 2 : 0,
              color: active ? skin.neon : null,
            ),
          ),
          content: Text(
            active ? Taunts.unlockedBody : Taunts.lockedBody,
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(active
                  ? tr('Que le pire arrive', 'Bring on the worst')
                  : tr('Très bien', 'Very well')),
            ),
          ],
        );
      },
    );
  }

}

/// La carte de dédicace : identique à [_Rule] hors mode trash, avec un liseré
/// néon et une pastille « ×7 » quand il est actif, pour retrouver où retaper.
class _DedicationCard extends StatelessWidget {
  const _DedicationCard({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return const _DedicationRule();
    }
    final skin = TenkSkin.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: skin.neon, width: 2),
            boxShadow: [
              BoxShadow(
                  color: skin.neon.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1),
            ],
          ),
          child: const _DedicationRule(),
        ),
        Positioned(
          top: -10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: skin.neon,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(tr('RETAPE ×7', 'TAP ×7 AGAIN'),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.black)),
          ),
        ),
      ],
    );
  }
}

/// Le contenu de la carte de dédicace (le même, mode trash ou non).
class _DedicationRule extends StatelessWidget {
  const _DedicationRule();

  @override
  Widget build(BuildContext context) {
    return _Rule(
      emoji: '🌈',
      title: tr('Imaginé par Ben, vibecodé par Claude',
          'Dreamed up by Ben, vibe-coded by Claude'),
      text: tr(
          'Un projet perso pour les soirées entre amis. Dédicace à Fanch, '
              'Khorven et Victor pour cette introduction aux 10 000 ! 🍻',
          'A personal project for game nights with friends. Shout-out to '
              'Fanch, Khorven and Victor for introducing me to 10,000! 🍻'),
    );
  }
}

/// Bandeau qui rappelle, dans « À propos », que le mode trash est actif et
/// comment s'en débarrasser.
class _TrashBanner extends StatelessWidget {
  const _TrashBanner();

  @override
  Widget build(BuildContext context) {
    final skin = TenkSkin.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.neon.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(skin.corner),
        border: Border.all(color: skin.neon.withValues(alpha: 0.7), width: 2),
      ),
      child: Row(
        children: [
          const Text('☠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${Taunts.activeBanner}\n${tr('Retape 7 fois la carte ci-dessus pour '
                  'revenir à la version polie.', 'Tap the card above 7 times again '
                  'to get the polite version back.')}',
              style: const TextStyle(
                  fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.emoji, required this.text});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 15, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.emoji, required this.title, required this.text});
  final String emoji;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(text,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
