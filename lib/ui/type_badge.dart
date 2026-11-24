import 'package:material_ui/material_ui.dart';

import '../core/poke_type.dart';

/// Couleur associée à chaque type.
const Map<PokeType, Color> typeColors = <PokeType, Color>{
  PokeType.normal: Color(0xFF9099A1),
  PokeType.fire: Color(0xFFFF9C54),
  PokeType.water: Color(0xFF4D90D5),
  PokeType.grass: Color(0xFF63BB5B),
  PokeType.electric: Color(0xFFF3D23B),
  PokeType.ice: Color(0xFF74CEC0),
  PokeType.fighting: Color(0xFFCE4069),
  PokeType.poison: Color(0xFFAB6AC8),
  PokeType.ground: Color(0xFFD97746),
  PokeType.flying: Color(0xFF8FA8DD),
  PokeType.psychic: Color(0xFFF97176),
  PokeType.bug: Color(0xFF90C12C),
  PokeType.rock: Color(0xFFC7B78B),
  PokeType.ghost: Color(0xFF5269AC),
  PokeType.dragon: Color(0xFF0A6DC4),
  PokeType.dark: Color(0xFF5A5366),
  PokeType.steel: Color(0xFF5A8EA1),
  PokeType.fairy: Color(0xFFEC8FE6),
};

/// Pictogramme associé à chaque type.
const Map<PokeType, IconData> typeIcons = <PokeType, IconData>{
  PokeType.normal: Icons.radio_button_unchecked,
  PokeType.fire: Icons.local_fire_department,
  PokeType.water: Icons.water_drop,
  PokeType.grass: Icons.eco,
  PokeType.electric: Icons.bolt,
  PokeType.ice: Icons.ac_unit,
  PokeType.fighting: Icons.sports_mma,
  PokeType.poison: Icons.science,
  PokeType.ground: Icons.terrain,
  PokeType.flying: Icons.air,
  PokeType.psychic: Icons.psychology,
  PokeType.bug: Icons.bug_report,
  PokeType.rock: Icons.landscape,
  PokeType.ghost: Icons.nights_stay,
  PokeType.dragon: Icons.cyclone,
  PokeType.dark: Icons.dark_mode,
  PokeType.steel: Icons.hexagon_outlined,
  PokeType.fairy: Icons.auto_awesome,
};

/// Pastille ronde d'un type : couleur du type, pictogramme blanc, anneau
/// optionnel (vert pour une force, rouge pour une faiblesse).
class TypeBadge extends StatelessWidget {
  /// Crée la pastille du type [type].
  const TypeBadge(this.type, {super.key, this.size = 36, this.ring});

  /// Type représenté.
  final PokeType type;

  /// Diamètre en pixels logiques.
  final double size;

  /// Couleur de l'anneau, ou `null` pour un anneau blanc discret.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final color = typeColors[type]!;
    final light = Color.lerp(color, Colors.white, 0.35)!;
    return Tooltip(
      message: type.nameFr,
      child: Semantics(
        label: type.nameFr,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[light, color],
            ),
            border: Border.all(
              color: ring ?? Colors.white.withValues(alpha: 0.85),
              width: size / 14,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: size / 6,
                offset: Offset(0, size / 18),
              ),
            ],
          ),
          child: ExcludeSemantics(
            child: Icon(
              typeIcons[type],
              color: Colors.white,
              size: size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille de type suivie de son nom.
class TypeChip extends StatelessWidget {
  /// Crée l'étiquette du type [type], avec un multiplicateur [factor] facultatif.
  const TypeChip(this.type, {super.key, this.factor});

  /// Type représenté.
  final PokeType type;

  /// Multiplicateur affiché après le nom, ou `null`.
  final double? factor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = factor;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 10, 2),
      decoration: BoxDecoration(
        color: typeColors[type]!.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(child: TypeBadge(type, size: 24)),
          const SizedBox(width: 6),
          Text(
            f == null ? type.nameFr : '${type.nameFr} ${formatFactor(f)}',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

/// Multiplicateur arrondi à deux décimales, avec une virgule : « ×1,6 ».
String formatFactor(double value) {
  final rounded = (value * 100).round() / 100;
  var text = rounded.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '×${text.replaceAll('.', ',')}';
}

/// Fond teinté par le premier de [types], adouci pour garder le texte lisible.
Color typeTint(BuildContext context, List<PokeType> types) {
  final scheme = Theme.of(context).colorScheme;
  if (types.isEmpty) return scheme.surfaceContainerHighest;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return Color.lerp(scheme.surface, typeColors[types.first], dark ? 0.32 : 0.26)!;
}
