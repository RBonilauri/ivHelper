import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';

const _json = '''
{
  "DRAGON_BREATH": {"fast": true, "name": "Draco-Souffle", "power": 3, "type": "dragon",
    "energyGain": 3, "turns": 1},
  "IRON_HEAD": {"fast": false, "name": "Tête de Fer", "power": 85, "type": "steel", "energy": 50},
  "DRACO_METEOR": {"fast": false, "name": "Draco-Météore", "power": 150, "type": "dragon",
    "energy": 65, "effects": [{"target": "self", "atk": -2, "def": 0, "chance": 1}]},
  "OBSTRUCT": {"fast": false, "name": "Blocage", "power": 15, "type": "dark", "energy": 40,
    "effects": [{"target": "self", "atk": 0, "def": 1, "chance": 1},
                {"target": "opponent", "atk": 0, "def": -1, "chance": 1}]},
  "ACID_SPRAY": {"fast": false, "name": "Bombe Acide", "power": 20, "type": "poison", "energy": 45,
    "effects": [{"target": "opponent", "atk": 0, "def": -2, "chance": 1}]},
  "MUD_BOMB": {"fast": false, "name": "Boue-Bombe", "power": 60, "type": "ground", "energy": 33}
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final book = MoveBook.fromJson(_json);

  test("le coût d'énergie donne le nombre de barres, comme dans le jeu", () {
    expect(book['DRAGON_BREATH']!.chargeBars, 0);
    expect(book['DRACO_METEOR']!.energy, 65);
    expect(book['DRACO_METEOR']!.chargeBars, 1);
    expect(book['IRON_HEAD']!.chargeBars, 2);
    expect(book['ACID_SPRAY']!.chargeBars, 2);
    expect(book['MUD_BOMB']!.chargeBars, 3);
  });

  test('les changements de stats sont lus pour soi et pour l\'adversaire', () {
    expect(book['IRON_HEAD']!.effects, isEmpty);
    final meteor = book['DRACO_METEOR']!.effects.single;
    expect(meteor.target, StatTarget.self);
    expect(meteor.attack, -2);
    expect(meteor.defense, 0);
    expect(meteor.chance, 1);
    expect(meteor.isBeneficial, isFalse);

    final obstruct = book['OBSTRUCT']!.effects;
    expect(obstruct.map((e) => e.target), [StatTarget.self, StatTarget.opponent]);
    expect(obstruct.every((e) => e.isBeneficial), isTrue);
    expect(book['OBSTRUCT']!.type, PokeType.dark);
  });

  test('attaque immédiate : énergie rapportée et durée en tours', () {
    expect(book['DRAGON_BREATH']!.energyGain, 3);
    expect(book['DRAGON_BREATH']!.turns, 1);
    // Valeurs par défaut pour une chargée ou des données anciennes.
    expect(book['IRON_HEAD']!.energyGain, 0);
    expect(book['IRON_HEAD']!.turns, 1);
  });

  test('un ancien moves.json sans énergie ni effets reste lisible', () {
    final old = MoveBook.fromJson(
      '{"BRAVE_BIRD": {"fast": false, "name": "Rapace", "power": 130, "type": "flying"}}',
    );
    expect(old['BRAVE_BIRD']!.energy, 0);
    expect(old['BRAVE_BIRD']!.chargeBars, 0);
    expect(old['BRAVE_BIRD']!.effects, isEmpty);
  });

  test('les vraies attaques ont leur énergie et leurs effets', () async {
    final moves = await MoveBook.load();
    final meteor = moves['DRACO_METEOR']!;
    expect(meteor.chargeBars, 1);
    // Riposte : 6 d'énergie en 2 tours, comme dans le jeu.
    expect(moves['COUNTER']!.energyGain, 6);
    expect(moves['COUNTER']!.turns, 2);
    expect(meteor.effects.single.attack, -2);
    expect(moves['IRON_HEAD']!.chargeBars, 2);
    expect(
      moves['ICY_WIND']!.effects.single.target,
      StatTarget.opponent,
    );
  });

  test('MoveBook.all : toutes les attaques, par nom', () {
    final book = MoveBook(const <Move>[
      Move(id: 'B', nameFr: 'Rapace', type: PokeType.flying, isFast: false),
      Move(id: 'A', nameFr: 'Calcination', type: PokeType.fire, isFast: true),
    ]);
    expect(<String>[for (final m in book.all) m.nameFr],
        <String>['Calcination', 'Rapace']);
  });
}
