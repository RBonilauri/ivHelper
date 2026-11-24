import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import 'type_badge.dart';

/// Or des Pokémon rang 1.
const Color rankOneGold = Color(0xFFE0A800);

/// Couleur de fond d'une case : le premier type, adouci.
Color tileColor(BuildContext context, CollectionRow row) {
  final scheme = Theme.of(context).colorScheme;
  final types = row.species.types;
  if (types.isEmpty) return scheme.surfaceContainerHighest;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return Color.lerp(scheme.surface, typeColors[types.first], dark ? 0.32 : 0.26)!;
}

/// Bordure d'une case : dorée et épaisse pour un rang 1.
BorderSide tileBorder(BuildContext context, CollectionRow row) {
  if (row.entry.isRankOne) {
    return const BorderSide(color: rankOneGold, width: 3);
  }
  final types = row.species.types;
  return BorderSide(
    color: types.isEmpty
        ? Theme.of(context).colorScheme.outlineVariant
        : typeColors[types.first]!.withValues(alpha: 0.6),
  );
}

/// Badge « ★ Rang 1 ».
class RankOneBadge extends StatelessWidget {
  /// Crée le badge.
  const RankOneBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: rankOneGold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '★ Rang 1',
        style: TextStyle(
          color: Color(0xFF1D2A5B),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Étiquette de ligue et de rang : « Super · 12 ».
class LeagueTag extends StatelessWidget {
  /// Crée l'étiquette de [entry].
  const LeagueTag(this.entry, {super.key});

  /// Pokémon enregistré.
  final CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${entry.league.label} · rang ${entry.rank}',
        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Particularités d'un Pokémon : shiny, chanceux, costume, obscur ou
/// purifié, taille.
class EntryAttributes extends StatelessWidget {
  /// Crée la ligne de particularités de [entry].
  const EntryAttributes(this.entry, {super.key, this.withLabels = false});

  /// Pokémon enregistré.
  final CollectionEntry entry;

  /// Vrai pour écrire le nom à côté de chaque icône.
  final bool withLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(IconData?, String, Color?)>[
      if (entry.shiny) (Icons.auto_awesome, 'Shiny', const Color(0xFFE0A800)),
      if (entry.lucky) (Icons.stars, 'Chanceux', const Color(0xFFD4A017)),
      if (entry.costume) (Icons.checkroom, 'Costume', const Color(0xFFD9488F)),
      if (entry.shadow == ShadowState.shadow)
        (Icons.whatshot, 'Obscur', const Color(0xFF7B3FA0)),
      if (entry.shadow == ShadowState.purified)
        (Icons.wb_sunny_outlined, 'Purifié', const Color(0xFF4A90C2)),
      if (entry.size != PokeSize.none) (null, entry.size.label, null),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final (icon, label, color) in items)
          if (icon == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.onSurface),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Semantics(
              label: label,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 16, color: color),
                  if (withLabels) ...<Widget>[
                    const SizedBox(width: 3),
                    Text(label, style: theme.textTheme.labelMedium),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

/// Demande confirmation avant de retirer [entry] ; renvoie vrai si confirmé.
Future<bool> confirmDelete(BuildContext context, CollectionEntry entry) async {
  final iv = entry.iv;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer ce Pokémon ?'),
      content: Text(
        '${entry.speciesName} ${iv.atk}/${iv.def}/${iv.sta} '
        '(${entry.league.label}, rang ${entry.rank}) sera retiré de ta '
        'collection.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE5484D),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
