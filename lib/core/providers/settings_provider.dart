import 'package:argus/core/constants.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kScrapeModeFull = 'scrape_mode_full';
const _kScrapeDelayMs = 'scrape_delay_ms';

class AppSettings {
  final bool fullScrapeMode;
  final Duration scrapeDelay;

  const AppSettings({
    this.fullScrapeMode = false,
    this.scrapeDelay = kDefaultScrapeDelay,
  });
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
    );
  }

  Future<void> setFullScrapeMode(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kScrapeModeFull, value);
    state = AppSettings(fullScrapeMode: value, scrapeDelay: state.scrapeDelay);
  }

  Future<void> setScrapeDelay(Duration value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_kScrapeDelayMs, value.inMilliseconds);
    state = AppSettings(
      fullScrapeMode: state.fullScrapeMode,
      scrapeDelay: value,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
