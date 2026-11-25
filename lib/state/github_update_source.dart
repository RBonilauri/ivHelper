import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ivhelper_capture/ivhelper_capture.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_update.dart';
import 'update_controller.dart';

/// Dernière Release du dépôt, publiée par la CI à chaque fusion dans main.
final Uri latestReleaseUrl = Uri.parse(
  'https://api.github.com/repos/RBonilauri/ivHelper/releases/latest',
);

/// Versions publiées sur GitHub, installées par l'installeur d'Android.
class GitHubUpdateSource implements UpdateSource {
  /// Crée la source.
  const GitHubUpdateSource();

  @override
  Future<String> latestReleaseJson() async {
    final response = await http.get(
      latestReleaseUrl,
      headers: const <String, String>{
        'Accept': 'application/vnd.github+json',
      },
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    return response.body;
  }

  @override
  Future<void> downloadAndInstall(
    AppRelease release,
    void Function(double progress) onProgress,
  ) async {
    final client = http.Client();
    final file = File(
      '${Directory.systemTemp.path}/ivhelper-${release.versionName}.apk',
    );
    try {
      final response = await client.send(http.Request('GET', release.apkUrl));
      if (response.statusCode != 200) {
        throw http.ClientException('HTTP ${response.statusCode}');
      }
      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress(received / total);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
    onProgress(1);
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw StateError('installeur : ${result.message}');
    }
  }

  @override
  Future<void> leaveForInstaller() => IvhelperCapture.closeTask();

  @override
  Future<void> openInBrowser(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) throw StateError('navigateur indisponible');
  }
}
