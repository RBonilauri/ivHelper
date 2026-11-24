import '../core/moves.dart';
import '../core/species_repository.dart';

/// Nom de [move], suivi d'un astérisque si c'est une attaque d'événement
/// (Élite) pour [species].
String moveLabel(Move move, Species? species) =>
    species != null && species.isElite(move.id) ? '${move.nameFr}*' : move.nameFr;

/// Légende de l'astérisque.
const String eliteLegend = '* attaque d\'événement (Élite)';
