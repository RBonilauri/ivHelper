import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'game_data_controller.dart';

/// Dossier des données publiées chaque jour par la tâche planifiée du dépôt.
const String gameDataBaseUrl =
    'https://raw.githubusercontent.com/RBonilauri/ivHelper/main/assets';

/// Données du jeu incluses dans l'appli et téléchargées depuis GitHub.
class HttpGameDataSource implements GameDataSource {
  /// Crée la source.
  const HttpGameDataSource();

  @override
  Future<String> bundledVersion() =>
      rootBundle.loadString('assets/game_data_version.json');

  @override
  Future<String> bundledSpecies() => rootBundle.loadString('assets/species.json');

  @override
  Future<String> bundledMoves() => rootBundle.loadString('assets/moves.json');

  @override
  Future<String> fetchVersion() => _get('game_data_version.json');

  @override
  Future<String> fetchSpecies() => _get('species.json');

  @override
  Future<String> fetchMoves() => _get('moves.json');

  Future<String> _get(String name) async {
    final response = await http
        .get(Uri.parse('$gameDataBaseUrl/$name'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }
}
