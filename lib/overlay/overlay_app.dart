import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/meta.dart';
import '../core/moves.dart';
import '../core/power_up.dart';
import '../core/rank_table.dart';
import '../core/screen_reading.dart';
import '../core/search_string.dart';
import '../core/species_repository.dart';
import '../core/stats.dart';
import '../settings/settings_controller.dart';
import '../state/collection_controller.dart';
import '../ui/app_theme.dart';
import '../ui/family_rank_table.dart';
import '../ui/format.dart';
import '../ui/iv_bar.dart';
import '../ui/iv_logo.dart';
import '../ui/save_pokemon_sheet.dart';
import '../ui/search_field.dart';
import 'overlay_services.dart';

/// Application affichée dans la fenêtre flottante, par-dessus le jeu.
class OverlayApp extends StatelessWidget {
  /// Crée l'application de la pastille.
  const OverlayApp({
    super.key,
    required this.repository,
    required this.moves,
    required this.settings,
    required this.scanner,
    required this.window,
    this.meta,
  });

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Attaques connues.
  final MoveBook moves;

  /// Réglages (thème) et stockage partagé avec l'app.
  final SettingsController settings;

  /// Lecture de l'écran.
  final ScreenScanner scanner;

  /// Fenêtre flottante.
  final OverlayWindow window;

  /// Méta pour mettre en gras les attaques recommandées.
  final MetaSnapshot? meta;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ivHelper',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      home: OverlayHome(
        repository: repository,
        moves: moves,
        store: settings.store,
        scanner: scanner,
        window: window,
        meta: meta,
      ),
    );
  }
}

enum _Mode { bubble, scanning, panel }

/// En dessous de ce côté (dp), la fenêtre est une pastille : le panneau n'y
/// tient pas. Le moteur de la pastille survit à la fermeture de la fenêtre ;
/// relancée depuis l'app, elle revient en pastille alors que l'état peut être
/// resté en panneau (le coin blanc du panneau, sans bouton, restait affiché).
const double _panelMinSide = 120;

/// Pastille, puis panneau de résultats après lecture de l'écran.
class OverlayHome extends StatefulWidget {
  /// Crée l'écran de la pastille.
  const OverlayHome({
    super.key,
    required this.repository,
    required this.moves,
    required this.store,
    required this.scanner,
    required this.window,
    this.meta,
  });

  /// Espèces connues.
  final SpeciesRepository repository;

  /// Attaques connues.
  final MoveBook moves;

  /// Stockage partagé avec l'app (collection).
  final SettingsStore store;

  /// Lecture de l'écran.
  final ScreenScanner scanner;

  /// Fenêtre flottante.
  final OverlayWindow window;

  /// Méta pour les attaques recommandées.
  final MetaSnapshot? meta;

  @override
  State<OverlayHome> createState() => _OverlayHomeState();
}

class _OverlayHomeState extends State<OverlayHome> {
  _Mode _mode = _Mode.bubble;
  ScanResult? _scan;
  String? _error;
  Species? _species;
  List<Species> _family = const <Species>[];
  Iv _iv = const Iv(15, 15, 15);
  double _maxLevel = 51;
  Species? _selected;
  League _league = League.great;
  bool _lucky = false;
  ShadowState _shadowState = ShadowState.none;
  late final CollectionController _collection = CollectionController(
    repository: widget.repository,
    moves: widget.moves,
    store: widget.store,
  );

  @override
  void dispose() {
    _collection.dispose();
    super.dispose();
  }

  Future<void> _scanScreen() async {
    setState(() {
      _mode = _Mode.scanning;
      _error = null;
    });
    ScanResult? result;
    String? error;
    try {
      result = await widget.scanner.scan();
    } on Object catch (e) {
      error = describeScanError(e);
    }
    if (!mounted) return;
    await widget.window.showPanel();
    final species = result?.species;
    setState(() {
      _mode = _Mode.panel;
      _scan = result;
      _error = error ??
          (species == null
              ? 'Pokémon non reconnu : choisis-le ci-dessous.'
              : (result!.iv == null
                  ? 'Barres non trouvées : ouvre l\'évaluation (Évaluer) '
                      'puis relis, ou règle les IV à la main.'
                  : null));
      if (species != null) _setSpecies(species, family: result!.family);
      if (result?.iv != null) _iv = result!.iv!;
      _lucky = result?.text.lucky ?? false;
      _shadowState = (result?.text.shadow ?? false)
          ? ShadowState.shadow
          : ShadowState.none;
    });
  }

