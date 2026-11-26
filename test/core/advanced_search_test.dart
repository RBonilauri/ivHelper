import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/advanced_search.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';

void main() {
  test('un appui ajoute, deux excluent, trois décochent', () {
    expect(Pick.off.next, Pick.include);
    expect(Pick.include.next, Pick.exclude);
    expect(Pick.exclude.next, Pick.off);
  });

  test('rubrique : OU par défaut, ET au choix, exclusions en plus', () {
    final fire = typeTerm(PokeType.fire);
    final water = typeTerm(PokeType.water);
    final dark = typeTerm(PokeType.dark);
    expect(
      buildSearch(<SearchSection>[
        SearchSection(included: <SearchTerm>[fire, water]),
      ]),
      'feu,eau',
    );
    expect(
      buildSearch(<SearchSection>[
        SearchSection(included: <SearchTerm>[fire, water], all: true),
      ]),
      'feu&eau',
    );
    expect(
      buildSearch(<SearchSection>[
        SearchSection(
          included: <SearchTerm>[fire],
          excluded: <SearchTerm>[water, dark],
        ),
      ]),
      'feu&!eau&!ténèbres',
    );
    expect(buildSearch(const <SearchSection>[]), '');
  });

  test('rubriques reliées par ET, puis les bornes, sans doublon', () {
    expect(
      buildSearch(
        <SearchSection>[
          SearchSection(included: <SearchTerm>[
            speciesTerm('Raichu d\'Alola', family: true),
          ]),
          SearchSection(included: <SearchTerm>[statusTerms[1]]),
          SearchSection(excluded: <SearchTerm>[statusTerms[2]]),
          SearchSection(included: <SearchTerm>[statusTerms[1]]),
        ],
        ranges: <String?>[
          numberRange('PC', null, 1500),
          null,
          statRange(0, 1, 'attaque'),
        ],
      ),
      '+raichu&chromatique&!obscur&PC-1500&0-1attaque',
    );
  });

  test('type d\'attaque selon l\'emplacement', () {
    expect(moveTypeTerm(PokeType.ground, MoveSlot.any).atoms, <String>['@sol']);
    expect(moveTypeTerm(PokeType.ground, MoveSlot.fast).atoms, <String>['@1sol']);
    final charged = moveTypeTerm(PokeType.fire, MoveSlot.charged);
    expect(charged.atoms, <String>['@2feu', '@3feu']);
    expect(
      buildSearch(<SearchSection>[
        SearchSection(included: <SearchTerm>[
          moveTypeTerm(PokeType.ground, MoveSlot.fast),
          moveTypeTerm(PokeType.ice, MoveSlot.fast),
        ]),
        SearchSection(
          included: <SearchTerm>[charged, moveTypeTerm(PokeType.flying, MoveSlot.charged)],
        ),
      ]),
      '@1sol,@1glace&@2feu,@3feu,@2vol,@3vol',
    );
    // ET dans la rubrique : chaque case garde son OU interne.
    expect(
      SearchSection(
        included: <SearchTerm>[charged, moveTypeTerm(PokeType.flying, MoveSlot.charged)],
        all: true,
      ).clauses(),
      <String>['@2feu,@3feu', '@2vol,@3vol'],
    );
    // Exclure une chargée Feu : ni la première ni la seconde.
    expect(
      SearchSection(excluded: <SearchTerm>[charged]).clauses(),
      <String>['!@2feu', '!@3feu'],
    );
  });

  test('attaque par nom, attaque élite, Pokémon et famille', () {
    const move = Move(
      id: 'BRAVE_BIRD',
      nameFr: 'Rapace',
      type: PokeType.flying,
      isFast: false,
    );
    expect(moveNameTerm(move).atoms, <String>['@rapace']);
    expect(eliteTerm.atoms, <String>['@spécial']);
    expect(speciesTerm('Nosferapti', family: false).atoms, <String>['nosferapti']);
    expect(speciesTerm('Nosferapti', family: true).atoms, <String>['+nosferapti']);
    expect(<String>[for (final t in sizeTerms) ...t.atoms],
        <String>['xxs', 'xs', 'xl', 'xxl']);
    expect(<String>[for (final t in statusTerms) ...t.atoms],
        <String>['chanceux', 'chromatique', 'obscur', 'purifié', 'costume']);
    expect(<String>[for (final t in categoryTerms) ...t.atoms],
        <String>['légendaire', 'fabuleux', 'ultra-chimère']);
    expect(starTerms.last.atoms, <String>['4*']);
  });

  test('bornes d\'IV, de PC, d\'âge et d\'année', () {
    expect(statRange(0, 4, 'PV'), isNull);
    expect(statRange(4, 4, 'PV'), '4PV');
    expect(statRange(3, 1, 'défense'), '1-3défense');
    expect(numberRange('PC', null, null), isNull);
    expect(numberRange('PC', 1500, null), 'PC1500-');
    expect(numberRange('PC', null, 1500), 'PC-1500');
    expect(numberRange('PC', 2500, 1500), 'PC1500-2500');
    expect(numberRange('âge', 0, 0), 'âge0');
    expect(numberRange('année', 2020, 2022), 'année2020-2022');
    expect(ivBucketLabel(3), '11-14');
  });

  test('PickGroup : cycle, ET/OU, cases ajoutées, effacement', () {
    final g = PickGroup(<SearchTerm>[for (final t in PokeType.values) typeTerm(t)]);
    g.cycle('fire');
    g.cycle('water');
    expect(g.section().clauses(), <String>['feu,eau']);
    g.all = true;
    expect(g.section().clauses(), <String>['feu', 'eau']);
    g.cycle('water');
    expect(g.pickOf('water'), Pick.exclude);
    expect(g.section().clauses(), <String>['feu', '!eau']);
    expect(g.includedCount, 1);
    expect(g.activeCount, 2);
    g.cycle('water');
    expect(g.pickOf('water'), Pick.off);
    expect(g.section().clauses(), <String>['feu']);

    final mons = PickGroup(const <SearchTerm>[]);
    mons.add(speciesTerm('Nosferapti', family: true));
    mons.add(speciesTerm('Pikachu', family: false));
    expect(mons.section().clauses(), <String>['+nosferapti,pikachu']);
    mons.remove('pikachu');
    expect(mons.terms, hasLength(1));
    g.clear();
    expect(g.all, isFalse);
    expect(g.section().clauses(), isEmpty);
    expect(g.terms, hasLength(18));
    mons.clear(dropTerms: true);
    expect(mons.terms, isEmpty);
  });

  test('étoiles : total d\'IV de chaque évaluation et possibilité', () {
    expect(starTotal(0), (0, 22));
    expect(starTotal(1), (23, 29));
    expect(starTotal(2), (30, 36));
    expect(starTotal(3), (37, 44));
    expect(starTotal(4), (45, 45));
    const all = <(int, int)>[(0, 4), (0, 4), (0, 4)];
    expect(ivTotalRange(all), (0, 45));
    expect(ivTotalRange(const <(int, int)>[(3, 4), (4, 4), (1, 2)]), (27, 40));
    for (var star = 0; star <= 4; star++) {
      expect(starPossible(star, all), isTrue);
    }
    // Attaque 0-15, défense 15, PV 1-10 : au plus 40, jamais 4★.
    const low = <(int, int)>[(0, 4), (4, 4), (1, 2)];
    expect(starPossible(4, low), isFalse);
    expect(starPossible(3, low), isTrue);
    // Tout à 15 : seulement 4★.
    const max = <(int, int)>[(4, 4), (4, 4), (4, 4)];
    expect(<int>[for (var s = 0; s <= 4; s++) if (starPossible(s, max)) s], <int>[4]);
  });

  test('étoiles ajoutées : tranches permises pour chaque stat', () {
    expect(starBucketLimits(const <int>{}), (0, 4));
    expect(starBucketLimits(const <int>{4}), (4, 4));
    // 3★ : total 37 ou plus, donc chaque stat vaut au moins 7 (tranche 6-10).
    expect(starBucketLimits(const <int>{3}), (2, 4));
    expect(starBucketLimits(const <int>{3, 4}), (2, 4));
    expect(starBucketLimits(const <int>{0}), (0, 4));
    expect(starBucketLimits(const <int>{2}), (0, 4));
  });

  test('bornes d\'IV : omises quand l\'évaluation les impose déjà', () {
    const max = <(int, int)>[(4, 4), (4, 4), (4, 4)];
    expect(ivRangeClauses(max, const <int>{4}), isEmpty);
    expect(ivRangeClauses(max, const <int>{}), <String>['4attaque', '4défense', '4PV']);
    expect(
      ivRangeClauses(const <(int, int)>[(2, 4), (3, 4), (0, 4)], const <int>{3}),
      <String>['3-4défense'],
    );
  });

  test('rubrique à choix exclusifs : toujours OU', () {
    final sizes = PickGroup(sizeTerms, exclusive: true);
    sizes.cycle('xxs');
    sizes.cycle('xxl');
    sizes.all = true;
    expect(sizes.section().clauses(), <String>['xxs,xxl']);
    sizes.uncheck('xxl');
    expect(sizes.section().clauses(), <String>['xxs']);
  });
}
