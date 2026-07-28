import '../../data/catalogs/animal_catalog.dart';
import '../../data/catalogs/color_catalog.dart';
import '../../domain/models/color_token.dart';
import '../../domain/models/player.dart';

/// Emoji du totem d'un joueur (avec repli si l'entrée est introuvable).
String emojiFor(Player player) =>
    AnimalCatalog.byId(player.avatarId)?.emoji ?? '❓';

/// Couleur de tuile d'un joueur (avec repli neutre).
ColorToken colorFor(Player player) =>
    ColorCatalog.byId(player.colorId) ??
    const ColorToken(
      id: 'fallback',
      backgroundArgb: 0xFF455A64,
      foregroundArgb: 0xFFFFFFFF,
    );
