import 'dart:convert';

import 'package:ivhelper/state/meta_controller.dart';

/// Méta minimale : Flambusard en tête de la ligue super ([withAltaria] :
/// Altaria, Dragon/Vol, en deuxième).
String fakeMetaJson({
  String updated = '2026-11-20',
  String name = 'Flambusard',
  String species = 'Flambusard',
  List<String> best = const <String>['Florges'],
  bool withAltaria = false,
  List<Object?>? cups,
}) =>
    jsonEncode(<String, Object?>{
      'updated': updated,
      'source': 'PvPoke',
      'leagues': <String, Object?>{
        'great': <Object?>[
          <String, Object?>{
            'rank': 1,
            'name': name,
            'species': species,
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
            'bestMatchups': best,
            'worstMatchups': <String>['Altaria'],
          },
          if (withAltaria)
            <String, Object?>{
              'rank': 2,
              'name': 'Altaria',
              'species': 'Altaria',
              'shadow': false,
              'types': <String>['dragon', 'flying'],
              'score': 88,
              'fast': <String, String>{
                'id': 'DRAGON_BREATH',
                'name': 'Draco-Souffle',
                'type': 'dragon',
              },
              'charged': <Object?>[
                <String, String>{
                  'id': 'MOONBLAST',
                  'name': 'Pouvoir Lunaire',
                  'type': 'fairy',
                },
              ],
              'bestMatchups': <String>['Flambusard'],
              'worstMatchups': <String>['Florges'],
            },
        ],
        'ultra': <Object?>[],
        'master': <Object?>[],
      },
      if (cups != null) 'cups': cups,
    });

/// Entrée de méta minimale (Feu/Vol, Calcination et Rapace).
Map<String, Object?> fakeMetaEntry({
  int rank = 1,
  String name = 'Flambusard',
  String? species = 'Flambusard',
  bool shadow = false,
}) =>
    <String, Object?>{
      'rank': rank,
      'name': name,
      'species': species,
      'shadow': shadow,
      'types': <String>['fire', 'flying'],
      'score': 90,
      'fast': <String, String>{
        'id': 'INCINERATE',
        'name': 'Calcination',
        'type': 'fire',
      },
      'charged': <Object?>[
        <String, String>{'id': 'BRAVE_BIRD', 'name': 'Rapace', 'type': 'flying'},
      ],
      'bestMatchups': <String>[],
      'worstMatchups': <String>[],
    };

/// Coupe minimale : Flambusard n° 1, admis avec [eligible].
Map<String, Object?> fakeCupJson({
  String key = 'spectral-1500',
  String title = 'Battle Frontier (Spectral)',
  String league = 'great',
  List<Map<String, Object?>>? entries,
  List<String> eligible = const <String>['Flambusard'],
}) =>
    <String, Object?>{
      'key': key,
      'title': title,
      'league': league,
      'entries': entries ?? <Map<String, Object?>>[fakeMetaEntry()],
      'eligible': eligible,
    };

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
