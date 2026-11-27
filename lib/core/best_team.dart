import 'collection.dart';
import 'meta.dart';
import 'poke_type.dart';

/// Squelette.
class TeamCandidate {
  /// Squelette.
  const TeamCandidate({
    required this.id,
    required this.species,
    required this.shadow,
    required this.types,
    required this.moveTypes,
    required this.ivRank,
    this.metaName,
    this.metaRank,
    this.metaScore,
    this.beats = const <String>[],
    this.losesTo = const <String>[],
  });

  /// Squelette.
  final String id;

  /// Squelette.
  final String species;

  /// Squelette.
  final bool shadow;

  /// Squelette.
  final List<PokeType> types;

  /// Squelette.
  final List<PokeType> moveTypes;

  /// Squelette.
  final int ivRank;

  /// Squelette.
  final String? metaName;

  /// Squelette.
  final int? metaRank;

  /// Squelette.
  final double? metaScore;

  /// Squelette.
  final List<String> beats;

  /// Squelette.
  final List<String> losesTo;
}

/// Squelette.
class TeamProposal {
  /// Squelette.
  const TeamProposal({
    required this.members,
    required this.coverage,
    required this.covered,
    required this.total,
    required this.threats,
  });

  /// Squelette.
  final List<TeamCandidate> members;

  /// Squelette.
  final double coverage;

  /// Squelette.
  final int covered;

  /// Squelette.
  final int total;

  /// Squelette.
  final List<String> threats;
}

/// Squelette.
bool counters(TeamCandidate c, MetaEntry o) => false;

/// Squelette.
List<TeamProposal> bestTeams(
  List<TeamCandidate> candidates,
  List<MetaEntry> opponents, {
  int top = 50,
  int count = 3,
}) =>
    const <TeamProposal>[];

/// Squelette.
List<TeamCandidate> teamCandidates(
  List<CollectionRow> rows,
  League league,
  MetaSnapshot meta,
) =>
    const <TeamCandidate>[];
