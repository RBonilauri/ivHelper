import 'dart:convert';

import 'package:ivhelper/state/meta_controller.dart';

/// Méta minimale : Flambusard en tête de la ligue super.
String fakeMetaJson({String updated = '2026-11-20', String name = 'Flambusard'}) =>
    jsonEncode(<String, Object?>{
      'updated': updated,
      'source': 'PvPoke',
      'leagues': <String, Object?>{
        'great': <Object?>[
          <String, Object?>{
            'rank': 1,
            'name': name,
            'species': 'Flambusard',
            'shadow': false,
            'types': <String>['fire', 'flying'],
            'score': 91.5,
            'fast': <String, String>{
              'id': 'INCINERATE',
              'name': 'Calcination',
              'type': 'fire',
            },
            'charged': <Object?>[
              <String, String>{
                'id': 'BRAVE_BIRD',
                'name': 'Rapace',
                'type': 'flying',
              },
            ],
            'bestMatchups': <String>['Florges'],
            'worstMatchups': <String>['Altaria'],
          },
        ],
        'ultra': <Object?>[],
        'master': <Object?>[],
      },
    });

/// Source de méta en mémoire, sans réseau.
class FakeMetaSource implements MetaSource {
  /// Crée la source ; [remote] `null` simule une absence de réseau.
  FakeMetaSource({required this.local, this.remote});

  /// Méta incluse dans l'app.
  final String local;

  /// Méta en ligne, ou `null` hors ligne.
  String? remote;

  /// Nombre d'appels au réseau.
  int fetches = 0;

  @override
  Future<String> bundled() async => local;

  @override
  Future<String> fetch() async {
    fetches++;
    final r = remote;
    if (r == null) throw Exception('hors ligne');
    return r;
  }
}
