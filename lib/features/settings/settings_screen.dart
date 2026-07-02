import 'package:argus/theme/app_theme.dart';
import 'package:argus/theme/catppuccin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:argus/core/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _getFlavorDisplayName(String flavor) {
    switch (flavor) {
      case 'system':
        return 'System default';
      case 'latte':
        return 'Latte (Light)';
      case 'frappe':
        return 'Frappe (Medium)';
      case 'macchiato':
        return 'Macchiato (Dark)';
      case 'mocha':
        return 'Mocha (Darkest)';
      default:
        return flavor;
    }
  }

  Widget _accentDot(
    BuildContext context,
    WidgetRef ref,
    String label,
    Color color,
    String name,
    String currentAccent,
  ) {
    final isSelected = currentAccent.toLowerCase() == name.toLowerCase();
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setAccentColor(name),
      child: Tooltip(
        message: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final dynamicColors = ref.watch(dynamicColorSchemeProvider);

    // resolve current active palette to display the correct color tones for the accent selector dots
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPaletteName = settings.themeFlavor == 'system'
        ? (isDark ? 'mocha' : 'latte')
        : settings.themeFlavor;
    final palette = AppTheme.getPalette(currentPaletteName);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Theme Flavor'),
            subtitle: Text(_getFlavorDisplayName(settings.themeFlavor)),
            trailing: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color:
                      Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              child: PopupMenuButton<String>(
                onSelected: (String value) {
                  ref.read(settingsProvider.notifier).setThemeFlavor(value);
                },
                offset: const Offset(0, 40),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getFlavorDisplayName(settings.themeFlavor),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                itemBuilder: (context) {
                  final accentColor = Theme.of(context).colorScheme.primary;
                  final current = settings.themeFlavor;

                  PopupMenuItem<String> buildItem(
                    String value,
                    String label,
                    Color? baseColor,
                  ) {
                    final isSelected = value == current;
                    return PopupMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: baseColor,
                              border: Border.all(
                                color: isSelected
                                    ? accentColor
                                    : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white24
                                          : Colors.black26),
                                width: isSelected ? 2 : 1,
                              ),
                              gradient: baseColor == null
                                  ? const LinearGradient(
                                      colors: [Colors.white, Colors.black],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected ? accentColor : null,
                                  ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              color: accentColor,
                              size: 18,
                            ),
                        ],
                      ),
                    );
                  }

                  return [
                    buildItem('system', 'System default', null),
                    buildItem('latte', 'Latte', const Color(0xFFeff1f5)),
                    buildItem('frappe', 'Frappe', const Color(0xFF303446)),
                    buildItem(
                      'macchiato',
                      'Macchiato',
                      const Color(0xFF24273a),
                    ),
                    buildItem('mocha', 'Mocha', const Color(0xFF1e1e2e)),
                  ];
                },
              ),
            ),
          ),
          if (isDark)
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_rounded),
              title: const Text('Pure black'),
              subtitle: const Text('Use pitch black backgrounds in dark mode'),
              value: settings.pureBlack,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setPureBlack(v),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Accent Color',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Material You Dynamic Accent Option
                (() {
                  final isSelected = settings.accentColor == 'material_you';
                  final Color materialYouColor = dynamicColors != null
                      ? (isDark
                            ? dynamicColors.dark.primary
                            : dynamicColors.light.primary)
                      : Colors.grey;

                  return GestureDetector(
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .setAccentColor('material_you'),
                    child: Tooltip(
                      message: 'Material You (System)',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dynamicColors != null
                                  ? materialYouColor
                                  : null,
                              gradient: dynamicColors == null
                                  ? SweepGradient(
                                      colors: [
                                        palette.red,
                                        palette.peach,
                                        palette.yellow,
                                        palette.green,
                                        palette.blue,
                                        palette.mauve,
                                        palette.red,
                                      ],
                                    )
                                  : null,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: materialYouColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dynamic',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? materialYouColor : null,
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })(),
                ...CatppuccinPalette.accentNames.map((name) {
                  final color = palette.getColorByName(name);
                  return _accentDot(
                    context,
                    ref,
                    name,
                    color,
                    name,
                    settings.accentColor,
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Scraping Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Full scrape mode'),
            subtitle: const Text(
              'Recursively scrape all files on source index. '
              'Slower but indexes everything upfront.',
            ),
            value: settings.fullScrapeMode,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setFullScrapeMode(v),
          ),
          const Divider(),
          ListTile(
            title: const Text('Request delay'),
            subtitle: Text(
              '${settings.scrapeDelay.inMilliseconds}ms between requests '
              '(reduces rate-limiting risk)',
            ),
          ),
          Slider(
            value: settings.scrapeDelay.inMilliseconds.toDouble(),
            min: 0,
            max: 1000,
            divisions: 10,
            label: '${settings.scrapeDelay.inMilliseconds}ms',
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .setScrapeDelay(Duration(milliseconds: v.toInt())),
          ),
        ],
      ),
    );
  }
}
