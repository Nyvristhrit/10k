import '../../data/catalogs/animal_catalog.dart';
import '../../data/catalogs/color_catalog.dart';
import '../../domain/models/color_token.dart';
import '../../domain/models/player.dart';
import '../trash/trash_taunts.dart';

/// Emoji du totem d'un joueur (avec repli si l'entrée est introuvable).
String emojiFor(Player player) =>
    AnimalCatalog.byId(player.avatarId)?.emoji ?? '❓';

/// Emoji d'un joueur **en cours de partie**.
///
/// En mode trash, le bon dernier se voit confisquer son animal au profit d'un
/// 💩 : c'est le bonnet d'âne de la table (voir `lastPlaceId`). Partout ailleurs
/// — et dans toute l'appli en mode normal — le totem reste celui du joueur.
String emojiInGame(
  Player player, {
  required bool trash,
  String? shamedId,
}) =>
    trash && shamedId != null && player.id == shamedId
        ? Taunts.shameEmoji
        : emojiFor(player);

/// Couleur de tuile d'un joueur (avec repli neutre).
///
/// En mode [trash], on pioche dans la palette acide : le joueur garde sa
/// famille de couleur, mais en version néon.
ColorToken colorFor(Player player, {bool trash = false}) =>
    ColorCatalog.byId(player.colorId, toxicPalette: trash) ??
    const ColorToken(
      id: 'fallback',
      backgroundArgb: 0xFF455A64,
      foregroundArgb: 0xFFFFFFFF,
    );
