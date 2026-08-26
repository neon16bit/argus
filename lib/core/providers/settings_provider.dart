import 'package:argus/core/constants.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kScrapeModeFull = 'scrape_mode_full';
const _kScrapeDelayMs = 'scrape_delay_ms';
const _kThemeFlavor = 'theme_flavor';
const _kAccentColor = 'accent_color';
const _kPureBlack = 'pure_black';
const _kUseExternalPlayer = 'use_external_player';

class AppSettings {
  final bool fullScrapeMode;
  final Duration scrapeDelay;
  final String themeFlavor;
  final String accentColor;
  final bool pureBlack;
  final bool useExternalPlayer;

  const AppSettings({
    this.fullScrapeMode = false,
    this.scrapeDelay = kDefaultScrapeDelay,
    this.themeFlavor = 'system',
    this.accentColor = 'mauve',
    this.pureBlack = false,
    this.useExternalPlayer = false,
  });

  AppSettings copyWith({
    bool? fullScrapeMode,
    Duration? scrapeDelay,
    String? themeFlavor,
    String? accentColor,
    bool? pureBlack,
    bool? useExternalPlayer,
  }) {
    return AppSettings(
      fullScrapeMode: fullScrapeMode ?? this.fullScrapeMode,
      scrapeDelay: scrapeDelay ?? this.scrapeDelay,
      themeFlavor: themeFlavor ?? this.themeFlavor,
      accentColor: accentColor ?? this.accentColor,
      pureBlack: pureBlack ?? this.pureBlack,
      useExternalPlayer: useExternalPlayer ?? this.useExternalPlayer,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppSettings(
      fullScrapeMode: prefs.getBool(_kScrapeModeFull) ?? false,
      scrapeDelay: Duration(
        milliseconds:
            prefs.getInt(_kScrapeDelayMs) ?? kDefaultScrapeDelay.inMilliseconds,
      ),
      themeFlavor: prefs.getString(_kThemeFlavor) ?? 'system',
      accentColor: prefs.getString(_kAccentColor) ?? 'mauve',
      pureBlack: prefs.getBool(_kPureBlack) ?? false,
      useExternalPlayer: prefs.getBool(_kUseExternalPlayer) ?? false,
    );
  }

  Future<void> setFullScrapeMode(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kScrapeModeFull, value);
    state = state.copyWith(fullScrapeMode: value);
  }

  Future<void> setScrapeDelay(Duration value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_kScrapeDelayMs, value.inMilliseconds);
    state = state.copyWith(scrapeDelay: value);
  }

  Future<void> setThemeFlavor(String flavor) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kThemeFlavor, flavor);
    state = state.copyWith(themeFlavor: flavor);
  }

  Future<void> setAccentColor(String accent) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kAccentColor, accent);
    state = state.copyWith(accentColor: accent);
  }

  Future<void> setPureBlack(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kPureBlack, value);
    state = state.copyWith(pureBlack: value);
  }

  Future<void> setUseExternalPlayer(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kUseExternalPlayer, value);
    state = state.copyWith(useExternalPlayer: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
