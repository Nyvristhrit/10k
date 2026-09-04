/// Une version notable, avec ses nouveautés côté joueur (texte simple, pas de
/// jargon technique). Volontairement **pas** un miroir exhaustif de
/// `CHANGELOG.md` : seules les versions avec un changement visible pour un
/// joueur y figurent, comme sur la page de téléchargement — un correctif
/// mineur/cosmétique n'a pas sa place ici. Les deux listes (celle-ci et le
/// bloc `.changelog` de `docs/index.html`) doivent rester en phase à chaque
/// publication notable (voir la procédure dans `CHANGELOG.md`).
class WhatsNewRelease {
  const WhatsNewRelease({required this.version, required this.items});

  /// Numéro de version (`X.Y.Z`), sans le `v` — comparé terme à terme.
  final String version;
  final List<String> items;
}

class WhatsNewCatalog {
  /// Du plus ancien au plus récent : `releases.last` est toujours la version
  /// notable la plus récente.
  static const List<WhatsNewRelease> releases = [
    WhatsNewRelease(version: '1.1.0', items: [
      'Correction : les vies se restaurent bien à 3 quand une rencontre vide entièrement la pile d\'un joueur.',
      'Toggle du mode trash rendu plus visible.',
      'Noms de joueur par défaut façon totem scout (espèce + épithète), avec éditeur d\'épithètes perso en mode trash.',
      'Écran toujours allumé pendant la partie (réglable).',
      'Mode paysage pour utilisation sur tablette.',
    ]),
    WhatsNewRelease(version: '1.2.0', items: [
      'Éditeur d\'épithètes trash (réglages) clarifié et plafonné à 20.',
      'Corrections visuelles de la page de téléchargement (logo, mode paysage).',
    ]),
    WhatsNewRelease(version: '1.3.0', items: [
      'Historique de la partie : consulte tous les coups joués manche par manche, et reviens en arrière en touchant l\'un d\'eux.',
      'Plateau de dés virtuel intégré : lance, garde et relance des dés directement dans l\'appli si tu n\'en as pas sous la main.',
    ]),
    WhatsNewRelease(version: '1.3.3', items: [
      'Correction : les noms de joueur trop longs (surtout en mode trash) n\'étaient plus coupés en plein mot — le texte rétrécit désormais pour tenir en entier sur la tuile.',
      'Le halo du joueur dont c\'est le tour est plus visible.',
      'Nouveau réglage pour masquer les dés intégrés si tu joues avec de vrais dés, qui adoptent aussi une teinte aléatoire à chaque ouverture.',
    ]),
    WhatsNewRelease(version: '1.4.0', items: [
      'Nouvel écran « Stats & records » : parties jouées, temps de jeu cumulé, manches moyennes par score cible, plus gros carton…',
      'Alias de joueur (stable d\'une partie à l\'autre) et écran « Alias & profils » : victoires par personne, couleur perso, renommage.',
    ]),
    WhatsNewRelease(version: '1.5.0', items: [
      'Dernière chance : un joueur délogé peut désormais retenter sa chance et redéloger l\'adversaire — la revanche est illimitée, jusqu\'à ce qu\'un candidat traverse un tour complet sans se faire déloger.',
      'Cette fenêtre « Quoi de neuf » : un résumé des nouveautés s\'affiche automatiquement après une mise à jour.',
    ]),
  ];

  /// Les versions strictement postérieures à [seenVersion], dans l'ordre
  /// chronologique (les plus anciennes d'abord, pour lire la progression).
  static List<WhatsNewRelease> since(String seenVersion) {
    return releases.where((r) => _compare(r.version, seenVersion) > 0).toList();
  }

  /// Compare deux versions `X.Y.Z` terme à terme (pas un tri alphabétique :
  /// « 1.10.0 » doit rester après « 1.9.0 »). Un terme manquant ou non
  /// numérique compte comme 0.
  static int _compare(String a, String b) {
    final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }
}
