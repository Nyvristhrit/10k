import '../../domain/models/animal_avatar.dart';

/// Catalogue des totems animaux (Annexe A de la spécification).
///
/// Le tirage se fait sans remise parmi les entrées `eligibleForRandomDraw`.
/// Chaque entrée a un `id` stable et un `familyId` regroupant les variantes
/// proches. Ce catalogue peut être enrichi sans changer la logique du moteur.
///
/// Note : la spécification décrit 137 identités éligibles ; ce fichier en
/// contient un large sous-ensemble représentatif (voir DECISIONS.md D-004).
class AnimalCatalog {
  const AnimalCatalog._();

  static const List<AnimalAvatar> all = [
    // ── Mammifères ──────────────────────────────────────────────────────────
    AnimalAvatar(id: 'monkey', emoji: '🐵', defaultFrenchName: 'Petit singe', familyId: 'monkey'),
    AnimalAvatar(id: 'gorilla', emoji: '🦍', defaultFrenchName: 'Gorille', familyId: 'gorilla'),
    AnimalAvatar(id: 'dog', emoji: '🐶', defaultFrenchName: 'Chiot', familyId: 'dog'),
    AnimalAvatar(id: 'wolf', emoji: '🐺', defaultFrenchName: 'Loup', familyId: 'wolf'),
    AnimalAvatar(id: 'fox', emoji: '🦊', defaultFrenchName: 'Renard', familyId: 'fox'),
    AnimalAvatar(id: 'raccoon', emoji: '🦝', defaultFrenchName: 'Raton laveur', familyId: 'raccoon'),
    AnimalAvatar(id: 'cat', emoji: '🐱', defaultFrenchName: 'Chaton', familyId: 'cat'),
    AnimalAvatar(id: 'lion', emoji: '🦁', defaultFrenchName: 'Lion', familyId: 'lion'),
    AnimalAvatar(id: 'tiger', emoji: '🐯', defaultFrenchName: 'Tigre', familyId: 'tiger'),
    AnimalAvatar(id: 'leopard', emoji: '🐆', defaultFrenchName: 'Léopard', familyId: 'leopard'),
    AnimalAvatar(id: 'horse', emoji: '🐴', defaultFrenchName: 'Poney', familyId: 'horse'),
    AnimalAvatar(id: 'unicorn', emoji: '🦄', defaultFrenchName: 'Licorne', familyId: 'unicorn'),
    AnimalAvatar(id: 'zebra', emoji: '🦓', defaultFrenchName: 'Zèbre', familyId: 'zebra'),
    AnimalAvatar(id: 'deer', emoji: '🦌', defaultFrenchName: 'Cerf', familyId: 'deer'),
    AnimalAvatar(id: 'bison', emoji: '🦬', defaultFrenchName: 'Bison', familyId: 'bison'),
    AnimalAvatar(id: 'cow', emoji: '🐮', defaultFrenchName: 'Vache', familyId: 'cow'),
    AnimalAvatar(id: 'ox', emoji: '🐂', defaultFrenchName: 'Bœuf', familyId: 'ox'),
    AnimalAvatar(id: 'pig', emoji: '🐷', defaultFrenchName: 'Cochon', familyId: 'pig'),
    AnimalAvatar(id: 'boar', emoji: '🐗', defaultFrenchName: 'Sanglier', familyId: 'boar'),
    AnimalAvatar(id: 'ram', emoji: '🐏', defaultFrenchName: 'Bélier', familyId: 'ram'),
    AnimalAvatar(id: 'sheep', emoji: '🐑', defaultFrenchName: 'Brebis', familyId: 'sheep'),
    AnimalAvatar(id: 'goat', emoji: '🐐', defaultFrenchName: 'Chèvre', familyId: 'goat'),
    AnimalAvatar(id: 'camel', emoji: '🐫', defaultFrenchName: 'Chameau', familyId: 'camel'),
    AnimalAvatar(id: 'llama', emoji: '🦙', defaultFrenchName: 'Lama', familyId: 'llama'),
    AnimalAvatar(id: 'giraffe', emoji: '🦒', defaultFrenchName: 'Girafe', familyId: 'giraffe'),
    AnimalAvatar(id: 'elephant', emoji: '🐘', defaultFrenchName: 'Éléphant', familyId: 'elephant'),
    AnimalAvatar(id: 'mammoth', emoji: '🦣', defaultFrenchName: 'Mammouth', familyId: 'mammoth'),
    AnimalAvatar(id: 'rhino', emoji: '🦏', defaultFrenchName: 'Rhinocéros', familyId: 'rhinoceros'),
    AnimalAvatar(id: 'hippo', emoji: '🦛', defaultFrenchName: 'Hippopotame', familyId: 'hippopotamus'),
    AnimalAvatar(id: 'mouse', emoji: '🐭', defaultFrenchName: 'Petite souris', familyId: 'mouse'),
    AnimalAvatar(id: 'rat', emoji: '🐀', defaultFrenchName: 'Rat', familyId: 'rat'),
    AnimalAvatar(id: 'hamster', emoji: '🐹', defaultFrenchName: 'Hamster', familyId: 'hamster'),
    AnimalAvatar(id: 'rabbit', emoji: '🐰', defaultFrenchName: 'Petit lapin', familyId: 'rabbit'),
    AnimalAvatar(id: 'hedgehog', emoji: '🦔', defaultFrenchName: 'Hérisson', familyId: 'hedgehog'),
    AnimalAvatar(id: 'bat', emoji: '🦇', defaultFrenchName: 'Chauve-souris', familyId: 'bat'),
    AnimalAvatar(id: 'bear', emoji: '🐻', defaultFrenchName: 'Ours', familyId: 'bear'),
    AnimalAvatar(id: 'koala', emoji: '🐨', defaultFrenchName: 'Koala', familyId: 'koala'),
    AnimalAvatar(id: 'panda', emoji: '🐼', defaultFrenchName: 'Panda', familyId: 'panda'),
    AnimalAvatar(id: 'sloth', emoji: '🦥', defaultFrenchName: 'Paresseux', familyId: 'sloth'),
    AnimalAvatar(id: 'otter', emoji: '🦦', defaultFrenchName: 'Loutre', familyId: 'otter'),
    AnimalAvatar(id: 'skunk', emoji: '🦨', defaultFrenchName: 'Moufette', familyId: 'skunk'),
    AnimalAvatar(id: 'kangaroo', emoji: '🦘', defaultFrenchName: 'Kangourou', familyId: 'kangaroo'),
    AnimalAvatar(id: 'badger', emoji: '🦡', defaultFrenchName: 'Blaireau', familyId: 'badger'),

    // ── Oiseaux ─────────────────────────────────────────────────────────────
    AnimalAvatar(id: 'turkey', emoji: '🦃', defaultFrenchName: 'Dinde', familyId: 'turkey'),
    AnimalAvatar(id: 'chicken', emoji: '🐔', defaultFrenchName: 'Poule', familyId: 'chicken'),
    AnimalAvatar(id: 'rooster', emoji: '🐓', defaultFrenchName: 'Coq', familyId: 'rooster'),
    AnimalAvatar(id: 'chick', emoji: '🐤', defaultFrenchName: 'Poussin', familyId: 'chick'),
    AnimalAvatar(id: 'bird', emoji: '🐦', defaultFrenchName: 'Oiseau', familyId: 'bird'),
    AnimalAvatar(id: 'penguin', emoji: '🐧', defaultFrenchName: 'Pingouin', familyId: 'penguin'),
    AnimalAvatar(id: 'eagle', emoji: '🦅', defaultFrenchName: 'Aigle', familyId: 'eagle'),
    AnimalAvatar(id: 'duck', emoji: '🦆', defaultFrenchName: 'Canard', familyId: 'duck'),
    AnimalAvatar(id: 'swan', emoji: '🦢', defaultFrenchName: 'Cygne', familyId: 'swan'),
    AnimalAvatar(id: 'owl', emoji: '🦉', defaultFrenchName: 'Hibou', familyId: 'owl'),
    AnimalAvatar(id: 'flamingo', emoji: '🦩', defaultFrenchName: 'Flamant rose', familyId: 'flamingo'),
    AnimalAvatar(id: 'peacock', emoji: '🦚', defaultFrenchName: 'Paon', familyId: 'peacock'),
    AnimalAvatar(id: 'parrot', emoji: '🦜', defaultFrenchName: 'Perroquet', familyId: 'parrot'),

    // ── Amphibiens et reptiles ──────────────────────────────────────────────
    AnimalAvatar(id: 'frog', emoji: '🐸', defaultFrenchName: 'Grenouille', familyId: 'frog'),
    AnimalAvatar(id: 'crocodile', emoji: '🐊', defaultFrenchName: 'Crocodile', familyId: 'crocodile'),
    AnimalAvatar(id: 'turtle', emoji: '🐢', defaultFrenchName: 'Tortue', familyId: 'turtle'),
    AnimalAvatar(id: 'lizard', emoji: '🦎', defaultFrenchName: 'Lézard', familyId: 'lizard'),
    AnimalAvatar(id: 'snake', emoji: '🐍', defaultFrenchName: 'Serpent', familyId: 'snake'),
    AnimalAvatar(id: 'dragon', emoji: '🐉', defaultFrenchName: 'Dragon', familyId: 'dragon'),
    AnimalAvatar(id: 'trex', emoji: '🦖', defaultFrenchName: 'T-Rex', familyId: 'trex'),
    AnimalAvatar(id: 'sauropod', emoji: '🦕', defaultFrenchName: 'Sauropode', familyId: 'sauropod'),

    // ── Animaux marins ──────────────────────────────────────────────────────
    AnimalAvatar(id: 'whale', emoji: '🐳', defaultFrenchName: 'Baleine', familyId: 'whale'),
    AnimalAvatar(id: 'dolphin', emoji: '🐬', defaultFrenchName: 'Dauphin', familyId: 'dolphin'),
    AnimalAvatar(id: 'seal', emoji: '🦭', defaultFrenchName: 'Phoque', familyId: 'seal'),
    AnimalAvatar(id: 'fish', emoji: '🐟', defaultFrenchName: 'Poisson', familyId: 'fish'),
    AnimalAvatar(id: 'blowfish', emoji: '🐡', defaultFrenchName: 'Poisson-globe', familyId: 'blowfish'),
    AnimalAvatar(id: 'shark', emoji: '🦈', defaultFrenchName: 'Requin', familyId: 'shark'),
    AnimalAvatar(id: 'octopus', emoji: '🐙', defaultFrenchName: 'Pieuvre', familyId: 'octopus'),
    AnimalAvatar(id: 'crab', emoji: '🦀', defaultFrenchName: 'Crabe', familyId: 'crab'),
    AnimalAvatar(id: 'lobster', emoji: '🦞', defaultFrenchName: 'Homard', familyId: 'lobster'),
    AnimalAvatar(id: 'shrimp', emoji: '🦐', defaultFrenchName: 'Crevette', familyId: 'shrimp'),
    AnimalAvatar(id: 'squid', emoji: '🦑', defaultFrenchName: 'Calmar', familyId: 'squid'),

    // ── Insectes et petits animaux ──────────────────────────────────────────
    AnimalAvatar(id: 'snail', emoji: '🐌', defaultFrenchName: 'Escargot', familyId: 'snail'),
    AnimalAvatar(id: 'butterfly', emoji: '🦋', defaultFrenchName: 'Papillon', familyId: 'butterfly'),
    AnimalAvatar(id: 'ant', emoji: '🐜', defaultFrenchName: 'Fourmi', familyId: 'ant'),
    AnimalAvatar(id: 'bee', emoji: '🐝', defaultFrenchName: 'Abeille', familyId: 'bee'),
    AnimalAvatar(id: 'ladybug', emoji: '🐞', defaultFrenchName: 'Coccinelle', familyId: 'ladybug'),
    AnimalAvatar(id: 'cricket', emoji: '🦗', defaultFrenchName: 'Criquet', familyId: 'cricket'),
    AnimalAvatar(id: 'scorpion', emoji: '🦂', defaultFrenchName: 'Scorpion', familyId: 'scorpion'),

    // ── Symboles conservés mais exclus du tirage par défaut (§6.4) ───────────
    AnimalAvatar(id: 'paws', emoji: '🐾', defaultFrenchName: 'Empreintes', familyId: 'paws', eligibleForRandomDraw: false),
    AnimalAvatar(id: 'feather', emoji: '🪶', defaultFrenchName: 'Plume', familyId: 'feather', eligibleForRandomDraw: false),
    AnimalAvatar(id: 'shell', emoji: '🐚', defaultFrenchName: 'Coquillage', familyId: 'shell', eligibleForRandomDraw: false),
    AnimalAvatar(id: 'microbe', emoji: '🦠', defaultFrenchName: 'Microbe', familyId: 'microbe', eligibleForRandomDraw: false),
  ];

  /// Entrées réellement tirables comme identité de joueur.
  static List<AnimalAvatar> get eligible =>
      all.where((a) => a.eligibleForRandomDraw).toList();

  /// Retrouve un animal par son id (ou `null`).
  static AnimalAvatar? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
