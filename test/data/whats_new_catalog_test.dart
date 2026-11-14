import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/data/catalogs/whats_new_catalog.dart';

void main() {
  group('WhatsNewCatalog', () {
    test('since() ne retient que les versions strictement postérieures', () {
      final since = WhatsNewCatalog.since('1.2.0');
      expect(since.any((r) => r.version == '1.1.0'), false);
      expect(since.any((r) => r.version == '1.2.0'), false);
      expect(since.any((r) => r.version == '1.3.0'), true);
    });

    test('since() de la version la plus récente ne retourne rien', () {
      final latest = WhatsNewCatalog.releases.last.version;
      expect(WhatsNewCatalog.since(latest), isEmpty);
    });

    test('since() garde l\'ordre chronologique (plus ancien en premier)', () {
      final since = WhatsNewCatalog.since('1.2.0');
      final versions = since.map((r) => r.version).toList();
      expect(versions, [for (final r in since) r.version]);
      expect(versions.first, '1.3.0');
      expect(versions.last, WhatsNewCatalog.releases.last.version);
    });

    test('since() compare les nombres, pas le texte (1.9.0 avant 1.10.0)',
        () {
      // En comparaison textuelle, "1.10.0" < "1.9.0" ; numériquement non.
      expect(WhatsNewCatalog.since('1.9.0'), isEmpty);
      expect(WhatsNewCatalog.since('1.3.9'), contains(
          WhatsNewCatalog.releases.firstWhere((r) => r.version == '1.4.0')));
    });

    test('aucune version en double', () {
      final versions = WhatsNewCatalog.releases.map((r) => r.version);
      expect(versions.toSet().length, versions.length);
    });
  });
}
