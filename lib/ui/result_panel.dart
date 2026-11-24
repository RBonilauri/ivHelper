import 'package:material_ui/material_ui.dart';

import '../core/rank_service.dart';
import '../core/rank_table.dart';
import '../core/species_repository.dart';
import '../core/stat_line.dart';
import 'format.dart';

enum _League { great, ultra }

/// Résultats d'une espèce en ligue super et hyper : rang, tableau du haut du
/// classement et détails dépliables.
class ResultPanel extends StatefulWidget {
  /// Crée le panneau de résultats.
  const ResultPanel({super.key, required this.species, required this.result});

  /// Espèce évaluée.
  final Species species;

  /// Résultats des deux ligues.
  final RankResult result;

  @override
  State<ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends State<ResultPanel> {
  _League _league = _League.great;
  bool _details = false;
  final Set<int> _open = <int>{};

  LeagueResult get _current =>
      _league == _League.great ? widget.result.great : widget.result.ultra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final league = _current;
    final mine = league.mine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<_League>(
          segments: const <ButtonSegment<_League>>[
            ButtonSegment<_League>(
              value: _League.great,
              label: Text('Super · 1500'),
            ),
            ButtonSegment<_League>(
              value: _League.ultra,
              label: Text('Hyper · 2500'),
            ),
          ],
          selected: <_League>{_league},
          onSelectionChanged: (selection) {
            setState(() {
              _league = selection.first;
              _open.clear();
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Text(
              'Rang ${formatGrouped(mine.rank)}',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'sur ${formatGrouped(league.table.entries.length)} · '
                '${formatPercent(mine.percent)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Text('Détails'),
            Switch(
              value: _details,
              onChanged: (value) => setState(() => _details = value),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const _HeaderRow(),
        _RankRow(
          rowKey: const ValueKey<String>('mine-row'),
          entry: mine,
          stats: statLine(widget.species.base, mine),
          highlighted: true,
          open: _details || _open.contains(mine.rank),
          onTap: () => _toggle(mine.rank),
        ),
        for (final entry in league.top(10))
          _RankRow(
            rowKey: const ValueKey<String>('rank-row'),
            entry: entry,
            stats: statLine(widget.species.base, entry),
            highlighted: false,
            open: _details || _open.contains(entry.rank),
            onTap: () => _toggle(entry.rank),
          ),
      ],
    );
  }

  void _toggle(int rank) {
    setState(() {
      if (!_open.remove(rank)) _open.add(rank);
    });
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(flex: 2, child: Text('#', style: style)),
          Expanded(flex: 2, child: Text('Niv', style: style)),
          Expanded(flex: 2, child: Text('PC', style: style)),
          Expanded(flex: 4, child: Text('A/D/PV', style: style)),
          Expanded(flex: 3, child: Text('Parfait', style: style)),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rowKey,
    required this.entry,
    required this.stats,
    required this.highlighted,
    required this.open,
    required this.onTap,
  });

  final Key rowKey;
  final RankEntry entry;
  final StatLine stats;
  final bool highlighted;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: highlighted ? scheme.onPrimaryContainer : null,
      fontWeight: highlighted ? FontWeight.w600 : null,
    );
    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          child: Container(
            key: rowKey,
            color: highlighted ? scheme.primaryContainer : null,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(formatGrouped(entry.rank), style: textStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(formatLevel(entry.level), style: textStyle),
                ),
                Expanded(flex: 2, child: Text('${entry.cp}', style: textStyle)),
                Expanded(
                  flex: 4,
                  child: Text(entry.iv.toString(), style: textStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text(formatPercent(entry.percent), style: textStyle),
                ),
                SizedBox(
                  width: 24,
                  child: Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (open)
          Container(
            width: double.infinity,
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Atk ${formatStat(stats.atk)} · Déf ${formatStat(stats.def)} · '
              'PV ${stats.hp} · '
              'Stat globale ${formatGrouped(stats.product.round())}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
