import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'meta_controller.dart';

/// Adresse de la méta publiée chaque jour par la tâche planifiée du dépôt.
const String metaUrl =
    'https://raw.githubusercontent.com/RBonilauri/ivHelper/main/assets/meta.json';

/// Méta incluse dans l'app et téléchargée depuis GitHub.
class HttpMetaSource implements MetaSource {
  /// Crée la source.
  const HttpMetaSource();

  @override
  Future<String> bundled() => rootBundle.loadString('assets/meta.json');

  @override
  Future<String> fetch() async {
    final response = await http
        .get(Uri.parse(metaUrl))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }
}
