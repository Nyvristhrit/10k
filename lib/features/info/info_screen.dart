import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../shared/widgets/app_background.dart';

/// Fiche d'information : règles du jeu, aide sur l'appli, et « à propos ».
/// Accessible depuis le petit « ? » de l'accueil.
///
/// C'est aussi la porte dérobée du **mode trash** : sept tapes sur la carte de
/// dédicace (onglet « À propos ») font basculer l'appli, exactement comme les
/// sept tapes sur le numéro de build déverrouillent les options développeur
/// d'Android.
class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  int _tab = 0;
  int _taps = 0;

  /// Version affichée dans « À propos », lue depuis `pubspec.yaml` (jamais à
  /// remettre à jour à la main : elle suit le numéro de version réel de
  /// l'APK installé). `null` tant qu'elle n'est pas encore chargée.
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    }).catchError((_) {
      // Si la plateforme ne répond pas, on garde simplement la ligne vide
      // plutôt que de planter l'écran pour un simple numéro de version.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Aide & règles')),
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
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Règles')),
                      ButtonSegment(value: 1, label: Text('L\'appli')),
                      ButtonSegment(value: 2, label: Text('À propos')),
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
        const _Intro(
          emoji: '🎲',
          text:
              'But du jeu : être le premier à atteindre exactement 10 000 points. '
              'Chacun lance les dés à son tour et l\'appli tient les scores.',
        ),
        const _Rule(
          emoji: '🚪',
          title: 'Sortir',
          text:
              'Au premier tour réussi, il faut marquer au moins 300 points pour '
              '« sortir » et entrer dans la partie. (Ce minimum est réglable.)',
        ),
        const _Rule(
          emoji: '➕',
          title: 'Marquer',
          text:
              'À chaque tour réussi, on ajoute les points marqués. Ils s\'empilent '
              'les uns sur les autres : c\'est la « pile de gains ».',
        ),
        const _Rule(
          emoji: '❤️',
          title: 'Les 3 cœurs',
          text:
              'Chaque joueur a 3 cœurs. Un tour raté fait perdre un cœur. Au 3ᵉ '
              'échec, le dernier gain de la pile est annulé… puis les 3 cœurs '
              'reviennent. Un tour réussi restaure aussi les 3 cœurs d\'un coup.',
        ),
        const _Rule(
          emoji: '🤝',
          title: 'La rencontre',
          text:
              'Si en marquant tu tombes exactement sur le total d\'un adversaire, '
              'c\'est une « rencontre » : ce dernier perd son dernier gain. '
              'Malin pour freiner celui qui mène !',
        ),
        const _Rule(
          emoji: '🎯',
          title: 'Tomber pile',
          text:
              'Il faut atteindre 10 000 pile. Un score qui te ferait dépasser '
              '10 000 est refusé et compte comme un tour raté.',
        ),
        const _Rule(
          emoji: '⏳',
          title: 'Dernière chance',
          text:
              'Dès qu\'un joueur atteint 10 000, tous les autres ont droit à un '
              'ultime tour pour tenter de le rejoindre. Ensuite, on classe !',
        ),
        const _SectionTitle('Combinaisons de dés 🎲'),
        const _Rule(
          emoji: '✋',
          title: 'Main pleine',
          text:
              'Si tous tes dés marquent des points, tu dois reprendre toute la '
              'main et relancer, en cumulant les points, tant que ça marche.',
        ),
        const _Rule(
          emoji: '3️⃣',
          title: 'Brelan (3 dés pareils)',
          text:
              'À n\'importe quel lancer : tu gagnes la centaine du chiffre '
              '(brelan de 3 = 300, de 6 = 600…). Le brelan de 1 est le plus '
              'fort : 1000 points.',
        ),
        const _Rule(
          emoji: '4️⃣',
          title: 'Carré (4 dés pareils)',
          text:
              'Ça double la valeur des dés : carré de 3 = 600, carré de 5 = '
              '1000… et le carré de 1 vaut 2000 points.',
        ),
        const _Rule(
          emoji: '🪜',
          title: 'Les suites',
          text:
              'Au 1ᵉʳ lancer du tour seulement. Petite suite 1-2-3-4-5 = 500. '
              'Grande suite 2-3-4-5-6 = 1000. Tous les dés comptent (main '
              'pleine) : il faut tout relancer pour continuer.',
        ),
        const _Rule(
          emoji: '🎩',
          title: 'Le sombrero malgache',
          text:
              'Au 1ᵉʳ lancer seulement. Si tu as deux paires (ex. deux 3 et '
              'deux 5) + un dé à part, tu peux l\'annoncer à la table et '
              'relancer ce dé isolé. S\'il retombe sur l\'une des deux valeurs, '
              'tu gagnes la somme des deux en centaines (deux 5 + deux 3 → '
              '500 + 300 = 800). Le nom est libre : baptise-le comme tu veux ! '
              'C\'est une main pleine → tu rejoues tous les dés.',
        ),
      ];

  // ── Onglet L'appli ───────────────────────────────────────────────────────
  List<Widget> _app(BuildContext context) => [
        const _Intro(
          emoji: '📱',
          text:
              '10K remplace la feuille de score : tu lances les vrais dés, '
              'l\'appli s\'occupe des points, des cœurs et des règles.',
        ),
        const _Rule(
          emoji: '👥',
          title: 'Préparer',
          text:
              'Ajoute les joueurs (chacun reçoit un animal et une couleur au '
              'hasard). Touche le crayon pour renommer, la croix pour retirer.',
        ),
        const _Rule(
          emoji: '⚙️',
          title: 'Régler la partie',
          text:
              'Dans la préparation, le bouton « Réglages » (en haut à droite) '
              'ouvre tous les paramètres : objectif, cœurs, mode de jeu, etc.',
        ),
        const _Rule(
          emoji: '🔢',
          title: 'Saisir un score',
          text:
              'Touche la tuile d\'un joueur : une fenêtre s\'ouvre. Empile +100, '
              '+500, +1000 (le petit bouton rouge « − » corrige), puis Valider.',
        ),
        const _Rule(
          emoji: '🚫',
          title: 'Passer / faire quitter',
          text:
              'Le bouton « Passer » saute le tour. Un appui long sur une tuile '
              'permet de faire quitter un joueur (il reste au classement).',
        ),
        const _Rule(
          emoji: '↩️',
          title: 'Se tromper ? Annuler',
          text:
              'La flèche « retour arrière » en haut du plateau annule la dernière '
              'action (score, échec, départ…). Aucune erreur n\'est définitive.',
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
          child: Text('Le compagnon du jeu de 10 000',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 20),
        const _Rule(
          emoji: '💡',
          title: 'L\'idée',
          text:
              'Fini les feuilles de score : du papier au téléphone. 10K pose le '
              'jeu au centre de la table, en grand et en couleurs, et applique '
              'les règles à ta place.',
        ),
        const _Rule(
          emoji: '🔒',
          title: '100 % hors ligne',
          text:
              'Aucune connexion, aucun compte, aucune donnée envoyée. Tout reste '
              'sur ton téléphone.',
        ),
        // La carte de dédicace cache l'interrupteur du mode trash : sept tapes
        // et l'appli change de personnalité (voir `_onDedicationTap`). Une fois
        // le mode actif, elle porte elle-même le liseré néon (au lieu de se
        // fondre dans les cartes voisines) pour qu'on retrouve où retaper.
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
        const _SupportCard(),
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
      ];

  /// Compte les tapes sur la carte de dédicace et bascule le mode trash à la
/// septième — avec un compte à rebours à partir de la quatrième, comme Android.
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
              child: Text(active ? 'Que le pire arrive' : 'Très bien'),
            ),
          ],
        );
      },
    );
  }

}

