import 'package:argus/data/database/app_database.dart';

class EpisodeFixResult {
  final Map<int, int> updates;
  final Map<int?, int> seasonItemCounts;

  const EpisodeFixResult({
    required this.updates,
    required this.seasonItemCounts,
  });

  int get totalFixed => updates.length;
  bool get isEmpty => updates.isEmpty;
}

class EpisodeFixer {
  static final _digitPattern = RegExp(r'\d+');

  static EpisodeFixResult detect(List<MediaItem> items) {
    final allUpdates = <int, int>{};
    final seasonCounts = <int?, int>{};

    // group items by season
    final bySeason = <int?, List<MediaItem>>{};
    for (final item in items) {
      bySeason.putIfAbsent(item.season, () => []).add(item);
    }

    for (final entry in bySeason.entries) {
      final seasonItems = entry.value;
      if (seasonItems.length < 2) continue;

      final result = _detectForGroup(seasonItems);
      if (result.isNotEmpty) {
        allUpdates.addAll(result);
        seasonCounts[entry.key] = result.length;
      }
    }

    return EpisodeFixResult(
      updates: allUpdates,
      seasonItemCounts: seasonCounts,
    );
  }

  static Map<int, int> _detectForGroup(List<MediaItem> items) {
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

    // build column values and filter out constant columns
    final variableColumns = <int>[];
    for (int col = 0; col < maxCols; col++) {
      final values = <int>{};
      int count = 0;
      for (final nums in itemNumbers.values) {
        if (col < nums.length) {
          values.add(nums[col]);
          count++;
        }
      }
      // skip columns where all values are the same
      // skip columns that dont have values for most items
      if (values.length > 1 && count >= itemNumbers.length * 0.5) {
        variableColumns.add(col);
      }
    }

    if (variableColumns.isEmpty) return {};

    // from the variable columns find the one with the best sequential score
    int bestCol = -1;
    int bestScore = 0;

    for (final col in variableColumns) {
      final colValues = <int>[];
      for (final nums in itemNumbers.values) {
        if (col < nums.length) {
          colValues.add(nums[col]);
        }
      }

      final score = _sequentialScore(colValues);
      if (score > bestScore) {
        bestScore = score;
        bestCol = col;
      }
    }

    // require at least 50% of items to form a sequential run
    if (bestCol < 0 || bestScore < (itemNumbers.length * 0.5)) return {};

    // build the update map from the winning column
    final updates = <int, int>{};
    for (final entry in itemNumbers.entries) {
      if (bestCol < entry.value.length) {
        updates[entry.key] = entry.value[bestCol];
      }
    }

    return updates;
  }

  // returns the length of the longest run where consecutive sorted values differ by at most maxGap
  static int _sequentialScore(List<int> values, {int maxGap = 3}) {
    if (values.length < 2) return 0;

    final sorted = [...values]..sort();
    // deduplicate
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
