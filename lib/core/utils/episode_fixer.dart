import 'package:argus/data/database/app_database.dart';

class SeasonFixInfo {
  final int? season;
  final int episodeCount; // unique episodes detected
  final int itemCount; // total files to update
  final Map<int, int> updates; // itemId -> detected episode

  const SeasonFixInfo({
    required this.season,
    required this.episodeCount,
    required this.itemCount,
    required this.updates,
  });
}

class EpisodeFixResult {
  final Map<int?, SeasonFixInfo> seasons;

  const EpisodeFixResult({required this.seasons});

  int get totalFixed => seasons.values.fold(0, (sum, s) => sum + s.itemCount);
  bool get isEmpty => seasons.isEmpty;
}

class EpisodeFixer {
  static final _digitPattern = RegExp(r'\d+');

  static EpisodeFixResult detect(List<MediaItem> items) {
    final seasonMap = <int?, SeasonFixInfo>{};

    // group items by season
    final bySeason = <int?, List<MediaItem>>{};
    for (final item in items) {
      bySeason.putIfAbsent(item.season, () => []).add(item);
    }

    for (final seasonEntry in bySeason.entries) {
      final seasonItems = seasonEntry.value;
      if (seasonItems.length < 2) continue;

      // group items by dir url to isolate
      final byFolder = <String, List<MediaItem>>{};
      for (final item in seasonItems) {
        final url = item.directUrl;
        final slashIdx = url.lastIndexOf('/');
        final folderKey = slashIdx > 0
            ? '${item.sourceId}_${url.substring(0, slashIdx)}'
            : '${item.sourceId}';
        byFolder.putIfAbsent(folderKey, () => []).add(item);
      }

      final seasonUpdates = <int, int>{};
      for (final folderItems in byFolder.values) {
        if (folderItems.length < 2) continue;
        final updates = _detectForItems(folderItems);
        seasonUpdates.addAll(updates);
      }

      if (seasonUpdates.isNotEmpty) {
        final uniqueEpisodes = seasonUpdates.values.toSet().length;
        seasonMap[seasonEntry.key] = SeasonFixInfo(
          season: seasonEntry.key,
          episodeCount: uniqueEpisodes,
          itemCount: seasonUpdates.length,
          updates: seasonUpdates,
        );
      }
    }

    return EpisodeFixResult(seasons: seasonMap);
  }

  static Map<int, int> _detectForItems(List<MediaItem> items) {
    // extract all numbers from each raw filename
    final itemNumbers = <int, List<int>>{};

    for (final item in items) {
      var name = item.rawName;
      final extIdx = name.lastIndexOf('.');
      if (extIdx > 0) name = name.substring(0, extIdx);

      final numbers = _digitPattern
          .allMatches(name)
          .map((m) => int.tryParse(m.group(0)!))
          .whereType<int>()
          .toList();

      if (numbers.isNotEmpty) {
        itemNumbers[item.id] = numbers;
      }
    }

    if (itemNumbers.length < 2) return {};

    // find the max number of columns
    final maxCols = itemNumbers.values
        .map((nums) => nums.length)
        .reduce((a, b) => a > b ? a : b);

    // find candidate columns from the left
    int bestCol = -1;
    bool bestIsFromEnd = false;
    int bestScore = 0;

    // test forward columns
    for (int col = 0; col < maxCols; col++) {
      final valuesAtCol = <int>{};
      final seqValues = <int>[];
      int presentCount = 0;

      for (final nums in itemNumbers.values) {
        if (col < nums.length) {
          valuesAtCol.add(nums[col]);
          seqValues.add(nums[col]);
          presentCount++;
        }
      }

      // skip columns where all values are the same
      if (valuesAtCol.length <= 1 || presentCount < itemNumbers.length * 0.6) {
        continue;
      }

      final score = _sequentialScore(seqValues);
      if (score > bestScore) {
        bestScore = score;
        bestCol = col;
        bestIsFromEnd = false;
      }
    }

    // test reverse columns
    for (int revCol = 1; revCol <= maxCols; revCol++) {
      final valuesAtCol = <int>{};
      final seqValues = <int>[];
      int presentCount = 0;

      for (final nums in itemNumbers.values) {
        if (nums.length >= revCol) {
          final val = nums[nums.length - revCol];
          valuesAtCol.add(val);
          seqValues.add(val);
          presentCount++;
        }
      }

      if (valuesAtCol.length <= 1 || presentCount < itemNumbers.length * 0.6) {
        continue;
      }

      final score = _sequentialScore(seqValues);
      if (score > bestScore) {
        bestScore = score;
        bestCol = revCol;
        bestIsFromEnd = true;
      }
    }

    // require at least 50% of items to form a sequential run
    if (bestScore < (itemNumbers.length * 0.5)) return {};

    // build the update map from the winning column
    final updates = <int, int>{};
    for (final entry in itemNumbers.entries) {
      final nums = entry.value;
      if (!bestIsFromEnd) {
        if (bestCol < nums.length) {
          updates[entry.key] = nums[bestCol];
        }
      } else {
        if (nums.length >= bestCol) {
          updates[entry.key] = nums[nums.length - bestCol];
        }
      }
    }

    return updates;
  }

  // returns the length of the longest run where consecutive sorted values differ by at most maxGap
  static int _sequentialScore(List<int> values, {int maxGap = 3}) {
    if (values.length < 2) return 0;

    final sorted = [...values]..sort();
    final unique = <int>[sorted.first];
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] != sorted[i - 1]) unique.add(sorted[i]);
    }

    if (unique.length < 2) return 0;

    int longest = 1;
    int current = 1;
    for (int i = 1; i < unique.length; i++) {
      final gap = unique[i] - unique[i - 1];
      if (gap >= 1 && gap <= maxGap) {
        current++;
      } else {
        current = 1;
      }
      if (current > longest) longest = current;
    }

    return longest;
  }
}
