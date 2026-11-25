import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/settings/account_backup.dart';
import 'package:ivhelper/settings/settings_controller.dart';

Future<MemorySettingsStore> _filled() async {
  final store = MemorySettingsStore();
  await store.writeThemeMode('dark');
  await store.writeFontScale(1.15);
  await store.writeCollection(jsonEncode(<Object?>[
    <String, Object?>{'id': 'a1', 'speciesName': 'Flambusard'},
  ]));
  await store.writeTeam(jsonEncode(<Object?>[
    <String, Object?>{'species': 'Altaria'},
  ]));
  await store.writeHistory(jsonEncode(<String>['Flambusard']));
  await store.writeMeta('{"updated":"2026-11-20"}');
  return store;
}

void main() {
  final now = DateTime.utc(2026, 11, 25, 13, 40);

  test("l'export contient tout le compte, sans la méta en cache", () async {
    final json = jsonDecode(
      await exportAccount(await _filled(), now: now),
    ) as Map<String, Object?>;
    expect(json['app'], 'ivHelper');
    expect(json['format'], 1);
    expect(json['exportedAt'], '2026-11-25T13:40:00.000Z');
    expect(json['themeMode'], 'dark');
    expect(json['fontScale'], 1.15);
    expect((json['collection']! as List<Object?>).single, <String, Object?>{
      'id': 'a1',
      'speciesName': 'Flambusard',
    });
    expect(json['team'], isA<List<Object?>>());
    expect(json['history'], <Object?>['Flambusard']);
    expect(json.containsKey('meta'), isFalse);
  });

  test("l'import restaure le compte exporté", () async {
    final text = await exportAccount(await _filled(), now: now);
    final target = MemorySettingsStore();
    final summary = await importAccount(target, text);
    expect(summary.pokemonCount, 1);
    expect(await target.readThemeMode(), 'dark');
    expect(await target.readFontScale(), 1.15);
    expect(jsonDecode((await target.readCollection())!), hasLength(1));
    expect(jsonDecode((await target.readTeam())!), hasLength(1));
    expect(jsonDecode((await target.readHistory())!), <Object?>['Flambusard']);
  });

  test('un fichier invalide est refusé sans rien modifier', () async {
    final target = await _filled();
    final before = await target.readCollection();
    for (final (text, message) in <(String, String)>[
      ('pas du json', "Ce fichier n'est pas une sauvegarde ivHelper."),
      ('{"app": "autre", "format": 1}', "Ce fichier n'est pas une sauvegarde ivHelper."),
      (
        '{"app": "ivHelper", "format": 2}',
        'Sauvegarde faite par une version plus récente : mets ivHelper à jour.',
      ),
      (
        '{"app": "ivHelper", "format": 1, "collection": {"x": 1}}',
        'Sauvegarde abîmée : collection illisible.',
      ),
    ]) {
      await expectLater(
        importAccount(target, text),
        throwsA(
          isA<AccountImportException>().having((e) => e.message, 'message', message),
        ),
      );
    }
    expect(await target.readCollection(), before);
  });

  test('le nom du fichier porte la date', () {
    expect(accountFileName(now), 'ivhelper-compte-2026-11-25.json');
  });
}
