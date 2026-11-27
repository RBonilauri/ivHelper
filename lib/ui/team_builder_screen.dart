import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/best_team.dart';
import '../core/collection.dart';
import '../core/moves.dart';
import '../core/poke_type.dart';
import '../core/species_repository.dart';
import '../state/collection_controller.dart';
import '../state/meta_controller.dart';
import '../state/team_controller.dart';
import 'collection_widgets.dart';
import 'format.dart';
import 'move_label.dart';
import 'best_team_sheet.dart';
import 'search_field.dart';
import 'type_badge.dart';
import 'info_button.dart';

const Color _good = Color(0xFF2EAD74);
const Color _bad = Color(0xFFE5484D);

/// Team builder : trois Pokémon, leurs attaques, et l'analyse des types.
class TeamBuilderScreen extends StatelessWidget {
  /// Crée la page pour l'équipe tenue par [team].
  const TeamBuilderScreen({
    super.key,
    required this.team,
    required this.collection,
    this.meta,
  });

  /// État de l'équipe.
  final TeamController team;

  /// Collection, source des imports.
  final CollectionController collection;

  /// Méta PvPoke, pour « Ma meilleure équipe » (bouton absent si `null`).
  final MetaController? meta;

  @override
  Widget build(BuildContext context) {
    final meta = this.meta;
    return Scaffold(
      appBar: AppBar(title: const Text('Team builder')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: team,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (meta != null) ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.tonalIcon(
                        key: const ValueKey<String>('best-team'),
                        onPressed: () => _openBestTeam(context, meta),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Ma meilleure équipe'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const InfoButton(
                      bestTeamExplanation,
                      key: ValueKey<String>('info-best-team'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              for (var i = 0; i < TeamController.size; i++) ...<Widget>[
                _SlotCard(team: team, collection: collection, index: i),
                const SizedBox(height: 12),
              ],
              _SummaryCard(team: team),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBestTeam(BuildContext context, MetaController meta) async {
    unawaited(meta.ensureLoaded());
    final pick = await showModalBottomSheet<TeamProposal>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => BestTeamSheet(
        meta: meta,
        rows: collection.visibleRowsUnfiltered,
        repository: collection.repository,
        moves: collection.moves,
      ),
    );
    if (pick == null) return;
    // Vider d'abord : un membre peut déjà occuper un autre emplacement.
    for (var i = 0; i < TeamController.size; i++) {
      team.setSpecies(i, null);
    }
    for (var i = 0; i < pick.members.length; i++) {
      final row = collection.rowOf(pick.members[i].id);
      if (row == null) continue;
      final e = row.entry;
      team.importFromCollection(
        i,
        e.id,
        row.species,
        fastId: e.fastMove,
        chargedIds: <String>[
          if (e.chargedMove1 != null) e.chargedMove1!,
          if (e.chargedMove2 != null) e.chargedMove2!,
        ],
      );
    }
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.team,
    required this.collection,
    required this.index,
  });

  final TeamController team;
  final CollectionController collection;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slot = team.slots[index];
    final species = slot.species;
    final defense = team.defenseOf(index);
    final offense = team.offenseOf(index);
    return Card(
      key: ValueKey<String>('slot-$index'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Pokémon ${index + 1}', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (species != null) ...<Widget>[
                  for (final t in species.types)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: TypeBadge(t, size: 28),
                    ),
                  IconButton(
                    tooltip: 'Retirer le Pokémon ${index + 1}',
                    icon: const Icon(Icons.close),
                    onPressed: () => team.setSpecies(index, null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _SpeciesField(
              key: ValueKey<String>('species-$index-${species?.nameFr}'),
              repository: team.repository,
              initial: species?.nameFr ?? '',
              label: 'Pokémon ${index + 1} (nom ou numéro)',
              onSelected: (s) => team.setSpecies(index, s),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                if (slot.collectionId != null)
                  Tooltip(
                    key: ValueKey<String>('imported-$index'),
                    message: 'Importé de ta collection',
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 30),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.collections_bookmark,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _import(context),
                  icon: const Icon(Icons.collections_bookmark_outlined),
                  label: const Text('Importer de ma collection'),
                ),
              ],
            ),
            if (species != null) ...<Widget>[
              const SizedBox(height: 10),
              _MovePicker(
                species: species,
                label: 'Attaque immédiate',
                value: slot.fast,
                options: team.fastOptions(index),
                onChanged: (m) => team.setFast(index, m),
              ),
              const SizedBox(height: 8),
              _MovePicker(
                species: species,
                label: 'Attaque chargée 1',
                value: slot.charged1,
                options: team.chargedOptionsFor(index, 1),
                onChanged: (m) => team.setCharged(index, 1, m),
              ),
              const SizedBox(height: 8),
              _MovePicker(
                species: species,
                label: 'Attaque chargée 2',
                value: slot.charged2,
                options: team.chargedOptionsFor(index, 2),
                onChanged: (m) => team.setCharged(index, 2, m),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: InfoButton(
                  '$eliteLegend · nombre : puissance en combat',
                  key: ValueKey<String>('info-moves-$index'),
                ),
              ),
            ],
            if (defense != null) ...<Widget>[
              const SizedBox(height: 14),
              _SectionTitle('Défense · selon ses types'),
              _ChipLine(
                label: 'Faible à',
                color: _bad,
                children: <Widget>[
                  for (final w in defense.weaknesses)
                    TypeChip(w.type, factor: w.factor),
                ],
              ),
              _ChipLine(
                label: 'Résiste à',
                color: _good,
                children: <Widget>[
                  for (final r in defense.resistances)
                    TypeChip(r.type, factor: r.factor),
                ],
              ),
            ],
            if (species != null) ...<Widget>[
              const SizedBox(height: 10),
              _SectionTitle('Attaque · selon ses attaques'),
              if (offense == null)
                Text(
                  'Choisis ses attaques pour voir ses cibles.',
                  style: theme.textTheme.bodySmall,
                )
              else ...<Widget>[
                _ChipLine(
                  label: 'Efficace contre',
                  color: _good,
                  children: <Widget>[
                    for (final t in offense.effectiveAgainst) TypeChip(t),
                  ],
                ),
                _ChipLine(
                  label: 'En difficulté contre',
                  color: _bad,
                  children: <Widget>[
                    for (final t in offense.strugglesAgainst) TypeChip(t),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final taken = team.importedIds(except: index);
    final entry = await showModalBottomSheet<CollectionEntry>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ImportSheet(
        rows: filterAndSort(
          collection.visibleRowsUnfiltered,
          const CollectionFilter(),
          CollectionSort.name,
        ),
        taken: taken,
        current: team.slots[index].collectionId,
      ),
    );
    if (entry == null) return;
    final species = team.repository.findByName(entry.speciesName);
    if (species == null) return;
    team.importFromCollection(
      index,
      entry.id,
      species,
      fastId: entry.fastMove,
      chargedIds: <String>[
        if (entry.chargedMove1 != null) entry.chargedMove1!,
        if (entry.chargedMove2 != null) entry.chargedMove2!,
      ],
    );
  }
}

class _SpeciesField extends StatelessWidget {
  const _SpeciesField({
    super.key,
    required this.repository,
    required this.initial,
    required this.label,
    required this.onSelected,
  });

  final SpeciesRepository repository;
  final String initial;
  final String label;
  final ValueChanged<Species> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Species>(
      initialValue: TextEditingValue(text: initial),
      displayStringForOption: (s) => s.nameFr,
      optionsBuilder: (value) {
        final text = value.text.trim();
        if (text.isEmpty) return const <Species>[];
        final exact = repository.lookup(text);
        final list = <Species>[
          if (exact != null) exact,
          for (final s in repository.suggest(text, max: 8))
            if (!identical(s, exact)) s,
        ];
        return list;
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focus, onSubmit) => SearchField(
        controller: controller,
        focusNode: focus,
        label: label,
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

class _MovePicker extends StatelessWidget {
  const _MovePicker({
    required this.species,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final Species species;
  final String label;
  final Move? value;
  final List<Move> options;
  final ValueChanged<Move?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value;
    final small = Theme.of(context).textTheme.bodySmall;
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('$label-${current?.id}'),
      initialValue: current?.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(child: Text('Aucune')),
        for (final m in options)
          DropdownMenuItem<String>(
            value: m.id,
            child: Row(
              children: <Widget>[
                TypeBadge(m.type, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    moveLabel(m, species),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${m.power}', style: small),
              ],
            ),
          ),
      ],
      onChanged: (id) {
        Move? picked;
        for (final m in options) {
          if (m.id == id) picked = m;
        }
        onChanged(picked);
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.team});

  final TeamController team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = team.slots.where((s) => s.species != null).length;
    if (filled == 0) {
      return Text(
        'Ajoute tes Pokémon pour voir le bilan de l\'équipe.',
        style: theme.textTheme.bodyMedium,
      );
    }
    final summary = team.summary;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Bilan de l\'équipe',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _Stat(
                  key: const ValueKey<String>('stat-coverage'),
                  value: '${summary.coverage.length}/18',
                  label: 'types touchés\nen super efficace',
                ),
                const SizedBox(width: 8),
                _Stat(
                  key: const ValueKey<String>('stat-resisted'),
                  value: '${summary.resisted.length}/18',
                  label: 'types résistés\npar au moins un',
                ),
                const SizedBox(width: 8),
                _Stat(
                  key: const ValueKey<String>('stat-shared'),
                  value: '${summary.sharedWeaknesses.length}',
                  label: 'faiblesses\npartagées',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ChipLine(
              collapsible: true,
              label: 'Super efficace contre (${summary.coverage.length}/18)',
              color: _good,
              empty: 'Choisis des attaques pour voir la couverture',
              children: <Widget>[
                for (final t in summary.coverage) TypeChip(t),
              ],
            ),
            _ChipLine(
              collapsible: true,
              label: 'Types d\'attaque de l\'équipe',
              color: _good,
              empty: 'Aucune attaque choisie',
              children: <Widget>[
                for (final t in summary.moveTypes) TypeChip(t),
              ],
            ),
            _ChipLine(
              collapsible: true,
              label: 'Au moins un résiste à (${summary.resisted.length}/18)',
              color: _good,
              children: <Widget>[
                for (final t in summary.resisted) TypeChip(t),
              ],
            ),
            _ChipLine(
              collapsible: true,
              label: 'Faiblesses partagées',
              color: _bad,
              empty: 'Aucune : bonne complémentarité',
              children: <Widget>[
                for (final t in summary.sharedWeaknesses) TypeChip(t),
              ],
            ),
            _ChipLine(
              collapsible: true,
              label: 'Personne ne résiste à',
              color: _bad,
              empty: 'Chaque type est résisté par au moins un',
              children: <Widget>[
                for (final t in summary.unresisted) TypeChip(t),
              ],
            ),
            _ChipLine(
              collapsible: true,
              label: 'Aucune attaque efficace contre',
              color: _bad,
              empty: 'Les 18 types sont couverts',
              children: <Widget>[
                for (final t in summary.uncovered) TypeChip(t),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChipLine extends StatefulWidget {
  const _ChipLine({
    required this.label,
    required this.color,
    required this.children,
    this.empty = 'Aucun',
    this.collapsible = false,
  });

  final String label;
  final Color color;
  final List<Widget> children;
  final String empty;

  /// Vrai pour une rubrique repliable d'un appui (ouverte par défaut).
  final bool collapsible;

  @override
  State<_ChipLine> createState() => _ChipLineState();
}

class _ChipLineState extends State<_ChipLine> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(widget.label, style: theme.textTheme.labelMedium)),
        if (widget.collapsible) ...<Widget>[
          if (!_open)
            Text(
              '${widget.children.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          Icon(_open ? Icons.expand_less : Icons.expand_more, size: 20),
        ],
      ],
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.collapsible ? 2 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.collapsible)
            Semantics(
              button: true,
              expanded: _open,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: header,
                ),
              ),
            )
          else
            header,
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: widget.children.isEmpty
                        ? Text(widget.empty, style: theme.textTheme.bodySmall)
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.children,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ImportSheet extends StatelessWidget {
  const _ImportSheet({
    required this.rows,
    required this.taken,
    required this.current,
  });

  final List<CollectionRow> rows;
  final Set<String> taken;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Importer de ma collection',
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              'Ta collection est vide : enregistre d\'abord des Pokémon '
              'depuis l\'écran de rang.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final row = rows[i];
                final e = row.entry;
                final inTeam = taken.contains(e.id);
                final here = e.id == current;
                return Opacity(
                  opacity: inTeam ? 0.45 : 1,
                  child: Card(
                    key: ValueKey<String>('import-${e.id}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    color: tileColor(context, row),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: tileBorder(context, row),
                    ),
                    child: ListTile(
                      enabled: !inTeam,
                      onTap: inTeam ? null : () => Navigator.of(context).pop(e),
                      leading: TypeBadge(
                        row.species.types.isEmpty
                            ? PokeType.normal
                            : row.species.types.first,
                        size: 32,
                      ),
                      title: Text(row.species.nameFr),
                      subtitle: Text(
                        inTeam
                            ? 'Déjà dans l\'équipe'
                            : '${e.league.label} · rang ${formatGrouped(e.rank)}'
                                ' · ${e.iv.atk}/${e.iv.def}/${e.iv.sta}'
                                '${here ? ' · ici' : ''}',
                      ),
                      trailing: EntryAttributes(e),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