/// La carte de dédicace elle-même : identique à [_Rule] quand le mode trash
/// est éteint (l'interrupteur reste caché, comme sur Android), mais porte un
/// liseré néon + une pastille « ×7 » une fois actif, pour qu'on retrouve du
/// premier coup d'œil où retaper (retour signalé par un ami : le bandeau du
/// dessous ne suffisait pas à repérer la bonne carte).
class _DedicationCard extends StatelessWidget {
  const _DedicationCard({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return const _Rule(
        emoji: '🌈',
        title: 'Imaginé par Ben, vibecodé par Claude',
        text: 'Un projet perso pour les soirées entre amis. Dédicace à Fanch, '
            'Khorven et Victor pour cette introduction aux 10 000 ! 🍻',
      );
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
          child: const _Rule(
            emoji: '🌈',
            title: 'Imaginé par Ben, vibecodé par Claude',
            text:
                'Un projet perso pour les soirées entre amis. Dédicace à Fanch, '
                'Khorven et Victor pour cette introduction aux 10 000 ! 🍻',
          ),
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
            child: const Text('RETAPE ×7',
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
              '${Taunts.activeBanner}\nRetape 7 fois la carte ci-dessus pour '
              'revenir à la version polie.',
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

/// Carte « offrir un café » (Ko-fi) : l'appli reste gratuite et sans pub, ce
/// lien est purement facultatif — un simple lien externe, aucune donnée
/// envoyée par ailleurs (cohérent avec le « 100 % hors ligne » ci-dessus).
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  static final Uri _koFiUrl = Uri.parse('https://ko-fi.com/qubestudio');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('☕', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Envie de soutenir le projet ?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '10K reste gratuit et sans pub. Si tu veux offrir un café, '
                  'c\'est facultatif et ça fait toujours plaisir.',
                  style: TextStyle(
                      fontSize: 14, height: 1.35, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      launchUrl(_koFiUrl, mode: LaunchMode.externalApplication),
                  icon: const Text('☕'),
                  label: const Text('Offrir un café sur Ko-fi'),
                ),
              ],
            ),
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
