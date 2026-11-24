import 'package:material_ui/material_ui.dart';

const Color _yellow = Color(0xFFFFCB05);
const Color _navy = Color(0xFF1D2A5B);

/// Palette sombre : or adouci sur gris bleuté, pour ne pas éblouir la nuit.
const Color _gold = Color(0xFFE2BE5A);
const Color _goldContainer = Color(0xFF3A3222);
const Color _onGoldContainer = Color(0xFFF1E1B0);
const Color _nightSurface = Color(0xFF121318);
const Color _nightBar = Color(0xFF1A1C23);
const Color _nightField = Color(0xFF1E2028);
const Color _nightText = Color(0xFFE8E4D8);

/// Thème global jaune, clair ou sombre.
ThemeData buildTheme(Brightness brightness) {
  return brightness == Brightness.dark ? _dark() : _light();
}

ThemeData _light() {
  final scheme = ColorScheme.fromSeed(seedColor: _yellow).copyWith(
    primary: const Color(0xFFF2B800),
    onPrimary: _navy,
    primaryContainer: const Color(0xFFFFEFA8),
    onPrimaryContainer: _navy,
    secondary: _navy,
    onSecondary: Colors.white,
    surface: const Color(0xFFFFFBEB),
  );
  return _common(
    scheme,
    barBackground: _yellow,
    barForeground: _navy,
    fieldFill: Colors.white,
    selectedBackground: scheme.primary,
    selectedForeground: _navy,
    thumbOn: _navy,
    outlinedForeground: _navy,
  );
}

ThemeData _dark() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _gold,
    brightness: Brightness.dark,
  ).copyWith(
    primary: _gold,
    onPrimary: const Color(0xFF2A2210),
    primaryContainer: _goldContainer,
    onPrimaryContainer: _onGoldContainer,
    secondary: const Color(0xFF9DAEE8),
    onSecondary: _navy,
    surface: _nightSurface,
    onSurface: _nightText,
  );
  return _common(
    scheme,
    barBackground: _nightBar,
    barForeground: _nightText,
    fieldFill: _nightField,
    selectedBackground: _goldContainer,
    selectedForeground: _onGoldContainer,
    thumbOn: _gold,
    outlinedForeground: _gold,
  );
}

ThemeData _common(
  ColorScheme scheme, {
  required Color barBackground,
  required Color barForeground,
  required Color fieldFill,
  required Color selectedBackground,
  required Color selectedForeground,
  required Color thumbOn,
  required Color outlinedForeground,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: barBackground,
      foregroundColor: barForeground,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    drawerTheme: DrawerThemeData(backgroundColor: scheme.surface),
    cardTheme: CardThemeData(
      elevation: 0,
      color: fieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      // Champ vide : l'indication est grise et en italique ; une fois remontée
      // au-dessus du texte, l'étiquette reprend un style normal.
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      floatingLabelStyle: const TextStyle(fontStyle: FontStyle.normal),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: selectedBackground,
        selectedForegroundColor: selectedForeground,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? thumbOn : scheme.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: outlinedForeground,
        side: BorderSide(color: outlinedForeground.withValues(alpha: 0.6)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      thumbColor: scheme.primary,
    ),
  );
}
