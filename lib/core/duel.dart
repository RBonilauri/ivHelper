import 'league.dart';
import 'meta.dart';
import 'moves.dart';
import 'poke_type.dart';
import 'species_repository.dart';
import 'stats.dart';

/// Squelette.
class Fighter {
  /// Squelette.
  const Fighter({
    required this.types,
    required this.atk,
    required this.def,
    required this.hp,
    required this.fast,
    required this.charged,
  });

  /// Squelette.
  final List<PokeType> types;

  /// Squelette.
  final double atk;

  /// Squelette.
  final double def;

  /// Squelette.
  final int hp;

  /// Squelette.
  final Move fast;

  /// Squelette.
  final List<Move> charged;

  /// Squelette.
  static Fighter? of({
    required BaseStats base,
    required Iv iv,
    required double level,
    required List<PokeType> types,
    required Move? fast,
    required List<Move> charged,
    bool shadow = false,
  }) =>
      null;
}

/// Squelette.
int pvpDamage(Move move, Fighter attacker, Fighter defender) => 0;

/// Squelette.
enum DuelOutcome {
  /// Squelette.
  win,

  /// Squelette.
  loss,

  /// Squelette.
  draw,
}

/// Squelette.
DuelOutcome duel(Fighter a, Fighter b, {int shields = 1}) => DuelOutcome.draw;

/// Squelette.
bool beats(Fighter a, Fighter b) => false;

/// Squelette.
Fighter? metaFighter(
  MetaEntry entry,
  League league,
  SpeciesRepository repository,
  MoveBook moves,
) =>
    null;
