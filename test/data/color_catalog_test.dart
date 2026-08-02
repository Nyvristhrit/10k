import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/data/catalogs/color_catalog.dart';

void main() {
  test('la palette toxique couvre exactement les mêmes identifiants', () {
    // Invariant capital : une partie sauvegardée mémorise l'id de couleur de
    // chaque joueur. Si la palette trash en oubliait un, le joueur basculerait
    // sur la couleur de repli en changeant de mode.
    final ids = ColorCatalog.all.map((c) => c.id).toList();
    final toxicIds = ColorCatalog.toxic.map((c) => c.id).toList();
    expect(toxicIds, ids);
  });

  test('chaque teinte toxique a son accent et reste opaque', () {
    for (final c in ColorCatalog.toxic) {
      expect(c.accentArgb, isNotNull, reason: '${c.id} sans accent');
      expect(c.backgroundArgb >> 24 & 0xFF, 0xFF,
          reason: '${c.id} : fond non opaque');
      expect(c.foregroundArgb >> 24 & 0xFF, 0xFF,
          reason: '${c.id} : texte non opaque');
    }
  });

  test('byId bascule bien de palette', () {
    final sage = ColorCatalog.byId('ruby')!;
    final toxic = ColorCatalog.byId('ruby', toxicPalette: true)!;
    expect(toxic.id, sage.id);
    expect(toxic.backgroundArgb, isNot(sage.backgroundArgb));
  });

  test('un id inconnu reste introuvable dans les deux palettes', () {
    expect(ColorCatalog.byId('inexistant'), isNull);
    expect(ColorCatalog.byId('inexistant', toxicPalette: true), isNull);
  });
}
