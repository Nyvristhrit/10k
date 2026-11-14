import '../../data/catalogs/animal_catalog.dart';
import '../../data/catalogs/color_catalog.dart';
import '../../domain/models/color_token.dart';
import '../../domain/models/player.dart';
import '../trash/trash_taunts.dart';

/// Emoji du totem d'un joueur (avec repli si l'entrée est introuvable).
String emojiFor(Player player) =>
    AnimalCatalog.byId(player.avatarId)?.emoji ?? '❓';

/// Emoji d'un joueur en cours de partie (remplacé pour le bon dernier en mode
/// trash, voir `lastPlaceId`).
String emojiInGame(
  Player player, {
  required bool trash,
  String? shamedId,
}) =>
    trash && shamedId != null && player.id == shamedId
        ? Taunts.shameEmoji
        : emojiFor(player);

/// Couleur de tuile d'un joueur (avec repli neutre), en néon si [trash].
ColorToken colorFor(Player player, {bool trash = false}) =>
    ColorCatalog.byId(player.colorId, toxicPalette: trash) ??
    const ColorToken(
      id: 'fallback',
      backgroundArgb: 0xFF455A64,
      foregroundArgb: 0xFFFFFFFF,
    );
