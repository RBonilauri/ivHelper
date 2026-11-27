import 'package:material_ui/material_ui.dart';

import '../core/best_team.dart';
import '../core/collection.dart';
import '../core/meta.dart';
import '../state/meta_controller.dart';
import 'format.dart';
import 'type_badge.dart';

/// Explication de « Ma meilleure équipe », dans la bulle « i ».
const String bestTeamExplanation =
    'Parmi tes Pokémon tagués dans la ligue, les trois espèces différentes '
    'qui contrent le plus d\'adversaires du top 50 de la méta PvPoke (le haut '
    'du classement compte davantage). Un Pokémon contre un adversaire si '
    'PvPoke le donne gagnant, sinon s\'il le touche en super efficace sans '
    'subir de super efficace. À égalité : meilleure note méta, puis meilleur '
    'rang d\'IV.';

/// Ligues proposées (pas de méta en Mini).
const List<League> _leagues = <League>[League.great, League.ultra, League.master];

/// Nombre de menaces affichées par proposition.
const int _threatsShown = 5;

/// Feuille « Ma meilleure équipe » : choix de la ligue et jusqu'à trois
/// équipes tirées de [rows] ; renvoie celle choisie.
class BestTeamSheet extends StatefulWidget {
  /// Crée la feuille.
  const BestTeamSheet({super.key, required this.meta, required this.rows});

  /// Méta PvPoke.
  final MetaController meta;

  /// Toute la collection.
  final List<CollectionRow> rows;

  @override
  State<BestTeamSheet> createState() => _BestTeamSheetState();
}

class _BestTeamSheetState extends State<BestTeamSheet> {
  League _league = League.great;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.meta,
      builder: (context, _) {
        final data = widget.meta.data;
        final metaLeague = metaLeagueOf(_league);
        final proposals = data == null || metaLeague == null
            ? const <TeamProposal>[]
            : bestTeams(
                teamCandidates(widget.rows, data.boardOf(metaLeague)),
                data.leagues[metaLeague] ?? const <MetaEntry>[],
              );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Ma meilleure équipe',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final l in _leagues)
                    ChoiceChip(
                      key: ValueKey<String>('best-league-${l.key}'),
                      label: Text(l.label),
                      selected: l == _league,
                      onSelected: (_) => setState(() => _league = l),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (data == null)
              const _Message('La méta PvPoke n\'est pas encore chargée.')
            else if (proposals.isEmpty)
              _Message(
                'Il faut au moins trois espèces différentes tagguées en '
                'ligue ${_league.label} dans ta collection.',
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: proposals.length,
                  itemBuilder: (context, i) =>
                      _ProposalCard(index: i, proposal: proposals[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.index, required this.proposal});

  final int index;
  final TeamProposal proposal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = proposal;
    final percent = (p.coverage * 100).round();
    final threats = p.threats.take(_threatsShown).join(', ');
    return Card(
      key: ValueKey<String>('best-team-$index'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Couvre $percent % du top ${p.total}',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              '${p.covered} adversaires contrés sur ${p.total}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final m in p.members) _MemberLine(member: m),
            if (threats.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'À surveiller : $threats',
                style: theme.textTheme.bodySmall,
              ),
            ],
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: ValueKey<String>('best-use-$index'),
                onPressed: () => Navigator.of(context).pop(p),
                child: const Text('Utiliser cette équipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberLine extends StatelessWidget {
  const _MemberLine({required this.member});

  final TeamCandidate member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = member;
    final rank = m.metaRank;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          for (final t in m.types)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: TypeBadge(t, size: 24),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              m.shadow ? '${m.species} (Obscur)' : m.species,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${rank == null ? 'Hors méta' : 'Méta n° $rank'}'
            ' · IV n° ${formatGrouped(m.ivRank)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
