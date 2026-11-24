import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/app_update.dart';
import 'package:ivhelper/state/update_controller.dart';

import '../support/fake_update.dart';

void main() {
  test('parseLatestRelease lit le numéro de build et l\'APK', () {
    final r = parseLatestRelease(releaseJson(42))!;
    expect(r.buildNumber, 42);
    expect(r.versionName, '1.0.42');
    expect(r.apkUrl.path, endsWith('/ivhelper.apk'));
    expect(r.isNewerThan(41), isTrue);
    expect(r.isNewerThan(42), isFalse);
  });

  test('parseLatestRelease refuse une Release sans APK ou mal étiquetée', () {
    expect(parseLatestRelease(releaseJson(3, withApk: false)), isNull);
    expect(parseLatestRelease('{"tag_name":"latest","assets":[]}'), isNull);
    expect(parseLatestRelease('pas du json'), isNull);
  });

  test('une version plus récente est proposée puis installée', () async {
    final source = FakeUpdateSource(latest: releaseJson(12));
    final c = UpdateController(source: source, currentBuild: 10);
    await c.check();
    expect(c.showBanner, isTrue);
    expect(c.message, 'Version 1.0.12 disponible.');
    await c.install();
    expect(source.installed.single.buildNumber, 12);
    expect(c.progress, 1);
    expect(c.downloading, isFalse);
  });

  test('même version : rien à proposer', () async {
    final c = UpdateController(
      source: FakeUpdateSource(latest: releaseJson(10)),
      currentBuild: 10,
    );
    await c.check();
    expect(c.available, isNull);
    expect(c.message, 'ivHelper est à jour.');
  });

  test('hors ligne ou échec du téléchargement : message et repli', () async {
    final offline = UpdateController(
      source: FakeUpdateSource(),
      currentBuild: 10,
    );
    await offline.check();
    expect(offline.message, 'Impossible de vérifier : vérifie ta connexion.');

    final failing = UpdateController(
      source: FakeUpdateSource(latest: releaseJson(11), failInstall: true),
      currentBuild: 10,
    );
    await failing.check();
    await failing.install();
    expect(
      failing.message,
      'Le téléchargement a échoué. Essaie via le navigateur.',
    );
    expect(failing.showBanner, isTrue);
  });

  test('« Plus tard » masque la bannière', () async {
    final c = UpdateController(
      source: FakeUpdateSource(latest: releaseJson(11)),
      currentBuild: 10,
    );
    await c.check();
    c.dismiss();
    expect(c.showBanner, isFalse);
    expect(c.available, isNotNull);
  });
}
