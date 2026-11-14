import '../../l10n/l10n.dart';

/// Épithètes façon totem scout, accolées à l'espèce pour former un nom par
/// défaut (« Panda Facétieux »). Elles ne s'accordent pas en genre : on choisit
/// des adjectifs qui passent au masculin comme au féminin.
class AdjectiveCatalog {
  const AdjectiveCatalog._();

  /// Épithètes sages dans la langue de l'interface.
  static List<String> get safeLocalized => trList(safe, safeEn);

  /// Épithètes trash proposées par défaut dans la langue de l'interface.
  static List<String> get trashDefaults => trList(trash, trashEn);

  /// Épithètes sages en anglais (placées devant l'espèce : « Sneaky Panda »).
  static const List<String> safeEn = [
    'Mischievous', 'Watchful', 'Bouncy', 'Cunning', 'Sneaky', 'Generous',
    'Prankster', 'Impish', 'Thunderous', 'Placid', 'Fiery', 'Easygoing',
    'Jolly', 'Cheeky', 'Fearless', 'Nonchalant', 'Grumpy', 'Unflappable',
    'Sharp-eyed', 'Daring', 'Innocent', 'Chatty', 'Silent', 'Flighty',
    'Kindly', 'Formidable', 'Untamed', 'Shifty', 'Hearty', 'Wacky', 'Hammy',
    'Boastful', 'Grouchy', 'Dreamy', 'Valiant', 'Colorful', 'Sly',
    'Smirking', 'Bubbly', 'Whimsical', 'Naughty', 'Rowdy', 'Rebel', 'Stoic',
    'Zany', 'Roving', 'Quirky', 'Chirpy', 'Playful', 'Clever',
    'Scatterbrained', 'Absent-minded', 'Homebody', 'Talkative', 'Curious',
    'Greedy', 'Timid', 'Spirited', 'Pensive', 'Funny', 'Crafty', 'Handy',
    'Adventurous', 'Diplomatic', 'Scheming', 'Philosopher', 'Poet',
    'Acrobat', 'Daredevil', 'Burly', 'Unstoppable', 'Tireless', 'Early-bird',
    'Clumsy', 'Meticulous', 'Impatient', 'Optimistic', 'Cranky', 'Lucky',
    'Sentimental', 'Nostalgic',
  ];

  /// Épithètes trash par défaut, en anglais.
  static const List<String> trashEn = [
    'Loser',
    'Clown',
    'Muppet',
    'Numpty',
    'Doofus',
    'Dingbat',
    'Goofball',
    'Knucklehead',
    'Nitwit',
    'Dead-weight',
  ];

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

  /// Épithètes trash par défaut : moqueuses mais sans grossièreté (règles du
  /// Play Store). La table peut modifier la liste dans les réglages.
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