  void _setSpecies(Species species, {List<Species>? family}) {
    _species = species;
    _family = family ?? widget.repository.familyOf(species);
    _selected = species;
  }

  Future<void> _close() async {
    await widget.window.showBubble();
    if (mounted) setState(() => _mode = _Mode.bubble);
  }

  /// Ferme la pastille et revient en mode pastille pour la prochaine relance.
  Future<void> _stop() async {
    try {
      await widget.window.stopAll();
    } finally {
      if (mounted) {
        setState(() {
          _mode = _Mode.bubble;
          _error = null;
        });
      }
    }
  }

  Future<void> _save() async {
    final species = _selected;
    if (species == null) return;
    await _collection.load();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await showSaveSheet(
      context,
      SavePokemonSheet(
        species: species,
        iv: _iv,
        moves: widget.moves,
        initialLeague: _league,
        metaMoves: (s, league, shadow) =>
            widget.meta?.movesetForAnyLeague(
              s.nameFr,
              league.key,
              shadow: shadow == ShadowState.shadow,
            ) ??
            const <String>[],
        rankFor: (league) =>
            _collection.rankFor(species, _iv, _maxLevel, league),
        onSave: (options) {
          final entry = _collection.add(species, _iv, _maxLevel, options);
          messenger.showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 3),
              content: Text(
                '${species.nameFr} enregistré '
                '(${entry.league.label}, rang ${entry.rank})',
              ),
            ),
          );
        },
      ),
    );
  }

  /// Niveau actuel : recalculé avec les PC et PV lus pour l'espèce et les IV
  /// affichés (la lecture d'origine sinon). L'évolution garde le niveau.
  double? get _currentLevel {
    final scan = _scan;
    if (scan == null) return null;
    final cp = scan.text.cp;
    final hp = scan.text.hpMax;
    final species = _species;
    if (species != null && cp != null && hp != null) {
      final level = matchingLevel(species, _iv, cp, hp);
      if (level != null) return level;
    }
    return scan.level;
  }

  /// Copie le surnom `PVP#rang` du stade et de la ligue choisis.
  Future<void> _copyNickname(String nickname) async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = await widget.window.copyText(nickname);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            copied
                ? '$nickname copié : colle-le comme surnom dans le jeu.'
                : 'Copie impossible : écris $nickname comme surnom.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tiny = MediaQuery.sizeOf(context).shortestSide < _panelMinSide;
    return switch (_mode) {
      _Mode.bubble => _Bubble(onTap: _scanScreen),
      _Mode.scanning => const _Bubble(busy: true),
      _Mode.panel when tiny => _Bubble(onTap: _scanScreen),
      _Mode.panel => _panel(context),
    };
  }

  Widget _panel(BuildContext context) {
    final theme = Theme.of(context);
    final scan = _scan;
    final species = _species;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: <Widget>[
            Row(
              children: <Widget>[
                const IvLogo(size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('ivHelper', style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Relire l\'écran',
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await widget.window.showBubble();
                    await _scanScreen();
                  },
                ),
                IconButton(
                  tooltip: 'Réduire',
                  icon: const Icon(Icons.close_fullscreen),
                  onPressed: _close,
                ),
                IconButton(
                  tooltip: 'Arrêter la superposition',
                  icon: const Icon(Icons.power_settings_new),
                  onPressed: _stop,
                ),
              ],
            ),
            if (_error != null)
              Container(
                key: const ValueKey<String>('scan-error'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3E3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFF8A1C1C)),
                ),
              ),
            if (scan != null)
              Text(
                <String>[
                  if (species != null) species.nameFr,
                  if (scan.text.cp != null) 'PC ${scan.text.cp}',
                  if (scan.text.hpMax != null) 'PV ${scan.text.hpMax}',
                  if (scan.level != null) 'niveau ${formatLevel(scan.level!)}',
                ].join(' · '),
                key: const ValueKey<String>('scan-summary'),
                style: theme.textTheme.titleSmall,
              ),
            const SizedBox(height: 8),
            _SpeciesPicker(
              key: ValueKey<String>('picker-${species?.nameFr}'),
              repository: widget.repository,
              initial: species?.nameFr ?? '',
              onSelected: (s) => setState(() => _setSpecies(s)),
            ),
            const SizedBox(height: 8),
            IvBar(
              label: 'Atk',
              value: _iv.atk,
              min: 0,
              onChanged: (v) => setState(() => _iv = Iv(v, _iv.def, _iv.sta)),
            ),
            IvBar(
              label: 'Déf',
              value: _iv.def,
              min: 0,
              onChanged: (v) => setState(() => _iv = Iv(_iv.atk, v, _iv.sta)),
            ),
            IvBar(
              label: 'PV',
              value: _iv.sta,
              min: 0,
              onChanged: (v) => setState(() => _iv = Iv(_iv.atk, _iv.def, v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Meilleur ami (niveau 51)'),
              value: _maxLevel == 51,
              onChanged: (v) => setState(() => _maxLevel = v ? 51 : 50),
            ),
            if (_family.isNotEmpty) ...<Widget>[
              FamilyRankTable(
                family: _family,
                iv: _iv,
                maxLevel: _maxLevel,
                current: scan?.species,
                selectedSpecies: _selected,
                selectedLeague: _league,
                onSelect: (s, l) => setState(() {
                  _selected = s;
                  _league = l;
                }),
              ),
              const SizedBox(height: 4),
              Text(
                'Touche une case pour choisir le stade et la ligue à '
                'enregistrer. • = stade affiché dans le jeu.',
                style: theme.textTheme.bodySmall,
              ),
              if (_selected != null) ...<Widget>[
                const SizedBox(height: 8),
                _LeagueDetails(
                  species: _selected!,
                  league: _league,
                  entry: _collection.rankFor(
                    _selected!,
                    _iv,
                    _maxLevel,
                    _league,
                  ),
                  meta: widget.meta,
                  currentLevel: _currentLevel,
                  evolves: _selected != _species,
                  lucky: _lucky,
                  shadow: _shadowState,
                  onLucky: (v) => setState(() => _lucky = v),
                  onShadow: (v) => setState(() {
                    _shadowState = v;
                    if (v == ShadowState.shadow) _lucky = false;
                  }),
                ),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _selected == null ? null : _save,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(
                  _selected == null
                      ? 'Enregistrer'
                      : 'Enregistrer ${_selected!.nameFr} (${_league.label})',
                ),
              ),
              if (_selected != null) ...<Widget>[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final nickname = pvpNickname(
                      _collection
                          .rankFor(_selected!, _iv, _maxLevel, _league)
                          .rank,
                    );
                    return OutlinedButton.icon(
                      key: const ValueKey<String>('copy-nickname'),
                      onPressed: () => _copyNickname(nickname),
                      icon: const Icon(Icons.copy),
                      label: Text('Copier $nickname'),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({this.onTap, this.busy = false});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          key: const ValueKey<String>('overlay-bubble'),
          onTap: busy ? null : onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x55000000), blurRadius: 6),
              ],
              color: busy ? const Color(0xFF1D2A5B) : null,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFFFCB05),
                    ),
                  )
                : const ClipOval(child: IvLogo(size: 56)),
          ),
        ),
      ),
    );
  }
}

