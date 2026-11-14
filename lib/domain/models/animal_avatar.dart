import 'package:equatable/equatable.dart';

import '../../l10n/l10n.dart';

/// Un totem animal attribuable à un joueur. L'`emoji` peut compter plusieurs
/// points de code : ne jamais le découper.
class AnimalAvatar extends Equatable {
  const AnimalAvatar({
    required this.id,
    required this.emoji,
    required this.defaultFrenchName,
    this.defaultEnglishName,
    required this.familyId,
    this.species = const <String>[],
    this.speciesEn = const <String>[],
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

  /// Nom anglais par défaut (ex. « Penguin »).
  final String? defaultEnglishName;

  /// Nom par défaut dans la langue de l'interface.
  String get defaultName =>
      L10n.isEnglish ? (defaultEnglishName ?? defaultFrenchName) : defaultFrenchName;

  /// Regroupe les variantes proches d'une même espèce (ex. tous les chats → `cat`).
  final String familyId;

  /// Espèces courtes pour ce totem, tirées comme nom de joueur (ex. Bouvreuil
  /// pour l'oiseau). Vide : on utilise [defaultFrenchName].
  final List<String> species;

  /// Les mêmes espèces, en anglais.
  final List<String> speciesEn;

  /// Les espèces dans la langue de l'interface.
  List<String> get localizedSpecies =>
      L10n.isEnglish && speciesEn.isNotEmpty ? speciesEn : species;

  /// Version Unicode d'introduction, si connue (pour la compatibilité d'affichage).
  final String? unicodeVersion;

  /// Emoji de secours pour les appareils qui ne rendraient pas l'emoji récent.
  final String? fallbackEmoji;

  /// `false` pour les symboles jamais tirés comme totem.
  final bool eligibleForRandomDraw;

  @override
  List<Object?> get props => [id];
}
