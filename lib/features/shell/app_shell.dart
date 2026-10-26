import 'package:argus/core/constants.dart';
import 'package:argus/core/providers/providers.dart';
import 'package:argus/features/home/home_screen.dart';
import 'package:argus/features/library/library_screen.dart';
import 'package:argus/features/search/search_screen.dart';
import 'package:argus/features/settings/settings_screen.dart';
import 'package:argus/features/sources/sources_screen.dart';
import 'package:argus/features/shell/widgets/metadata_notice_dialog.dart';
import 'package:argus/core/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

class _SidebarDestinationData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _SidebarDestinationData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

const List<_SidebarDestinationData> _mainDestinations = [
  _SidebarDestinationData(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _SidebarDestinationData(
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library_rounded,
    label: 'Library',
  ),
  _SidebarDestinationData(
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
    label: 'Sources',
  ),
];

const _SidebarDestinationData _settingsDestination = _SidebarDestinationData(
  icon: Icons.settings_outlined,
  selectedIcon: Icons.settings_rounded,
  label: 'Settings',
);

class _SidebarHeaderLogoToggle extends StatefulWidget {
  final bool isExtended;
  final VoidCallback onToggle;

  const _SidebarHeaderLogoToggle({
    required this.isExtended,
    required this.onToggle,
  });

  @override
  State<_SidebarHeaderLogoToggle> createState() =>
      _SidebarHeaderLogoToggleState();
}

class _SidebarHeaderLogoToggleState extends State<_SidebarHeaderLogoToggle> {
  bool _isHovered = false;

  @override
  void didUpdateWidget(covariant _SidebarHeaderLogoToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExtended != widget.isExtended) {
      _isHovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isExtended) {
      return Row(
        children: [
          SvgPicture.asset(
            'assets/icons/argus_icon.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.primary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Argus',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.view_sidebar_outlined, size: 20),
            tooltip: 'Collapse sidebar',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onToggle,
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'Expand sidebar',
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isHovered
                  ? theme.colorScheme.surfaceContainerHighest.withAlpha(150)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.85,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isHovered
                    ? Icon(
                        Icons.view_sidebar_rounded,
                        key: const ValueKey('sidebar_icon'),
                        size: 22,
                        color: theme.colorScheme.primary,
                      )
                    : SvgPicture.asset(
                        'assets/icons/argus_icon.svg',
                        key: const ValueKey('logo_svg'),
                        width: 26,
                        height: 26,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _SidebarDestinationData data;
  final bool isSelected;
  final bool isExtended;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.data,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = isSelected ? data.selectedIcon : data.icon;
    final fgColor = isSelected
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final bgColor = isSelected
        ? theme.colorScheme.secondaryContainer
        : Colors.transparent;

    if (!isExtended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Tooltip(
          message: data.label,
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 300),
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              hoverColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
                100,
              ),
              child: SizedBox(
                width: 48,
                height: 44,
                child: Center(child: Icon(icon, size: 22, color: fgColor)),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fgColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellContentStack extends ConsumerWidget {
  const _ShellContentStack();

  static const List<Widget> _desktopScreens = [
    HomeScreen(),
    LibraryScreen(),
    SourcesScreen(),
    SettingsScreen(),
    SearchScreen(),
  ];

  static const List<Widget> _mobileScreens = [
    HomeScreen(),
    LibraryScreen(),
    SourcesScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isDesktop = context.isDesktop;
    final screens = isDesktop ? _desktopScreens : _mobileScreens;
    final safeIndex = currentIndex.clamp(0, screens.length - 1);
    return IndexedStack(index: safeIndex, children: screens);
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool? _manualExtended;

  late final GlobalKey<NavigatorState> _desktopNavKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showMetadataNoticeDialogIfNeeded(context, ref);
        checkAppUpdateOnLaunchIfNeeded(context, ref);
      }
    });
  }

  void _onDestinationTapped(int index) {
    if (_desktopNavKey.currentState?.canPop() ?? false) {
      _desktopNavKey.currentState?.popUntil((r) => r.isFirst);
    }
    ref.read(navigationIndexProvider.notifier).setIndex(index);
  }

  void _onSearchTapped() {
    if (_desktopNavKey.currentState?.canPop() ?? false) {
      _desktopNavKey.currentState?.popUntil((r) => r.isFirst);
    }
    ref.read(navigationIndexProvider.notifier).setIndex(4);
    ref.read(searchFocusTriggerProvider.notifier).trigger();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final width = context.screenWidth;
    final isDesktop = context.isDesktop;
    final isExtended = _manualExtended ?? (width >= kSidebarExpandBreakpoint);
    final isSearchSelected = currentIndex == 4;
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) ...[
            SizedBox(
              width: isExtended ? 210 : 72,
              child: Material(
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    if (isExtended)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SidebarHeaderLogoToggle(
                              isExtended: true,
                              onToggle: () {
                                setState(() => _manualExtended = false);
                              },
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _onSearchTapped,
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSearchSelected
                                      ? theme.colorScheme.secondaryContainer
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSearchSelected
                                      ? Border.all(
                                          color: theme.colorScheme.primary
                                              .withAlpha(150),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                      color: isSearchSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSearchSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSearchSelected
                                            ? theme
                                                  .colorScheme
                                                  .onSecondaryContainer
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 8),
                        child: Column(
                          children: [
                            _SidebarHeaderLogoToggle(
                              isExtended: false,
                              onToggle: () {
                                setState(() => _manualExtended = true);
                              },
                            ),
                            const SizedBox(height: 4),
                            Tooltip(
                              message: 'Search',
                              preferBelow: false,
                              waitDuration: const Duration(milliseconds: 300),
                              child: Material(
                                color: isSearchSelected
                                    ? theme.colorScheme.secondaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: _onSearchTapped,
                                  borderRadius: BorderRadius.circular(10),
                                  hoverColor: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withAlpha(100),
                                  child: SizedBox(
                                    width: 44,
                                    height: 40,
                                    child: Center(
                                      child: Icon(
                                        Icons.search_rounded,
                                        size: 20,
                                        color: isSearchSelected
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                    // nav bar  items
                    for (int i = 0; i < _mainDestinations.length; i++)
                      _SidebarItem(
                        data: _mainDestinations[i],
                        isSelected: currentIndex == i,
                        isExtended: isExtended,
                        onTap: () => _onDestinationTapped(i),
                      ),

                    const Spacer(),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isExtended ? 16 : 12,
                        vertical: 4,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: theme.colorScheme.outlineVariant.withAlpha(50),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // settings
                    _SidebarItem(
                      data: _settingsDestination,
                      isSelected: currentIndex == 3,
                      isExtended: isExtended,
                      onTap: () => _onDestinationTapped(3),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: isDesktop
                ? Navigator(
                    key: _desktopNavKey,
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      settings: settings,
                      builder: (_) => const _ShellContentStack(),
                    ),
                  )
                : const _ShellContentStack(),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: currentIndex > 2 ? 0 : currentIndex,
              onDestinationSelected: (index) {
                ref.read(navigationIndexProvider.notifier).setIndex(index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: 'Sources',
                ),
              ],
            ),
    );
  }
}