class _SpeciesPicker extends StatelessWidget {
  const _SpeciesPicker({
    super.key,
    required this.repository,
    required this.initial,
    required this.onSelected,
  });

  final SpeciesRepository repository;
  final String initial;
  final ValueChanged<Species> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Species>(
      initialValue: TextEditingValue(text: initial),
      displayStringForOption: (s) => s.nameFr,
      optionsBuilder: (value) {
        final text = value.text.trim();
        if (text.isEmpty || text == initial) return const <Species>[];
        final exact = repository.lookup(text);
        return <Species>[
          if (exact != null) exact,
          for (final s in repository.suggest(text, max: 6))
            if (!identical(s, exact)) s,
        ];
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focus, onSubmit) => SearchField(
        controller: controller,
        focusNode: focus,
        label: 'Pokémon (corriger si besoin)',
        dense: true,
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

/// Rang dans la méta et coût pour monter le stade choisi au niveau de la
/// ligue choisie, selon chanceux, obscur ou purifié.
class _LeagueDetails extends StatelessWidget {
  const _LeagueDetails({
    required this.species,
    required this.league,
    required this.entry,
    required this.meta,
    required this.currentLevel,
    required this.evolves,
    required this.lucky,
    required this.shadow,
    required this.onLucky,
    required this.onShadow,
  });

  final Species species;
  final League league;
  final RankEntry entry;
  final MetaSnapshot? meta;
  final double? currentLevel;
  final bool evolves;
  final bool lucky;
  final ShadowState shadow;
  final ValueChanged<bool> onLucky;
  final ValueChanged<ShadowState> onShadow;

  String _metaLine() {
    final metaLeague = MetaLeague.fromKey(league.key);
    if (metaLeague == null) return 'Pas de méta en ligue ${league.label}';
    final data = meta;
    if (data == null) return 'Méta indisponible';
    final e = data.entryFor(
      species.nameFr,
      metaLeague,
      shadow: shadow == ShadowState.shadow,
    );
    return e == null
        ? 'Absent de la méta ${metaLeague.label}'
        : 'Méta ${metaLeague.label} : n° ${e.rank}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = currentLevel;
    final target = entry.level;
    final cost = from == null
        ? null
        : powerUpCost(from, target, lucky: lucky, shadow: shadow);
    return Card(
      key: const ValueKey<String>('league-details'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _metaLine(),
              key: const ValueKey<String>('meta-rank'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: <Widget>[
                FilterChip(
                  label: const Text('Chanceux'),
                  selected: lucky,
                  onSelected: shadow == ShadowState.shadow ? null : onLucky,
                ),
                FilterChip(
                  label: const Text('Obscur'),
                  selected: shadow == ShadowState.shadow,
                  onSelected: (on) =>
                      onShadow(on ? ShadowState.shadow : ShadowState.none),
                ),
                FilterChip(
                  label: const Text('Purifié'),
                  selected: shadow == ShadowState.purified,
                  onSelected: (on) =>
                      onShadow(on ? ShadowState.purified : ShadowState.none),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (from == null)
              Text(
                'Niveau actuel inconnu : relis l\'écran pour calculer le coût.',
                style: theme.textTheme.bodySmall,
              )
            else if (cost == null)
              Text(
                'Déjà au-dessus du niveau visé (${formatLevel(target)}) : '
                'trop de PC pour la ligue ${league.label}.',
                style: theme.textTheme.bodySmall,
              )
            else ...<Widget>[
              Text(
                'Niveau ${formatLevel(from)} → ${formatLevel(target)} · '
                '${cost.powerUps} amélioration${cost.powerUps > 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: <Widget>[
                  _CostItem(
                    icon: Icons.auto_awesome,
                    valueKey: 'cost-stardust',
                    value: cost.stardust,
                    label: 'poussières',
                  ),
                  _CostItem(
                    icon: Icons.circle,
                    valueKey: 'cost-candy',
                    value: cost.candy,
                    label: 'bonbons',
                  ),
                  if (cost.xlCandy > 0)
                    _CostItem(
                      icon: Icons.hexagon,
                      valueKey: 'cost-xl',
                      value: cost.xlCandy,
                      label: 'bonbons L',
                    ),
                ],
              ),
              if (target > 50 || evolves)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    <String>[
                      if (target > 50)
                        'Niveau 51 : bonus de meilleur ami, sans coût.',
                      if (evolves)
                        'Sans le coût d\'évolution en ${species.nameFr}.',
                    ].join(' '),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CostItem extends StatelessWidget {
  const _CostItem({
    required this.icon,
    required this.valueKey,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String valueKey;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          formatGrouped(value),
          key: ValueKey<String>(valueKey),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(width: 3),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

