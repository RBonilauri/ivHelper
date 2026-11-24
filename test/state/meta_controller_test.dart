import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/meta.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:ivhelper/state/meta_controller.dart';

import '../support/fake_meta.dart';

void main() {
  test('fromJson lit les ligues, les attaques et les matchs', () {
    final data = MetaData.fromJson(fakeMetaJson());
    final first = data.leagues[MetaLeague.great]!.single;
    expect(first.name, 'Flambusard');
    expect(first.types, <PokeType>[PokeType.fire, PokeType.flying]);
    expect(first.fast.nameFr, 'Calcination');
    expect(first.charged.single.type, PokeType.flying);
    expect(first.worstMatchups, <String>['Altaria']);
    expect(data.leagues[MetaLeague.master], isEmpty);
    expect(data.updatedFr, '20/11/2026');
  });

  test('fromJson refuse un contenu illisible', () {
    expect(() => MetaData.fromJson('{"leagues": 3}'), throwsFormatException);
    expect(() => MetaData.fromJson('pas du json'), throwsFormatException);
  });

  test('une méta en ligne plus récente remplace la copie et va en cache',
      () async {
    final store = MemorySettingsStore();
    final c = MetaController(
      source: FakeMetaSource(
        local: fakeMetaJson(),
        remote: fakeMetaJson(updated: '2026-11-24', name: 'Nouveau'),
      ),
      store: store,
    );
    await c.ensureLoaded();
    expect(c.data!.updated, '2026-11-24');
    expect(c.message, 'Nouvelle méta du 24/11/2026.');
    expect(await store.readMeta(), contains('Nouveau'));
  });

  test('hors ligne, la copie incluse reste affichée', () async {
    final c = MetaController(
      source: FakeMetaSource(local: fakeMetaJson()),
      store: MemorySettingsStore(),
    );
    await c.ensureLoaded();
    expect(c.data!.updated, '2026-11-20');
    expect(c.message, 'Hors ligne : méta du 20/11/2026 conservée.');
  });

  test('le cache plus récent que la copie incluse est utilisé hors ligne',
      () async {
    final store = MemorySettingsStore();
    await store.writeMeta(fakeMetaJson(updated: '2026-11-22'));
    final c = MetaController(
      source: FakeMetaSource(local: fakeMetaJson()),
      store: store,
    );
    await c.ensureLoaded();
    expect(c.data!.updated, '2026-11-22');
  });

  test('une méta en ligne plus ancienne ne remplace pas le cache', () async {
    final store = MemorySettingsStore();
    await store.writeMeta(fakeMetaJson(updated: '2026-11-22'));
    final c = MetaController(
      source: FakeMetaSource(local: fakeMetaJson(), remote: fakeMetaJson()),
      store: store,
    );
    await c.ensureLoaded();
    expect(c.data!.updated, '2026-11-22');
    expect(c.message, 'Méta à jour.');
  });

  test('ensureLoaded ne vérifie en ligne qu\'une fois', () async {
    final source = FakeMetaSource(local: fakeMetaJson(), remote: fakeMetaJson());
    final c = MetaController(source: source, store: MemorySettingsStore());
    await c.ensureLoaded();
    await c.ensureLoaded();
    expect(source.fetches, 1);
  });
}
