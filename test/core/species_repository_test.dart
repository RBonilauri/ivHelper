import 'package:flutter_test/flutter_test.dart';
import 'package:ivhelper/core/moves.dart';
import 'package:ivhelper/core/poke_type.dart';
import 'package:ivhelper/core/species_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpeciesRepository repo;

  setUpAll(() async {
    repo = await SpeciesRepository.load();
  });

  test('findByName trouve Flambusard avec ses stats de base', () {
    final s = repo.findByName('Flambusard');
    expect(s, isNotNull);
    expect(s!.dex, 663);
    expect(s.base.atk, 176);
    expect(s.base.def, 155);
    expect(s.base.sta, 186);
  });

  test('findByName ignore la casse et les accents', () {
    expect(repo.findByName('FLAMBUSARD')?.dex, 663);
    expect(repo.findByName('lepidonille')?.dex, 664);
  });

  test('findByName corrige une faute de lecture', () {
    expect(repo.findByName('Flambusrad')?.dex, 663);
  });

  test('findByName renvoie null pour un nom inconnu', () {
    expect(repo.findByName('Zorglub'), isNull);
  });

  test('suggest propose Flambusard pour Flamb', () {
    final names = repo.suggest('Flamb').map((s) => s.nameFr);
    expect(names, contains('Flambusard'));
  });

  test('findByDex renvoie l\'espèce de base ou null', () {
    expect(repo.findByDex(663)?.nameFr, 'Flambusard');
    expect(repo.findByDex(99999), isNull);
  });

  test('lookup accepte un numéro ou un nom', () {
    expect(repo.lookup('663')?.nameFr, 'Flambusard');
    expect(repo.lookup(' 663 ')?.nameFr, 'Flambusard');
    expect(repo.lookup('flambusard')?.dex, 663);
    expect(repo.lookup(''), isNull);
  });

  test('la forme d\'Alola de Raichu a ses propres stats', () {
    final base = repo.findByName('Raichu');
    final alola = repo.findByName('Raichu d\'Alola');
    expect(base, isNotNull);
    expect(alola, isNotNull);
    expect(alola!.dex, 26);
    expect(alola.base.atk, isNot(base!.base.atk));
  });

  test('le fichier couvre plus de mille espèces', () {
    expect(repo.all.length, greaterThan(1000));
  });

  test('Flambusard est Feu/Vol avec Calcination et Rapace', () async {
    final s = repo.findByName('Flambusard')!;
    expect(s.types, <PokeType>[PokeType.fire, PokeType.flying]);
    expect(s.fastMoves, contains('INCINERATE'));
    expect(s.chargedMoves, contains('BRAVE_BIRD'));
    final moves = await MoveBook.load();
    final incinerate = moves['INCINERATE']!;
    expect(incinerate.nameFr, 'Calcination');
    expect(incinerate.type, PokeType.fire);
    expect(incinerate.isFast, isTrue);
    expect(moves['BRAVE_BIRD']!.isFast, isFalse);
  });

  test('chaque espèce a au moins un type et des attaques connues', () async {
    final moves = await MoveBook.load();
    for (final s in repo.all) {
      expect(s.types, isNotEmpty, reason: s.nameFr);
      expect(moves.resolve(s.fastMoves).every((m) => m.isFast), isTrue);
      expect(
        moves.resolve(s.chargedMoves).every((m) => !m.isFast),
        isTrue,
        reason: s.nameFr,
      );
    }
  });
}
