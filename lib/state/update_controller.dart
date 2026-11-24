import 'package:flutter/foundation.dart';

import '../core/app_update.dart';

/// Accès aux versions publiées et à l'installeur d'Android.
abstract interface class UpdateSource {
  /// Réponse de l'API GitHub pour la dernière Release.
  Future<String> latestReleaseJson();

  /// Télécharge l'APK de [release] puis ouvre l'installeur d'Android.
  ///
  /// [onProgress] reçoit l'avancement entre 0 et 1.
  Future<void> downloadAndInstall(
    AppRelease release,
    void Function(double progress) onProgress,
  );

  /// Ouvre [url] dans le navigateur.
  Future<void> openInBrowser(Uri url);
}

/// État de la mise à jour de l'app.
class UpdateController extends ChangeNotifier {
  /// Crée le contrôleur pour l'app de build [currentBuild].
  UpdateController({required this.source, required this.currentBuild});

  /// Source des versions.
  final UpdateSource source;

  /// Numéro de build de l'app installée (0 en compilation locale).
  final int currentBuild;

  AppRelease? _available;
  bool _checking = false;
  bool _downloading = false;
  double _progress = 0;
  String? _message;
  bool _dismissed = false;
  bool _disposed = false;

  /// Version plus récente disponible, ou `null`.
  AppRelease? get available => _available;

  /// Vrai si la bannière de mise à jour doit s'afficher.
  bool get showBanner => _available != null && !_dismissed;

  /// Vrai pendant la vérification.
  bool get checking => _checking;

  /// Vrai pendant le téléchargement.
  bool get downloading => _downloading;

  /// Avancement du téléchargement, de 0 à 1.
  double get progress => _progress;

  /// Message de la dernière opération, ou `null`.
  String? get message => _message;

  /// Version installée, pour l'affichage.
  String get currentVersion =>
      currentBuild == 0 ? 'développement' : '1.0.$currentBuild';

  /// Cherche une version plus récente.
  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    _message = null;
    _notify();
    try {
      final release = parseLatestRelease(await source.latestReleaseJson());
      if (release != null && release.isNewerThan(currentBuild)) {
        _available = release;
        _dismissed = false;
        _message = 'Version ${release.versionName} disponible.';
      } else {
        _available = null;
        _message = 'ivHelper est à jour.';
      }
    } on Object {
      _message = 'Impossible de vérifier : vérifie ta connexion.';
    }
    _checking = false;
    _notify();
  }

  /// Télécharge et installe la version disponible.
  Future<void> install() async {
    final release = _available;
    if (release == null || _downloading) return;
    _downloading = true;
    _progress = 0;
    _message = null;
    _notify();
    try {
      await source.downloadAndInstall(release, (p) {
        _progress = p;
        _notify();
      });
      _message = 'Confirme l\'installation dans la fenêtre d\'Android.';
    } on Object {
      _message = 'Le téléchargement a échoué. Essaie via le navigateur.';
    }
    _downloading = false;
    _notify();
  }

  /// Ouvre la page de la version disponible dans le navigateur.
  Future<void> openInBrowser() async {
    final release = _available;
    if (release == null) return;
    await source.openInBrowser(release.apkUrl);
  }

  /// Masque la bannière jusqu'à la prochaine vérification.
  void dismiss() {
    _dismissed = true;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
