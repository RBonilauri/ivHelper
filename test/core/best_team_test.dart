import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/best_team.dart';
import 'package:ivhelper/core/meta.dart';
import 'package:ivhelper/core/poke_type.dart';

MetaMove _m(PokeType t) => MetaMove(id: t.id, nameFr: t.nameFr, type: t);

MetaEntry _opp(int rank, String name, List<PokeType> types, List<PokeType> moves) =>
    MetaEntry(
      rank: rank,
      name: name,
      species: name,
      shadow: false,
      types: types,
      score: 90,
      fast: _m(moves.first),
      charged: <MetaMove>[for (final t in moves.skip(1)) _m(t)],
      bestMatchups: const <String>[],
      worstMatchups: const <String>[],
    );

final List<MetaEntry> _meta = <MetaEntry>[
  _opp(1, 'Feunard', <PokeType>[PokeType.fire], <PokeType>[PokeType.fire]),
  _opp(2, 'Ptéra', <PokeType>[PokeType.grass], <PokeType>[PokeType.grass]),
  _opp(3, 'Corvaillus', <PokeType>[PokeType.steel, PokeType.flying],
      <PokeType>[PokeType.flying, PokeType.steel]),
];

TeamCandidate _c(
  String id,
  String species,
  PokeType type, {
  double? score,
  int ivRank = 1,
  List<String> beats = const <String>[],
  List<String> losesTo = const <String>[],
}) =>
    TeamCandidate(
      id: id,
      species: species,
      shadow: false,
      types: <PokeType>[type],
      moveTypes: <PokeType>[type],
      metaScore: score,
      ivRank: ivRank,
      beats: beats,
      losesTo: losesTo,
    );

void main() {
  test('contrer : PvPoke d\'abord, sinon super efficace sans le subir', () {
    final water = _c('a', 'Aligatueur', PokeType.water);
    expect(counters(water, _meta[0]), isTrue); // Eau contre Feu
    expect(counters(water, _meta[1]), isFalse); // Eau contre Plante
    final fire = _c('b', 'Simiabraz', PokeType.fire);
    expect(counters(fire, _meta[2]), isTrue); // Feu ×1,6 sur Acier/Vol
    // Les résultats PvPoke l'emportent sur les types.
    final grass = _c('d', 'Florizarre', PokeType.grass, beats: <String>['Feunard']);
    expect(counters(grass, _meta[0]), isTrue);
    final fireLoses = _c('b', 'Simiabraz', PokeType.fire, losesTo: <String>['Ptéra']);
    expect(counters(fireLoses, _meta[1]), isFalse);
  });

  test('meilleure équipe : couverture pondérée, puis note méta', () {
    final teams = bestTeams(
      <TeamCandidate>[
        _c('a', 'Aligatueur', PokeType.water, score: 90),
        _c('b', 'Simiabraz', PokeType.fire, score: 80),
        _c('c', 'Élekable', PokeType.electric, score: 70),
        _c('d', 'Florizarre', PokeType.grass, score: 40),
        _c('e', 'Tortank', PokeType.water, score: 50),
      ],
      _meta,
    );
    expect(teams, hasLength(3));
    final best = teams.first;
    expect(<String>[for (final m in best.members) m.id], <String>['a', 'b', 'c']);
    expect(best.coverage, 1.0);
    expect(best.covered, 3);
    expect(best.total, 3);
    expect(best.threats, isEmpty);
    // Les propositions suivantes ne sont jamais meilleures.
    expect(teams[1].coverage, lessThanOrEqualTo(best.coverage));
  });

  test('menaces : adversaires non couverts, du haut de la méta d\'abord', () {
    final teams = bestTeams(
      <TeamCandidate>[
        _c('d', 'Florizarre', PokeType.grass),
        _c('f', 'Grodoudou', PokeType.normal),
        _c('g', 'Ronflex', PokeType.normal),
      ],
      _meta,
    );
    expect(teams.single.covered, 0);
    expect(teams.single.coverage, 0);
    expect(teams.single.threats, <String>['Feunard', 'Ptéra', 'Corvaillus']);
  });

  test('pondération : le haut de la méta compte davantage', () {
    // Seul Feunard (n° 1) est couvert : poids 2 sur 2 + 5/3 + 4/3 = 5.
    final teams = bestTeams(
      <TeamCandidate>[
        _c('a', 'Aligatueur', PokeType.water),
        _c('f', 'Grodoudou', PokeType.normal),
        _c('g', 'Ronflex', PokeType.normal),
      ],
      _meta,
    );
    expect(teams.single.coverage, closeTo(0.4, 1e-9));
  });

  test('espèces différentes ; un doublon garde son meilleur rang d\'IV', () {
    final teams = bestTeams(
      <TeamCandidate>[
        _c('a1', 'Aligatueur', PokeType.water, ivRank: 40),
        _c('a2', 'Aligatueur', PokeType.water, ivRank: 3),
        _c('b', 'Simiabraz', PokeType.fire),
        _c('c', 'Élekable', PokeType.electric),
      ],
      _meta,
    );
    expect(teams, hasLength(1));
    expect(<String>[for (final m in teams.single.members) m.id], <String>['a2', 'b', 'c']);
    // Moins de trois espèces : pas d'équipe.
    expect(
      bestTeams(<TeamCandidate>[
        _c('a1', 'Aligatueur', PokeType.water),
        _c('a2', 'Aligatueur', PokeType.water),
        _c('b', 'Simiabraz', PokeType.fire),
      ], _meta),
      isEmpty,
    );
  });
}
