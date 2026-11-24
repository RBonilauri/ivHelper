import 'package:material_ui/material_ui.dart';

import '../core/collection.dart';
import '../core/meta.dart';
import '../core/moves.dart';
import '../core/screen_reading.dart';
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

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _Mode.bubble => _Bubble(onTap: _scanScreen),
      _Mode.scanning => const _Bubble(busy: true),
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
                  onPressed: widget.window.stopAll,
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
