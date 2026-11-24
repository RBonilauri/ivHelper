import 'package:flutter/foundation.dart';

import '../core/meta.dart';
import '../settings/settings_controller.dart';

/// D'où vient la méta : copie incluse dans l'app et version en ligne.
abstract interface class MetaSource {
  /// Contenu de `assets/meta.json` inclus dans l'app.
  Future<String> bundled();

  /// Contenu de la dernière méta publiée sur le dépôt.
  Future<String> fetch();
}

/// État de l'onglet Méta : la plus récente des méta incluse, en cache ou en
/// ligne.
class MetaController extends ChangeNotifier {
  /// Crée le contrôleur.
  MetaController({required this.source, required this.store});

  /// Source de la méta.
  final MetaSource source;

  /// Cache de la dernière méta téléchargée.
  final SettingsStore store;

  MetaData? _data;
  bool _refreshing = false;
  String? _message;
  Future<void>? _loading;
  bool _disposed = false;

  /// Méta affichée, ou `null` avant le premier chargement.
  MetaData? get data => _data;

  /// Vrai pendant une vérification en ligne.
  bool get refreshing => _refreshing;

  /// Message d'état de la dernière vérification, ou `null`.
  String? get message => _message;

  /// Charge la méta locale puis vérifie en ligne, une seule fois.
  Future<void> ensureLoaded() => _loading ??= _loadThenRefresh();

  Future<void> _loadThenRefresh() async {
    _consider(await _tryParse(source.bundled));
    final cached = await store.readMeta();
    if (cached != null) _consider(_parse(cached));
    _notify();
    await refresh();
  }

  /// Vérifie en ligne si une méta plus récente est publiée.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _message = null;
    _notify();
    final previous = _data;
    String? raw;
    try {
      raw = await source.fetch();
    } on Object {
      raw = null;
    }
    final remote = raw == null ? null : _parse(raw);
    if (remote == null) {
      _message = previous == null
          ? 'Méta indisponible : vérifie ta connexion.'
          : 'Hors ligne : méta du ${previous.updatedFr} conservée.';
    } else {
      _consider(remote);
      if (identical(_data, remote)) await store.writeMeta(raw!);
      _message = previous != null && remote.isNewerThan(previous)
          ? 'Nouvelle méta du ${remote.updatedFr}.'
          : 'Méta à jour.';
    }
    _refreshing = false;
    _notify();
  }

  void _consider(MetaData? candidate) {
    if (candidate == null) return;
    final current = _data;
    if (current == null || !current.isNewerThan(candidate)) _data = candidate;
  }

  static Future<MetaData?> _tryParse(Future<String> Function() read) async {
    try {
      return _parse(await read());
    } on Object {
      return null;
    }
  }

  static MetaData? _parse(String raw) {
    try {
      return MetaData.fromJson(raw);
    } on FormatException {
      return null;
    }
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
