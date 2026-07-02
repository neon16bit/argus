import 'package:argus/app.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final pakageInfo = await PackageInfo.fromPlatform();
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        packageInfoProvider.overrideWithValue(pakageInfo),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: ArgusApp(),
    ),
  );
}
