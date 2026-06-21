import 'package:argus/core/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      fullScrapeMode: prefs.getBool(_kScrapeModeFull) ?? false,
      scrapeDelay: Duration(
        milliseconds:
            prefs.getInt(_kScrapeDelayMs) ?? kDefaultScrapeDelay.inMilliseconds,
      ),
    );
  }

  Future<void> setFullScrapeMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kScrapeModeFull, value);
    state = AsyncData(
      AppSettings(
        fullScrapeMode: value,
        scrapeDelay: state.value?.scrapeDelay ?? kDefaultScrapeDelay,
      ),
    );
  }

  Future<void> setScrapeDelay(Duration value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kScrapeDelayMs, value.inMilliseconds);
    state = AsyncData(
      AppSettings(
        fullScrapeMode: state.value?.fullScrapeMode ?? false,
        scrapeDelay: value,
      ),
    );
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
