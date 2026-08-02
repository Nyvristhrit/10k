import '../../domain/models/animal_avatar.dart';

/// Catalogue des totems animaux (Annexe A de la spécification).
///
/// Le tirage se fait sans remise parmi les entrées `eligibleForRandomDraw`.
/// Chaque entrée a un `id` stable et un `familyId` regroupant les variantes
/// proches. Ce catalogue peut être enrichi sans changer la logique du moteur.
///
/// Chaque totem porte aussi une liste d'`species` : de vraies espèces courtes
/// (ex. l'oiseau → Bouvreuil, Mésange…). À la création d'un joueur sans nom
/// choisi, on tire une de ces espèces comme nom affiché (l'emoji, lui, ne change
/// pas). Les noms sont volontairement **courts** pour ne pas casser la mise en
/// page des tuiles.
///
/// Note : la spécification décrit 137 identités éligibles ; ce fichier en
/// contient un large sous-ensemble représentatif (voir DECISIONS.md D-004).
class AnimalCatalog {
  const AnimalCatalog._();

  static const List<AnimalAvatar> all = [
    // ── Mammifères ──────────────────────────────────────────────────────────
    AnimalAvatar(id: 'monkey', emoji: '🐵', defaultFrenchName: 'Petit singe', familyId: 'monkey', species: ['Ouistiti', 'Capucin', 'Macaque', 'Tamarin', 'Saïmiri']),
    AnimalAvatar(id: 'gorilla', emoji: '🦍', defaultFrenchName: 'Gorille', familyId: 'gorilla', species: ['Gorille', 'Dos argenté', 'Chimpanzé', 'Bonobo']),
    AnimalAvatar(id: 'dog', emoji: '🐶', defaultFrenchName: 'Chiot', familyId: 'dog', species: ['Labrador', 'Caniche', 'Chihuahua', 'Beagle', 'Husky', 'Teckel', 'Berger', 'Bouledogue']),
    AnimalAvatar(id: 'wolf', emoji: '🐺', defaultFrenchName: 'Loup', familyId: 'wolf', species: ['Loup gris', 'Loup arctique', 'Louveteau', 'Loup ibérique']),
    AnimalAvatar(id: 'fox', emoji: '🦊', defaultFrenchName: 'Renard', familyId: 'fox', species: ['Renard roux', 'Fennec', 'Renard polaire', 'Goupil']),
    AnimalAvatar(id: 'raccoon', emoji: '🦝', defaultFrenchName: 'Raton laveur', familyId: 'raccoon', species: ['Raton laveur', 'Raton crabier']),
    AnimalAvatar(id: 'cat', emoji: '🐱', defaultFrenchName: 'Chaton', familyId: 'cat', species: ['Siamois', 'Persan', 'Maine coon', 'Bengal', 'Chartreux', 'Sphynx', 'Angora']),
    AnimalAvatar(id: 'lion', emoji: '🦁', defaultFrenchName: 'Lion', familyId: 'lion', species: ['Lion', 'Lionne', 'Lionceau', 'Lion d’Asie']),
    AnimalAvatar(id: 'tiger', emoji: '🐯', defaultFrenchName: 'Tigre', familyId: 'tiger', species: ['Tigre', 'Tigre blanc', 'Tigreau', 'Tigre du Bengale']),
    AnimalAvatar(id: 'leopard', emoji: '🐆', defaultFrenchName: 'Léopard', familyId: 'leopard', species: ['Léopard', 'Panthère', 'Jaguar', 'Guépard', 'Once']),
    AnimalAvatar(id: 'horse', emoji: '🐴', defaultFrenchName: 'Poney', familyId: 'horse', species: ['Pur-sang', 'Poney', 'Mustang', 'Percheron', 'Étalon']),
    AnimalAvatar(id: 'unicorn', emoji: '🦄', defaultFrenchName: 'Licorne', familyId: 'unicorn', species: ['Licorne', 'Alicorne', 'Pégase']),
    AnimalAvatar(id: 'zebra', emoji: '🦓', defaultFrenchName: 'Zèbre', familyId: 'zebra', species: ['Zèbre', 'Zèbre de plaine', 'Zébrion']),
    AnimalAvatar(id: 'deer', emoji: '🦌', defaultFrenchName: 'Cerf', familyId: 'deer', species: ['Cerf', 'Biche', 'Faon', 'Chevreuil', 'Renne', 'Wapiti', 'Élan']),
    AnimalAvatar(id: 'bison', emoji: '🦬', defaultFrenchName: 'Bison', familyId: 'bison', species: ['Bison', 'Bisonneau', 'Bison d’Europe']),
    AnimalAvatar(id: 'cow', emoji: '🐮', defaultFrenchName: 'Vache', familyId: 'cow', species: ['Vache', 'Génisse', 'Veau', 'Normande', 'Holstein', 'Salers']),
    AnimalAvatar(id: 'ox', emoji: '🐂', defaultFrenchName: 'Bœuf', familyId: 'ox', species: ['Bœuf', 'Taureau', 'Zébu', 'Buffle']),
    AnimalAvatar(id: 'pig', emoji: '🐷', defaultFrenchName: 'Cochon', familyId: 'pig', species: ['Cochon', 'Porcelet', 'Truie', 'Cochon nain']),
    AnimalAvatar(id: 'boar', emoji: '🐗', defaultFrenchName: 'Sanglier', familyId: 'boar', species: ['Sanglier', 'Marcassin', 'Laie', 'Phacochère']),
    AnimalAvatar(id: 'ram', emoji: '🐏', defaultFrenchName: 'Bélier', familyId: 'ram', species: ['Bélier', 'Mérinos', 'Mouflon']),
    AnimalAvatar(id: 'sheep', emoji: '🐑', defaultFrenchName: 'Brebis', familyId: 'sheep', species: ['Brebis', 'Agneau', 'Mouton', 'Mérinos']),
    AnimalAvatar(id: 'goat', emoji: '🐐', defaultFrenchName: 'Chèvre', familyId: 'goat', species: ['Chèvre', 'Bouc', 'Chevreau', 'Chamois', 'Bouquetin']),
    AnimalAvatar(id: 'camel', emoji: '🐫', defaultFrenchName: 'Chameau', familyId: 'camel', species: ['Chameau', 'Dromadaire', 'Chamelon']),
    AnimalAvatar(id: 'llama', emoji: '🦙', defaultFrenchName: 'Lama', familyId: 'llama', species: ['Lama', 'Alpaga', 'Vigogne', 'Guanaco']),
    AnimalAvatar(id: 'giraffe', emoji: '🦒', defaultFrenchName: 'Girafe', familyId: 'giraffe', species: ['Girafe', 'Girafon', 'Okapi']),
    AnimalAvatar(id: 'elephant', emoji: '🐘', defaultFrenchName: 'Éléphant', familyId: 'elephant', species: ['Éléphant', 'Éléphanteau', 'Éléphant d’Asie']),
    AnimalAvatar(id: 'mammoth', emoji: '🦣', defaultFrenchName: 'Mammouth', familyId: 'mammoth', species: ['Mammouth', 'Mammouth laineux']),
    AnimalAvatar(id: 'rhino', emoji: '🦏', defaultFrenchName: 'Rhinocéros', familyId: 'rhinoceros', species: ['Rhinocéros', 'Rhino blanc', 'Rhino noir']),
    AnimalAvatar(id: 'hippo', emoji: '🦛', defaultFrenchName: 'Hippopotame', familyId: 'hippopotamus', species: ['Hippopotame', 'Hippo nain']),
    AnimalAvatar(id: 'mouse', emoji: '🐭', defaultFrenchName: 'Petite souris', familyId: 'mouse', species: ['Souris', 'Mulot', 'Campagnol', 'Souris grise']),
    AnimalAvatar(id: 'rat', emoji: '🐀', defaultFrenchName: 'Rat', familyId: 'rat', species: ['Rat', 'Rat brun', 'Surmulot', 'Rat noir']),
    AnimalAvatar(id: 'hamster', emoji: '🐹', defaultFrenchName: 'Hamster', familyId: 'hamster', species: ['Hamster', 'Hamster russe', 'Hamster doré']),
    AnimalAvatar(id: 'rabbit', emoji: '🐰', defaultFrenchName: 'Petit lapin', familyId: 'rabbit', species: ['Lapin', 'Lapereau', 'Lapin nain', 'Garenne', 'Angora']),
    AnimalAvatar(id: 'hedgehog', emoji: '🦔', defaultFrenchName: 'Hérisson', familyId: 'hedgehog', species: ['Hérisson', 'Hérisson d’Europe']),
    AnimalAvatar(id: 'bat', emoji: '🦇', defaultFrenchName: 'Chauve-souris', familyId: 'bat', species: ['Chauve-souris', 'Roussette', 'Pipistrelle', 'Vampire']),
    AnimalAvatar(id: 'bear', emoji: '🐻', defaultFrenchName: 'Ours', familyId: 'bear', species: ['Ours brun', 'Grizzly', 'Ours noir', 'Ourson', 'Baribal']),
    AnimalAvatar(id: 'koala', emoji: '🐨', defaultFrenchName: 'Koala', familyId: 'koala', species: ['Koala']),
    AnimalAvatar(id: 'panda', emoji: '🐼', defaultFrenchName: 'Panda', familyId: 'panda', species: ['Panda', 'Panda géant', 'Bébé panda']),
    AnimalAvatar(id: 'sloth', emoji: '🦥', defaultFrenchName: 'Paresseux', familyId: 'sloth', species: ['Paresseux', 'Aï', 'Unau']),
    AnimalAvatar(id: 'otter', emoji: '🦦', defaultFrenchName: 'Loutre', familyId: 'otter', species: ['Loutre', 'Loutron', 'Loutre de mer']),
    AnimalAvatar(id: 'skunk', emoji: '🦨', defaultFrenchName: 'Moufette', familyId: 'skunk', species: ['Moufette', 'Mouffette']),
    AnimalAvatar(id: 'kangaroo', emoji: '🦘', defaultFrenchName: 'Kangourou', familyId: 'kangaroo', species: ['Kangourou', 'Wallaby', 'Kangourou roux']),
    AnimalAvatar(id: 'badger', emoji: '🦡', defaultFrenchName: 'Blaireau', familyId: 'badger', species: ['Blaireau', 'Blaireau d’Europe']),

    // ── Oiseaux ─────────────────────────────────────────────────────────────
    AnimalAvatar(id: 'turkey', emoji: '🦃', defaultFrenchName: 'Dinde', familyId: 'turkey', species: ['Dinde', 'Dindon', 'Dindonneau']),
    AnimalAvatar(id: 'chicken', emoji: '🐔', defaultFrenchName: 'Poule', familyId: 'chicken', species: ['Poule', 'Poulette', 'Poule rousse', 'Cocotte']),
    AnimalAvatar(id: 'rooster', emoji: '🐓', defaultFrenchName: 'Coq', familyId: 'rooster', species: ['Coq', 'Coq gaulois', 'Coquelet']),
    AnimalAvatar(id: 'chick', emoji: '🐤', defaultFrenchName: 'Poussin', familyId: 'chick', species: ['Poussin', 'Caneton', 'Oisillon']),
    AnimalAvatar(id: 'bird', emoji: '🐦', defaultFrenchName: 'Oiseau', familyId: 'bird', species: ['Bouvreuil', 'Rouge-gorge', 'Mésange', 'Moineau', 'Merle', 'Pinson', 'Hirondelle', 'Étourneau']),
    AnimalAvatar(id: 'penguin', emoji: '🐧', defaultFrenchName: 'Pingouin', familyId: 'penguin', species: ['Pingouin', 'Manchot', 'Gorfou', 'Manchot royal']),
    AnimalAvatar(id: 'eagle', emoji: '🦅', defaultFrenchName: 'Aigle', familyId: 'eagle', species: ['Aigle royal', 'Pygargue', 'Faucon pèlerin', 'Buse', 'Milan', 'Aiglon']),
    AnimalAvatar(id: 'duck', emoji: '🦆', defaultFrenchName: 'Canard', familyId: 'duck', species: ['Canard', 'Colvert', 'Caneton', 'Eider', 'Mandarin']),
    AnimalAvatar(id: 'swan', emoji: '🦢', defaultFrenchName: 'Cygne', familyId: 'swan', species: ['Cygne', 'Cygne blanc', 'Cygne noir', 'Cygneau']),
    AnimalAvatar(id: 'owl', emoji: '🦉', defaultFrenchName: 'Hibou', familyId: 'owl', species: ['Hibou', 'Chouette', 'Hulotte', 'Grand-duc', 'Effraie']),
    AnimalAvatar(id: 'flamingo', emoji: '🦩', defaultFrenchName: 'Flamant rose', familyId: 'flamingo', species: ['Flamant rose', 'Flamant']),
    AnimalAvatar(id: 'peacock', emoji: '🦚', defaultFrenchName: 'Paon', familyId: 'peacock', species: ['Paon', 'Paon bleu', 'Paon blanc']),
    AnimalAvatar(id: 'parrot', emoji: '🦜', defaultFrenchName: 'Perroquet', familyId: 'parrot', species: ['Perroquet', 'Gris du Gabon', 'Ara', 'Toucan', 'Cacatoès', 'Perruche']),

    // ── Amphibiens et reptiles ──────────────────────────────────────────────
    AnimalAvatar(id: 'frog', emoji: '🐸', defaultFrenchName: 'Grenouille', familyId: 'frog', species: ['Grenouille', 'Rainette', 'Crapaud', 'Têtard']),
    AnimalAvatar(id: 'crocodile', emoji: '🐊', defaultFrenchName: 'Crocodile', familyId: 'crocodile', species: ['Crocodile', 'Alligator', 'Caïman', 'Gavial']),
    AnimalAvatar(id: 'turtle', emoji: '🐢', defaultFrenchName: 'Tortue', familyId: 'turtle', species: ['Tortue', 'Tortue verte', 'Tortue luth', 'Caouanne']),
    AnimalAvatar(id: 'lizard', emoji: '🦎', defaultFrenchName: 'Lézard', familyId: 'lizard', species: ['Lézard', 'Gecko', 'Iguane', 'Caméléon', 'Varan', 'Agame']),
    AnimalAvatar(id: 'snake', emoji: '🐍', defaultFrenchName: 'Serpent', familyId: 'snake', species: ['Serpent', 'Cobra', 'Python', 'Vipère', 'Boa', 'Couleuvre', 'Mamba']),
    AnimalAvatar(id: 'dragon', emoji: '🐉', defaultFrenchName: 'Dragon', familyId: 'dragon', species: ['Dragon', 'Wyverne', 'Drake']),
    AnimalAvatar(id: 'trex', emoji: '🦖', defaultFrenchName: 'T-Rex', familyId: 'trex', species: ['T-Rex', 'Raptor', 'Allosaure', 'Spinosaure']),
    AnimalAvatar(id: 'sauropod', emoji: '🦕', defaultFrenchName: 'Sauropode', familyId: 'sauropod', species: ['Diplodocus', 'Brontosaure', 'Tricératops', 'Sauropode']),

    // ── Animaux marins ──────────────────────────────────────────────────────
    AnimalAvatar(id: 'whale', emoji: '🐳', defaultFrenchName: 'Baleine', familyId: 'whale', species: ['Baleine', 'Baleineau', 'Rorqual', 'Cachalot', 'Baleine bleue']),
    AnimalAvatar(id: 'dolphin', emoji: '🐬', defaultFrenchName: 'Dauphin', familyId: 'dolphin', species: ['Dauphin', 'Marsouin', 'Grand dauphin', 'Orque']),
    AnimalAvatar(id: 'seal', emoji: '🦭', defaultFrenchName: 'Phoque', familyId: 'seal', species: ['Phoque', 'Otarie', 'Morse', 'Bébé phoque']),
    AnimalAvatar(id: 'fish', emoji: '🐟', defaultFrenchName: 'Poisson', familyId: 'fish', species: ['Poisson', 'Sardine', 'Maquereau', 'Truite', 'Carpe', 'Bar', 'Dorade']),
    AnimalAvatar(id: 'blowfish', emoji: '🐡', defaultFrenchName: 'Poisson-globe', familyId: 'blowfish', species: ['Poisson-globe', 'Fugu', 'Diodon']),
    AnimalAvatar(id: 'shark', emoji: '🦈', defaultFrenchName: 'Requin', familyId: 'shark', species: ['Requin', 'Grand requin', 'Requin marteau', 'Aiguillat']),
    AnimalAvatar(id: 'octopus', emoji: '🐙', defaultFrenchName: 'Pieuvre', familyId: 'octopus', species: ['Pieuvre', 'Poulpe', 'Pieuvre bleue']),
    AnimalAvatar(id: 'crab', emoji: '🦀', defaultFrenchName: 'Crabe', familyId: 'crab', species: ['Crabe', 'Tourteau', 'Crabe vert', 'Étrille']),
    AnimalAvatar(id: 'lobster', emoji: '🦞', defaultFrenchName: 'Homard', familyId: 'lobster', species: ['Homard', 'Langouste', 'Écrevisse', 'Langoustine']),
    AnimalAvatar(id: 'shrimp', emoji: '🦐', defaultFrenchName: 'Crevette', familyId: 'shrimp', species: ['Crevette', 'Gambas', 'Crevette rose', 'Bouquet']),
    AnimalAvatar(id: 'squid', emoji: '🦑', defaultFrenchName: 'Calmar', familyId: 'squid', species: ['Calmar', 'Encornet', 'Seiche', 'Calamar']),

    // ── Insectes et petits animaux ──────────────────────────────────────────
    AnimalAvatar(id: 'snail', emoji: '🐌', defaultFrenchName: 'Escargot', familyId: 'snail', species: ['Escargot', 'Petit-gris', 'Bourgogne']),
    AnimalAvatar(id: 'butterfly', emoji: '🦋', defaultFrenchName: 'Papillon', familyId: 'butterfly', species: ['Papillon', 'Monarque', 'Machaon', 'Morpho', 'Vulcain']),
    AnimalAvatar(id: 'ant', emoji: '🐜', defaultFrenchName: 'Fourmi', familyId: 'ant', species: ['Fourmi', 'Fourmi rouge', 'Fourmi noire', 'Reine']),
    AnimalAvatar(id: 'bee', emoji: '🐝', defaultFrenchName: 'Abeille', familyId: 'bee', species: ['Abeille', 'Bourdon', 'Reine', 'Butineuse']),
    AnimalAvatar(id: 'ladybug', emoji: '🐞', defaultFrenchName: 'Coccinelle', familyId: 'ladybug', species: ['Coccinelle']),
    AnimalAvatar(id: 'cricket', emoji: '🦗', defaultFrenchName: 'Criquet', familyId: 'cricket', species: ['Criquet', 'Sauterelle', 'Grillon', 'Locuste']),
    AnimalAvatar(id: 'scorpion', emoji: '🦂', defaultFrenchName: 'Scorpion', familyId: 'scorpion', species: ['Scorpion', 'Scorpion noir', 'Scorpion jaune']),

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
