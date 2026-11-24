import 'package:material_ui/material_ui.dart';

import '../core/league.dart';
import '../core/rank_service.dart';
import '../core/species_repository.dart';
import '../core/stats.dart';
import 'format.dart';
import 'type_badge.dart';

/// Rang des [iv] pour chaque stade d'évolution (lignes) et chaque ligue
/// (colonnes). Un appui sur une case la sélectionne.
class FamilyRankTable extends StatefulWidget {
  /// Crée le tableau.
  const FamilyRankTable({
    super.key,
    required this.family,
    required this.iv,
    required this.maxLevel,
    required this.selectedSpecies,
    required this.selectedLeague,
    required this.onSelect,
    this.current,
  });

  /// Stades d'évolution, du premier au dernier.
  final List<Species> family;

  /// IV du Pokémon.
  final Iv iv;

  /// Niveau maximal (50 ou 51).
  final double maxLevel;

  /// Stade affiché à l'écran du jeu (mis en évidence), ou `null`.
  final Species? current;

  /// Case sélectionnée : stade.
  final Species? selectedSpecies;

  /// Case sélectionnée : ligue.
  final League selectedLeague;

  /// Appelé quand une case est touchée.
  final void Function(Species species, League league) onSelect;

  @override
  State<FamilyRankTable> createState() => _FamilyRankTableState();
}

class _FamilyRankTableState extends State<FamilyRankTable> {
  final Map<String, RankResult> _cache = <String, RankResult>{};

  RankResult _resultFor(Species s) {
    final key = '${s.nameFr}|${widget.iv}|${widget.maxLevel}';
    return _cache[key] ??= rankIv(s.base, widget.iv, maxLevel: widget.maxLevel);
  }

  static LeagueResult _league(RankResult r, League l) => switch (l) {
        League.little => r.little,
        League.great => r.great,
        League.ultra => r.ultra,
        League.master => r.master,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      columnWidths: const <int, TableColumnWidth>{0: FlexColumnWidth(1.6)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(
          children: <Widget>[
            Text('Stade', style: theme.textTheme.labelMedium),
            for (final l in League.values)
              Center(child: Text(l.label, style: theme.textTheme.labelMedium)),
          ],
        ),
        for (final s in widget.family)
          TableRow(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    if (s.types.isNotEmpty)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 4),
                        child: TypeBadge(s.types.first, size: 18),
                      ),
                    Flexible(
                      child: Text(
                        identical(s, widget.current) ? '${s.nameFr} •' : s.nameFr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: identical(s, widget.current)
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final l in League.values)
                _Cell(
                  key: ValueKey<String>('cell-${s.nameFr}-${l.key}'),
                  entry: _league(_resultFor(s), l).mine.rank,
                  percent: _league(_resultFor(s), l).mine.percent,
                  selected: identical(s, widget.selectedSpecies) &&
                      l == widget.selectedLeague,
                  onTap: () => widget.onSelect(s, l),
                ),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.entry,
    required this.percent,
    required this.selected,
    required this.onTap,
  });

  final int entry;
  final double percent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background;
    if (entry == 1) {
      background = const Color(0xFFFFD54F);
    } else if (entry <= 10) {
      background = const Color(0xFF8FD694);
    } else if (entry <= 100) {
      background = const Color(0xFFD4F0D6);
    } else {
      background = theme.colorScheme.surfaceContainerHighest;
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1D2A5B), width: 2),
                  )
                : null,
            child: Column(
              children: <Widget>[
                Text(
                  formatGrouped(entry),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D2A5B),
                  ),
                ),
                Text(
                  formatPercent(percent),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF1D2A5B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
