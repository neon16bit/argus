import 'package:argus/data/database/app_database.dart';

class ShowViewModel {
  final List<dynamic> filteredItems;
  final List<Source> contributingSources;
  final Map<int?, List<List<dynamic>>> seasonMap;
  final List<int?> sortedSeasons;

  ShowViewModel({
    required this.filteredItems,
    required this.contributingSources,
    required this.seasonMap,
    required this.sortedSeasons,
  });

  factory ShowViewModel.compute({
    required List<dynamic> items,
    required List<Source> allSources,
    required int? selectedSourceId,
    String? preferredFolderUrl,
  }) {
    // determine which sources are contributing to this shows items
    final showSourceIds = items.map((i) => i.sourceId).toSet();
    final contributingSources = allSources
        .where((s) => showSourceIds.contains(s.id))
        .toList();

    bool matchesPreferred(dynamic item) {
      if (preferredFolderUrl == null || preferredFolderUrl.isEmpty) return false;
      final itemUrl = item.directUrl.toLowerCase();
      final prefUrl = preferredFolderUrl.toLowerCase();
      final prefDecoded = Uri.decodeFull(preferredFolderUrl).toLowerCase();
      final itemDecoded = Uri.decodeFull(item.directUrl).toLowerCase();
      return itemUrl.startsWith(prefUrl) ||
          itemDecoded.startsWith(prefDecoded) ||
          itemUrl.contains(prefUrl) ||
          itemDecoded.contains(prefDecoded);
    }

    // group items by season
    final tempSeasonMap = <int?, List<dynamic>>{};
    for (final item in items) {
      tempSeasonMap.putIfAbsent(item.season, () => []).add(item);
    }

    final filteredItems = <dynamic>[];
    final seasonMap = <int?, List<List<dynamic>>>{};

    for (final entry in tempSeasonMap.entries) {
      final season = entry.key;
      final episodes = entry.value;

      // filter episodes by selected source
      final filteredEpisodesForSeason = selectedSourceId == null
          ? episodes
          : episodes.where((i) => i.sourceId == selectedSourceId).toList();

      // if the selected source doesnt have this season, fall back to all sources
      final finalEpisodesForSeason = filteredEpisodesForSeason.isNotEmpty
          ? filteredEpisodesForSeason
          : episodes;

      filteredItems.addAll(finalEpisodesForSeason);

      final groupedEpisodes = <int?, List<dynamic>>{};
      final nullEpisodes = <dynamic>[];

      for (final item in finalEpisodesForSeason) {
        if (item.episode == null) {
          nullEpisodes.add(item);
        } else {
          groupedEpisodes.putIfAbsent(item.episode, () => []).add(item);
        }
      }

      for (final epList in groupedEpisodes.values) {
        if (preferredFolderUrl != null && epList.length > 1) {
          epList.sort((a, b) {
            final aMatch = matchesPreferred(a);
            final bMatch = matchesPreferred(b);
            if (aMatch && !bMatch) return -1;
            if (!aMatch && bMatch) return 1;
            return 0;
          });
        }
      }

      final sortedGrouped = groupedEpisodes.values.toList()
        ..sort(
          (a, b) => (a.first.episode ?? 0).compareTo(b.first.episode ?? 0),
        );

      seasonMap[season] = [
        ...sortedGrouped,
        ...nullEpisodes.map((e) => [e]),
      ];
    }

    final sortedSeasons = seasonMap.keys.toList()
      ..sort((a, b) {
        final aVal = a ?? 0;
        final bVal = b ?? 0;
        if (aVal == 0 && bVal != 0) return 1;
        if (bVal == 0 && aVal != 0) return -1;
        return aVal.compareTo(bVal);
      });

    return ShowViewModel(
      filteredItems: filteredItems,
      contributingSources: contributingSources,
      seasonMap: seasonMap,
      sortedSeasons: sortedSeasons,
    );
  }
}
