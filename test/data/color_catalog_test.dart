import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/data/catalogs/color_catalog.dart';

void main() {
  test('la palette toxique couvre exactement les mêmes identifiants', () {
    // Les parties stockent l'id de couleur : la palette trash doit tous les
    // avoir.
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

  test("tileForArgb : retrouve la tuile d'une couleur de profil", () {
    // Couleur de tuile exacte.
    for (final c in ColorCatalog.all) {
      expect(ColorCatalog.tileForArgb(c.backgroundArgb).id, c.id);
    }
    // Anciennes couleurs de profil sans tuile exacte.
    expect(ColorCatalog.tileForArgb(0xFF6366F1).id, 'indigo');
    expect(ColorCatalog.tileForArgb(0xFF0EA5E9).id, 'cyan');
    // Couleur quelconque : la plus proche.
    expect(ColorCatalog.tileForArgb(0xFFFF0000).id, 'ruby');
  });
}
