import 'package:material_ui/material_ui.dart';

const Color _yellow = Color(0xFFFFCB05);
const Color _navy = Color(0xFF1D2A5B);

/// Thème global jaune, clair ou sombre.
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: _yellow,
    brightness: brightness,
  );
  final scheme = base.copyWith(
    primary: dark ? _yellow : const Color(0xFFF2B800),
    onPrimary: _navy,
    primaryContainer: dark ? const Color(0xFF5C4A00) : const Color(0xFFFFEFA8),
    onPrimaryContainer: dark ? const Color(0xFFFFEFA8) : _navy,
    secondary: dark ? const Color(0xFF8FA2FF) : _navy,
    onSecondary: dark ? _navy : Colors.white,
    surface: dark ? const Color(0xFF14161F) : const Color(0xFFFFFBEB),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF1C1F2B) : _yellow,
      foregroundColor: dark ? _yellow : _navy,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1C1F2B) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: _navy,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? _navy : scheme.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      thumbColor: scheme.primary,
    ),
  );
}
