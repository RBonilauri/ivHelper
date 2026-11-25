import '../core/moves.dart';
import '../core/species_repository.dart';

/// Nom de [move], suivi d'un astérisque si c'est une attaque d'événement
/// (Élite) pour [species].
String moveLabel(Move move, Species? species) =>
    species != null && species.isElite(move.id) ? '${move.nameFr}*' : move.nameFr;

/// Légende de l'astérisque.
const String eliteLegend = '* attaque d\'événement (Élite)';

/// Effets lisibles d'un changement de stats : « Ton attaque −2 »,
/// « Défense adverse −1 (30 % de chance) »…
List<String> effectLabels(StatChange change) {
  final self = change.target == StatTarget.self;
  final odds = change.chance >= 1
      ? ''
      : ' (${_percent(change.chance)} % de chance)';
  return <String>[
    if (change.attack != 0)
      '${self ? 'Ton attaque' : 'Attaque adverse'} ${_signed(change.attack)}$odds',
    if (change.defense != 0)
      '${self ? 'Ta défense' : 'Défense adverse'} ${_signed(change.defense)}$odds',
  ];
}

String _signed(int value) => value > 0 ? '+$value' : '\u2212${-value}';

String _percent(double chance) {
  final value = chance * 100;
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? '${rounded.round()}'
      : rounded.toString().replaceAll('.', ',');
}
