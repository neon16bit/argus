import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:argus/theme/app_theme.dart';
import 'package:argus/core/providers/settings_provider.dart';

class AppThemeState {
  final ThemeData theme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;

  const AppThemeState({
    required this.theme,
    required this.darkTheme,
    required this.themeMode,
  });
}

class DynamicColorScheme {
  final ColorScheme light;
  final ColorScheme dark;
  const DynamicColorScheme({required this.light, required this.dark});
}

class DynamicColorsNotifier extends Notifier<DynamicColorScheme?> {
  @override
  DynamicColorScheme? build() {
    _loadDynamicColors();
    return null;
  }

  Future<void> _loadDynamicColors() async {
    try {
      final corePalette = await DynamicColorPlugin.getCorePalette();
      if (corePalette != null) {
        state = DynamicColorScheme(
          light: corePalette.toColorScheme(brightness: Brightness.light),
          dark: corePalette.toColorScheme(brightness: Brightness.dark),
        );
      }
    } catch (_) {
      // Ignored, state remains null
    }
  }

  void update(DynamicColorScheme? value) {
    state = value;
  }
}

final dynamicColorSchemeProvider =
    NotifierProvider<DynamicColorsNotifier, DynamicColorScheme?>(
      DynamicColorsNotifier.new,
    );

final appThemeProvider = Provider<AppThemeState>((ref) {
  final settings = ref.watch(settingsProvider);
  final dynamicColors = ref.watch(dynamicColorSchemeProvider);

  // resolve theme mode
  final ThemeMode themeMode;
  if (settings.themeFlavor == 'system') {
    themeMode = ThemeMode.system;
  } else if (settings.themeFlavor == 'latte') {
    themeMode = ThemeMode.light;
  } else {
    themeMode = ThemeMode.dark;
  }

  // resolve light theme
  Color? lightCustomAccent;
  if (settings.accentColor == 'material_you') {
    lightCustomAccent = dynamicColors?.light.primary;
  }
  final lightTheme = AppTheme.getTheme(
    'latte',
    settings.accentColor,
    customAccent: lightCustomAccent,
  );

  // resolve dark theme
  Color? darkCustomAccent;
  if (settings.accentColor == 'material_you') {
    darkCustomAccent = dynamicColors?.dark.primary;
  }
  final darkFlavor =
      settings.themeFlavor == 'system' || settings.themeFlavor == 'latte'
      ? 'mocha'
      : settings.themeFlavor;
  final darkTheme = AppTheme.getTheme(
    darkFlavor,
    settings.accentColor,
    customAccent: darkCustomAccent,
    usePureBlack: settings.pureBlack,
  );

  return AppThemeState(
    theme: lightTheme,
    darkTheme: darkTheme,
    themeMode: themeMode,
  );
});
