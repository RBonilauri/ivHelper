import 'dart:convert';

/// Numéro de build de cette app, fixé par la CI (`--dart-define=BUILD_NUMBER`).
/// Vaut 0 pour une compilation locale.
const int currentBuildNumber = int.fromEnvironment('BUILD_NUMBER');

/// Nom de version fixé par la CI (`--dart-define=VERSION_NAME`, ex. `1.1.52`).
const String currentVersionName = String.fromEnvironment('VERSION_NAME');

/// Une version publiée sur GitHub (Release) avec son APK.
class AppRelease {
  /// Crée une version.
  const AppRelease({
    required this.buildNumber,
    required this.versionName,
    required this.apkUrl,
    required this.pageUrl,
  });

  /// Numéro de build (croissant d'une version à l'autre).
  final int buildNumber;

  /// Nom de version affiché (par exemple `1.0.42`).
  final String versionName;

  /// Adresse de téléchargement de l'APK.
  final Uri apkUrl;

  /// Page de la Release sur GitHub.
  final Uri pageUrl;

  /// Vrai si cette version est plus récente que le build [current].
  bool isNewerThan(int current) => buildNumber > current;
}

/// Lit la réponse de l'API GitHub `releases/latest`.
///
/// Renvoie `null` si elle n'a pas d'étiquette `vX.Y.N` ou pas d'APK.
AppRelease? parseLatestRelease(String source) {
  final Object? root;
  try {
    root = jsonDecode(source);
  } on FormatException {
    return null;
  }
  if (root is! Map<String, dynamic>) return null;
  final tag = root['tag_name'];
  final page = root['html_url'];
  final assets = root['assets'];
  if (tag is! String || assets is! List<dynamic>) return null;
  final match = RegExp(r'^v?(\d+\.\d+\.(\d+))$').firstMatch(tag);
  if (match == null) return null;
  String? apk;
  for (final a in assets) {
    if (a is! Map<String, dynamic>) continue;
    final name = a['name'];
    final url = a['browser_download_url'];
    if (name is String && name.endsWith('.apk') && url is String) {
      apk = url;
      break;
    }
  }
  if (apk == null) return null;
  return AppRelease(
    buildNumber: int.parse(match.group(2)!),
    versionName: match.group(1)!,
    apkUrl: Uri.parse(apk),
    pageUrl: Uri.parse(page is String ? page : apk),
  );
}
