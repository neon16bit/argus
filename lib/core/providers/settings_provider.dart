import 'package:argus/core/constants.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kScrapeDelayMs = 'scrape_delay_ms';
const _kThemeFlavor = 'theme_flavor';
const _kAccentColor = 'accent_color';
const _kPureBlack = 'pure_black';
const _kUseExternalPlayer = 'use_external_player';
const _kTvdbApiKey = 'tvdb_api_key';

const bool kIsFdroidBuild =
    bool.fromEnvironment('IS_FDROID_BUILD') ||
    String.fromEnvironment('TVDB_API_KEY') == '';

class AppSettings {
  final Duration scrapeDelay;
  final String themeFlavor;
  final String accentColor;
  final bool pureBlack;
  final bool useExternalPlayer;
  final String tvdbApiKey;

  const AppSettings({
    this.scrapeDelay = kDefaultScrapeDelay,
    this.themeFlavor = 'system',
    this.accentColor = 'mauve',
    this.pureBlack = false,
    this.useExternalPlayer = false,
    this.tvdbApiKey = '',
  });

  bool get hasCustomTvdbKey => tvdbApiKey.trim().isNotEmpty;
  bool get isFdroidBuild => kIsFdroidBuild;

  AppSettings copyWith({
    Duration? scrapeDelay,
    String? themeFlavor,
    String? accentColor,
    bool? pureBlack,
    bool? useExternalPlayer,
    String? tvdbApiKey,
  }) {
    return AppSettings(
      scrapeDelay: scrapeDelay ?? this.scrapeDelay,
      themeFlavor: themeFlavor ?? this.themeFlavor,
      accentColor: accentColor ?? this.accentColor,
      pureBlack: pureBlack ?? this.pureBlack,
      useExternalPlayer: useExternalPlayer ?? this.useExternalPlayer,
      tvdbApiKey: tvdbApiKey ?? this.tvdbApiKey,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);

    return AppSettings(
      scrapeDelay: Duration(
        milliseconds:
            prefs.getInt(_kScrapeDelayMs) ?? kDefaultScrapeDelay.inMilliseconds,
      ),
      themeFlavor: prefs.getString(_kThemeFlavor) ?? 'system',
      accentColor: prefs.getString(_kAccentColor) ?? 'mauve',
      pureBlack: prefs.getBool(_kPureBlack) ?? false,
      useExternalPlayer: prefs.getBool(_kUseExternalPlayer) ?? false,
      tvdbApiKey: prefs.getString(_kTvdbApiKey) ?? '',
    );
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

  Future<void> setTvdbApiKey(String apiKey) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final cleanKey = apiKey.trim();

    if (cleanKey.isEmpty) {
      await prefs.remove(_kTvdbApiKey);
      state = state.copyWith(tvdbApiKey: '');
    } else {
      await prefs.setString(_kTvdbApiKey, cleanKey);
      state = state.copyWith(tvdbApiKey: cleanKey);
    }
  }

  Future<void> clearTvdbApiKey() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kTvdbApiKey);
    state = state.copyWith(tvdbApiKey: '');
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
