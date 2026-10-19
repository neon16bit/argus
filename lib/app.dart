import 'package:argus/features/shell/app_shell.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArgusApp extends ConsumerWidget {
  const ArgusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(appThemeProvider);
    ref.watch(simklSyncServiceProvider);

    return MaterialApp(
      title: 'Argus',
      debugShowCheckedModeBanner: false,
      theme: themeState.theme,
      darkTheme: themeState.darkTheme,
      themeMode: themeState.themeMode,
      home: const AppShell(),
    );
  }
}
