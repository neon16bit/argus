class CleanResult {
  final String title;
  final int? season;
  final int? episode;
  final String? extension;
  final int? year;

  const CleanResult({
    required this.title,
    this.season,
    this.episode,
    this.extension,
    this.year,
  });

  @override
  String toString() =>
      'CleanResult(title: "$title", S${season ?? "?"}E${episode ?? "?"}, '
      'year: $year, ext: $extension)';
}

// cleans raw filenames from open directory listings into structured data
//
// common patterns:
//  - S01E02, s1e2, 1x02, Season 1 Episode 2
//  - year tags (2023), resolution 720p/1080p/4K
//  - codec tags x264/x265/HEVC/AAC
//  - brackets [SubGroup], underscores, dots -> spaces
class NameCleaner {
  // season/episode patterns, ordered by specificity
  static final _sePatterns = [
    // S01E02, S1E2
    RegExp(r'[Ss](\d{1,2})\s*[Ee](\d{1,3})'),
    // Season 1 Episode 2
    RegExp(r'Season\s*(\d{1,2})\s*Episode\s*(\d{1,3})', caseSensitive: false),
    // 1x02
    RegExp(r'(\d{1,2})[xX](\d{2,3})'),
    // Episode 2, Ep.02, Ep02 (episode only)
    RegExp(r'\b[Ee]p(?:isode)?\.?\s*(\d{1,3})(?!\d)', caseSensitive: false),
    // E02 (episode only)
    RegExp(r'\b[Ee](\d{2,3})(?!\d)'),
  ];

  // Year pattern(2026), [2026], 2026
  static final _yearPattern = RegExp(r'[\(\[]?\b((?:19|20)\d{2})\b[\)\]]?');

  // noise patterns to strip
  static final _noisePatterns = [
    // resolution and quality
    RegExp(
      r'\b(?:(?:480|720|1080|1440|2160)[pi]?|[248]k|\d{3,4}x\d{3,4}|F?HD|UHD|SD)\b',
      caseSensitive: false,
    ),
    // codecs and encoders
    RegExp(r'\b[xXhH]\.?26[45]\b'),
    RegExp(
      r'\b(?:HEVC|AVC|AAC|E?AC3|DTS(?:-HD)?|FLAC|MP3|OPUS)(?:[\.\s\-]*[1-7]\.[01])?\b',
      caseSensitive: false,
    ),
    // source tags
    RegExp(
      r'\b(?:BluRay|BDRip|BRRip|HDRip|WEBRip|WEB-DL|DVDRip|HDTV|PDTV)\b',
      caseSensitive: false,
    ),
    // audio tags
    RegExp(
      r'\b(?:5\.1|7\.1|Atmos|TrueHD|DDP?(?:5\.1|2\.0))\b',
      caseSensitive: false,
    ),
    // hdr, remux,
    RegExp(r'\b(?:HDR10|HDR|SDR|DV|DoVi|Remux)\b', caseSensitive: false),
    // common streaming service tags
    RegExp(
      r'\b(?:NF|AMZN|DSNP|ATVP|HMAX|MAX|PEACOCK|CRAV)\b',
      caseSensitive: false,
    ),
    // brackets content [SubGroup], {info}
    RegExp(r'\[.*?\]'),
    RegExp(r'\{.*?\}'),
    // release group after last dash
    RegExp(r'\s*-\s*\w+$'),
    // common tags
    RegExp(
      r'\b(?:PROPER|REPACK|INTERNAL|EXTENDED|UNRATED|DIRECTORS\.?CUT)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(?:MULTI|DUAL|DUBBED|SUBBED)\b', caseSensitive: false),
    RegExp(r'\b(?:8|10)bit\b', caseSensitive: false),
  ];

  // main cleaning function
  static CleanResult clean(String rawName) {
    // Remove file extension
    String? ext;
    final extMatch = RegExp(r'\.(\w{2,4})$').firstMatch(rawName);
    if (extMatch != null) {
      ext = extMatch.group(1)!.toLowerCase();
      rawName = rawName.substring(0, extMatch.start);
    }

    // extract season and episode before cleaning
    int? season;
    int? episode;
    for (final pattern in _sePatterns) {
      final match = pattern.firstMatch(rawName);
      if (match != null) {
        if (match.groupCount >= 2) {
          season = int.tryParse(match.group(1)!);
          episode = int.tryParse(match.group(2)!);
        } else if (match.groupCount == 1) {
          // episode only pattern
          episode = int.tryParse(match.group(1)!);
        }
        // remove the season/episode tag from the name
        rawName = rawName.replaceFirst(match.group(0)!, ' ');
        break;
      }
    }

    // Extract year
    int? year;
    final yearMatch = _yearPattern.firstMatch(rawName);
    if (yearMatch != null) {
      year = int.tryParse(yearMatch.group(1)!);
      rawName = rawName.replaceFirst(yearMatch.group(0)!, ' ');
    }

    // strip noise
    for (final pattern in _noisePatterns) {
      rawName = rawName.replaceAll(pattern, ' ');
    }

    // replace dots, underscores, brackets with spaces
    rawName = rawName.replaceAll(RegExp(r'[._\[\]\(\)]'), ' ');
    // remove standalone dashes
    rawName = rawName.replaceAll(RegExp(r'\s+-\s+'), ' ');
    // collapse multiple spaces
    rawName = rawName.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    // title case
    final title = _titleCase(rawName);

    return CleanResult(
      title: title,
      season: season,
      episode: episode,
      extension: ext,
      year: year,
    );
  }

  static String _titleCase(String input) {
    if (input.isEmpty) {
      return input;
    }
    if (input.toLowerCase() != input) {
      return input; // if it has uppercase, assume it's already formatted
    }
    return input
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
