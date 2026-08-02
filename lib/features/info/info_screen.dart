import 'package:flutter/material.dart';

import '../../shared/widgets/app_background.dart';

/// Fiche d'information : règles du jeu, aide sur l'appli, et « à propos ».
/// Accessible depuis le petit « ? » de l'accueil.
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  int _tab = 0;

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
                    onSelectionChanged: (s) => setState(() => _tab = s.first),
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
        const _Rule(
          emoji: '🌈',
          title: 'Imaginé par Ben, vibecodé par Claude',
          text:
              'Un projet perso pour les soirées entre amis. Dédicace à Fanch, '
              'Khorven et Victor pour cette introduction aux 10 000 ! 🍻',
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('Version 1.0',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  fontSize: 12)),
        ),
      ];
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
