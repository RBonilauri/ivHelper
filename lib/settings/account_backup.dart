import 'dart:convert';

import 'settings_controller.dart';

/// Version du format de sauvegarde ; une sauvegarde d'un format plus récent
/// est refusée plutôt que mal relue.
const int accountFormat = 1;

/// Sauvegarde refusée, avec un message à montrer tel quel.
class AccountImportException implements Exception {
  /// Crée l'erreur.
  const AccountImportException(this.message);

  /// Explication en français.
  final String message;

  @override
  String toString() => message;
}

/// Ce qu'une sauvegarde importée contenait.
class AccountSummary {
  /// Crée le résumé.
  const AccountSummary({required this.pokemonCount});

  /// Nombre de Pokémon de la collection importée.
  final int pokemonCount;
}

/// Nom du fichier de sauvegarde du jour [now].
String accountFileName(DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'ivhelper-compte-${now.year}-${two(now.month)}-${two(now.day)}.json';
}

/// Exporte le compte (réglages d'affichage, collection, équipe, dernières
/// recherches) en JSON lisible. La méta en cache n'est pas exportée : elle
/// se télécharge à nouveau.
Future<String> exportAccount(SettingsStore store, {required DateTime now}) async {
  Object? decoded(String? raw) => raw == null ? null : jsonDecode(raw);
  final data = <String, Object?>{
    'app': 'ivHelper',
    'format': accountFormat,
    'exportedAt': now.toUtc().toIso8601String(),
    'themeMode': await store.readThemeMode(),
    'fontScale': await store.readFontScale(),
    'collection': decoded(await store.readCollection()) ?? <Object?>[],
    'team': decoded(await store.readTeam()),
    'history': decoded(await store.readHistory()),
  }..removeWhere((_, v) => v == null);
  return const JsonEncoder.withIndent('  ').convert(data);
}

/// Vérifie la sauvegarde [text] sans rien écrire ; lève
/// [AccountImportException] si elle est refusée.
AccountSummary previewAccount(String text) => _parse(text).summary;

/// Remplace le compte de [store] par la sauvegarde [text]. Tout est vérifié
/// avant d'écrire : un fichier refusé ne modifie rien.
Future<AccountSummary> importAccount(SettingsStore store, String text) async {
  final backup = _parse(text);
  final themeMode = backup.themeMode;
  final fontScale = backup.fontScale;
  if (themeMode != null) await store.writeThemeMode(themeMode);
  if (fontScale != null) await store.writeFontScale(fontScale);
  final collection = backup.collection;
  if (collection != null) await store.writeCollection(jsonEncode(collection));
  final team = backup.team;
  if (team != null) await store.writeTeam(jsonEncode(team));
  final history = backup.history;
  if (history != null) await store.writeHistory(jsonEncode(history));
  return backup.summary;
}

typedef _Backup = ({
  String? themeMode,
  double? fontScale,
  List<Object?>? collection,
  Object? team,
  List<Object?>? history,
  AccountSummary summary,
});

_Backup _parse(String text) {
  const notBackup = "Ce fichier n'est pas une sauvegarde ivHelper.";
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw const AccountImportException(notBackup);
  }
  if (decoded is! Map<String, Object?> || decoded['app'] != 'ivHelper') {
    throw const AccountImportException(notBackup);
  }
  final format = decoded['format'];
  if (format is! int) throw const AccountImportException(notBackup);
  if (format > accountFormat) {
    throw const AccountImportException(
      'Sauvegarde faite par une version plus récente : mets ivHelper à jour.',
    );
  }

  final collection = decoded['collection'];
  if (collection != null && collection is! List<Object?>) {
    throw const AccountImportException(
      'Sauvegarde abîmée : collection illisible.',
    );
  }
  final team = decoded['team'];
  final history = decoded['history'];
  if (history != null && history is! List<Object?>) {
    throw const AccountImportException(
      'Sauvegarde abîmée : recherches illisibles.',
    );
  }
  final themeMode = decoded['themeMode'];
  final fontScale = decoded['fontScale'];
  final entries = collection is List<Object?> ? collection : null;
  return (
    themeMode: themeMode is String ? themeMode : null,
    fontScale: fontScale is num ? fontScale.toDouble() : null,
    collection: entries,
    team: team,
    history: history is List<Object?> ? history : null,
    summary: AccountSummary(pokemonCount: entries?.length ?? 0),
  );
}
