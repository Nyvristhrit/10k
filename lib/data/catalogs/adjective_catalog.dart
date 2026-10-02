/// Épithètes façon totem scout, associées à l'espèce tirée pour former un nom
/// par défaut (« Panda Facétieux », « Baleine Fourbe »…).
///
/// Convention volontaire : comme les vrais totems scouts, l'épithète est une
/// **étiquette invariable** accolée à l'espèce — elle ne s'accorde pas en
/// genre avec l'animal (on ne cherche pas « Baleine Fourbee »). D'où le choix
/// d'adjectifs qui passent bien tels quels dans les deux cas.
class AdjectiveCatalog {
  const AdjectiveCatalog._();

  /// Épithètes du mode sage : bon enfant, jamais blessantes.
  static const List<String> safe = [
    'Malicieux·se',
    'Vigilant·e',
    'Bondissant·e',
    'Rusé·e',
    'Discret·ète',
    'Généreux·se',
    'Farceur·euse',
    'Espiègle',
    'Tonitruant·e',
    'Placide',
    'Impétueux·se',
    'Débonnaire',
    'Jovial·e',
    'Facétieux·se',
    'Intrépide',
    'Nonchalant·e',
    'Grincheux·se',
    'Flegmatique',
    'Perspicace',
    'Audacieux·se',
    'Candide',
    'Volubile',
    'Taciturne',
    'Frivole',
    'Bienveillant·e',
    'Redoutable',
    'Indomptable',
    'Chafouin·e',
    'Gaillard·e',
    'Loufoque',
    'Cabotin·e',
    'Fanfaron·ne',
    'Bougon·ne',
    'Rêveur·euse',
    'Vaillant·e',
    'Truculent·e',
    'Sournois·e',
    'Goguenard·e',
    'Pétulant·e',
    'Fantasque',
    'Coquin·e',
    'Turbulent·e',
    'Frondeur·euse',
    'Impassible',
    'Farfelu·e',
    'Baroudeur·euse',
    'Cocasse',
    'Guilleret·ète',
    'Enjoué·e',
    'Malin·igne',
    'Étourdi·e',
    'Distrait·e',
    'Casanier·ère',
    'Bavard·e',
    'Curieux·se',
    'Gourmand·e',
    'Craintif·ive',
    'Fougueux·se',
    'Songeur·euse',
    'Rigolo·te',
    'Astucieux·se',
    'Bricoleur·euse',
    'Aventurier·ère',
    'Diplomate',
    'Stratège',
    'Philosophe',
    'Poète',
    'Acrobate',
    'Cascadeur·euse',
    'Costaud·e',
    'Increvable',
    'Infatigable',
    'Matinal·e',
    'Gaffeur·euse',
    'Minutieux·se',
    'Impatient·e',
    'Optimiste',
    'Ronchon·ne',
    'Chanceux·se',
    'Sentimental·e',
    'Nostalgique',
  ];

  /// Épithètes du mode trash **proposées par défaut** : moqueuses, du
  /// chambrage de comptoir — mais sans grossièretés ni insultes visant un
  /// groupe de personnes, pour rester dans les clous du Play Store (v1.6.1,
  /// voir DECISIONS F-006). La table peut les retirer, ajouter les siennes
  /// (y compris bien plus salées) ou revenir à cette liste depuis les
  /// réglages : seule la liste de la table est utilisée pour tirer les noms
  /// (`SettingsRepository.loadTrashAdjectives`). Volontairement courte (une
  /// dizaine) : qui veut repartir de zéro la vide en quelques tapes.
  static const List<String> trash = [
    'Loser',
    'Nullos',
    'Gland',
    'Tocard·e',
    'Boulet',
    'Bouffon·ne',
    'Baltringue',
    'Gros naze',
    'Tête à claques',
    'Tête de nœud',
  ];
}
