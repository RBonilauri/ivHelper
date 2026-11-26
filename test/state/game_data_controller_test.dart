import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/game_data.dart';
import 'package:ivhelper/settings/settings_controller.dart';
import 'package:ivhelper/state/game_data_controller.dart';

import '../support/fake_game_data.dart';

GameDataController _controller(
  FakeGameDataSource source, [
  MemorySettingsStore? store,
]) =>
    GameDataController(source: source, store: store ?? MemorySettingsStore());

void main() {
  test('sans cache : les données incluses', () async {
    final c = _controller(FakeGameDataSource());
    await c.load();
    expect(c.current.updated, '2026-11-20');
    expect(c.current.species.findByName('Flambusard')!.base.atk, 176);
  });

  test('cache plus récent utilisé, plus ancien ou abîmé ignoré', () async {
    final store = MemorySettingsStore();
    await store.writeGameData(
      encodeGameDataCache(
        updated: '2026-11-25',
        speciesJson: speciesJson(atk: 190),
        movesJson: movesJson(),
      ),
    );
    final newer = _controller(FakeGameDataSource(), store);
    await newer.load();
    expect(newer.current.updated, '2026-11-25');
    expect(newer.current.species.findByName('Flambusard')!.base.atk, 190);

    // Une mise à jour de l'appli apporte des données plus récentes que le cache.
    final older = _controller(FakeGameDataSource(bundledUpdated: '2026-11-26'), store);
    await older.load();
    expect(older.current.updated, '2026-11-26');

    await store.writeGameData('abîmé');
    final broken = _controller(FakeGameDataSource(), store);
    await broken.load();
    expect(broken.current.updated, '2026-11-20');
  });

  test('version en ligne plus récente : téléchargée, gardée, appliquée ensuite', () async {
    final store = MemorySettingsStore();
    final c = _controller(FakeGameDataSource(remoteUpdated: '2026-11-27'), store);
    await c.load();
    expect(await c.refresh(), isTrue);
    // Rien ne change sous les yeux : la nouvelle version attend.
    expect(c.current.updated, '2026-11-20');
    expect(c.pending!.updated, '2026-11-27');
    expect(decodeGameDataCache((await store.readGameData())!).updated, '2026-11-27');
    var notified = 0;
    c.addListener(() => notified++);
    expect(c.applyPending(), isTrue);
    expect(c.current.updated, '2026-11-27');
    expect(c.current.species.findByName('Flambusard')!.base.atk, 200);
    expect(c.current.moves['INCINERATE']!.nameFr, 'Calcination+');
    expect(c.pending, isNull);
    expect(notified, 1);
    expect(c.applyPending(), isFalse);
  });

  test('même version : rien à télécharger', () async {
    final source = FakeGameDataSource(remoteUpdated: '2026-11-20');
    final c = _controller(source);
    await c.load();
    expect(await c.refresh(), isFalse);
    expect(source.speciesFetches, 0);
    expect(c.pending, isNull);
  });

  test('hors ligne, données abîmées ou tronquées : on garde l\'actuel', () async {
    for (final source in <FakeGameDataSource>[
      FakeGameDataSource(),
      FakeGameDataSource(remoteUpdated: '2026-11-27', remoteSpecies: 'oups'),
      // Bien moins d'espèces que l'actuel : téléchargement incomplet.
      FakeGameDataSource(remoteUpdated: '2026-11-27', remoteSpecies: speciesJson(count: 1)),
    ]) {
      final store = MemorySettingsStore();
      final c = _controller(source, store);
      await c.load();
      expect(await c.refresh(), isFalse);
      expect(c.pending, isNull);
      expect(await store.readGameData(), isNull);
      expect(c.current.updated, '2026-11-20');
    }
  });
}
