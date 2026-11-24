import 'dart:convert';

import 'package:ivhelper/core/app_update.dart';
import 'package:ivhelper/state/update_controller.dart';

/// Réponse `releases/latest` de l'API GitHub pour la version 1.0.[build].
String releaseJson(int build, {bool withApk = true}) => jsonEncode(
      <String, Object?>{
        'tag_name': 'v1.0.$build',
        'html_url': 'https://github.com/x/y/releases/tag/v1.0.$build',
        'assets': <Object?>[
          if (withApk)
            <String, String>{
              'name': 'ivhelper.apk',
              'browser_download_url':
                  'https://github.com/x/y/releases/download/v1.0.$build/ivhelper.apk',
            },
        ],
      },
    );

/// Source de mises à jour en mémoire, sans réseau ni installeur.
class FakeUpdateSource implements UpdateSource {
  /// Crée la source ; [latest] `null` simule une absence de réseau.
  FakeUpdateSource({this.latest, this.failInstall = false});

  /// Réponse de l'API, ou `null` hors ligne.
  String? latest;

  /// Vrai pour simuler un téléchargement en échec.
  bool failInstall;

  /// Versions dont l'installation a été lancée.
  final List<AppRelease> installed = <AppRelease>[];

  @override
  Future<String> latestReleaseJson() async {
    final l = latest;
    if (l == null) throw Exception('hors ligne');
    return l;
  }

  @override
  Future<void> downloadAndInstall(
    AppRelease release,
    void Function(double progress) onProgress,
  ) async {
    onProgress(0.5);
    if (failInstall) throw Exception('échec');
    onProgress(1);
    installed.add(release);
  }

  @override
  Future<void> openInBrowser(Uri url) async {}
}
