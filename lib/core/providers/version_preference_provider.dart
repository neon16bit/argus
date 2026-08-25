import 'package:argus/core/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kPrefVersionPrefix = 'pref_version_';
const _kDubOverridePrefix = 'dub_override_';

class VersionPreferenceNotifier extends Notifier<Map<String, String?>> {
  @override
  Map<String, String?> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final map = <String, String?>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_kPrefVersionPrefix)) {
        final groupTitle = key.substring(_kPrefVersionPrefix.length);
        map[groupTitle] = prefs.getString(key);
      }
    }
    return map;
  }

  String? getPreferred(String groupTitle) {
    return state[groupTitle];
  }

  Future<void> setPreferred(String groupTitle, String? folderUrl) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (folderUrl == null) {
      await prefs.remove('$_kPrefVersionPrefix$groupTitle');
    } else {
      await prefs.setString('$_kPrefVersionPrefix$groupTitle', folderUrl);
    }
    state = {...state, groupTitle: folderUrl};
  }
}

final versionPreferenceProvider =
    NotifierProvider<VersionPreferenceNotifier, Map<String, String?>>(
      VersionPreferenceNotifier.new,
    );

class DubOverrideNotifier extends Notifier<Map<String, bool?>> {
  @override
  Map<String, bool?> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final map = <String, bool?>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_kDubOverridePrefix)) {
        final folderUrl = key.substring(_kDubOverridePrefix.length);
        map[folderUrl] = prefs.getBool(key);
      }
    }
    return map;
  }

  bool? getOverride(String folderUrl) {
    return state[folderUrl];
  }

  Future<void> setOverride(String folderUrl, bool? value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = '$_kDubOverridePrefix$folderUrl';
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setBool(key, value);
    }
    state = {...state, folderUrl: value};
  }

  Future<bool?> toggleOverride(String folderUrl) async {
    final current = state[folderUrl];
    bool? next;
    if (current == null) {
      next = true; // force dub
    } else if (current == true) {
      next = false; // force not dub
    } else {
      next = null; // back to auto
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final key = '$_kDubOverridePrefix$folderUrl';
    if (next == null) {
      await prefs.remove(key);
    } else {
      await prefs.setBool(key, next);
    }
    state = {...state, folderUrl: next};
    return next;
  }
}

final dubOverrideProvider =
    NotifierProvider<DubOverrideNotifier, Map<String, bool?>>(
      DubOverrideNotifier.new,
    );
