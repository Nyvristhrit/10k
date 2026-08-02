import 'package:equatable/equatable.dart';

/// Un totem animal attribuable à un joueur (§24.2).
///
/// L'`id` est stable et indépendant du nom affiché : renommer un joueur ne
/// modifie jamais l'entrée du catalogue. L'`emoji` peut être une séquence
/// Unicode composée de plusieurs points de code — ne jamais la découper.
class AnimalAvatar extends Equatable {
  const AnimalAvatar({
    required this.id,
    required this.emoji,
    required this.defaultFrenchName,
    required this.familyId,
    this.species = const <String>[],
    this.unicodeVersion,
    this.fallbackEmoji,
    this.eligibleForRandomDraw = true,
  });

  /// Identifiant technique unique et stable (ex. `penguin`).
  final String id;

  /// L'emoji, éventuellement multi-codepoints (ex. `🐕‍🦺`).
  final String emoji;

  /// Nom français par défaut (ex. « Pingouin »).
  final String defaultFrenchName;

  /// Regroupe les variantes proches d'une même espèce (ex. tous les chats → `cat`).
  final String familyId;

  /// Espèces concrètes et courtes possibles pour ce totem (ex. pour l'oiseau :
  /// Bouvreuil, Mésange…). Le nom d'un joueur est tiré ici à sa création ; si la
  /// liste est vide, on retombe sur [defaultFrenchName].
  final List<String> species;

  /// Version Unicode d'introduction, si connue (pour la compatibilité d'affichage).
  final String? unicodeVersion;

  /// Emoji de secours pour les appareils qui ne rendraient pas l'emoji récent.
  final String? fallbackEmoji;

  /// `false` pour les symboles conservés mais jamais tirés comme totem (§6.4).
  final bool eligibleForRandomDraw;

  @override
  List<Object?> get props => [id];
}
