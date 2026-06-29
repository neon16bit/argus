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
    // format: title roman_numeral episode (e.g. Index II 01, Overlord III 05)
    // the number should not be followed by resolution/codec letters like 'p', 'k', or 'bit'
    // TODO: could be prone to false positives need to do more checks
    RegExp(
      r'(?<![a-zA-Z])(II|III|IV|V|VI|VII|VIII|IX|X)[\s_.-]+(\d{2,3})(?!\d|[pk]\b|bit\b)',
    ),
  ];

  // Year pattern(2026), [2026], 2026
  static final _yearPattern = RegExp(r'[\(\[]?\b((?:19|20)\d{2})\b[\)\]]?');

  // noise patterns to strip
  static final _noisePatterns = [
    // resolution and quality
    RegExp(
      r'\b(?:BD|HD|WEB)?(?:(?:480|720|1080|1440|2160)[pi]?|[248]k|\d{3,4}x\d{3,4}|F?HD|UHD|SD)\b',
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
      r'\b(?:NF|AMZN|DSNP|ATVP|HMAX|PEACOCK|CRAV)\b',
      caseSensitive: false,
    ),
    RegExp(r'\bMAX\b'),
    // release group after last dash (must have space before dash so hyphenated words arent stripped)
    RegExp(r'\s+-\s*[\w\.]+$'),
    // common tags
    RegExp(
      r'\b(?:PROPER|REPACK|INTERNAL|EXTENDED|UNRATED|DIRECTORS\.?CUT)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(?:MULTI|DUAL|DUBBED|SUBBED)\b', caseSensitive: false),
    RegExp(r'\b(?:8|10)bit\b', caseSensitive: false),
  ];

  // Cleans a folder name into a show title + year.
  static CleanResult cleanFolderName(String folderName) {
    var name = folderName;
    // extract year before stripping brackets
    int? year;
    final yearMatch = _yearPattern.firstMatch(name);
    if (yearMatch != null) {
      year = int.tryParse(yearMatch.group(1)!);
      name = name.replaceFirst(yearMatch.group(0)!, ' ');
    }

    // strip bracket content
    name = name.replaceAll(RegExp(r'\(.*?\)'), ' ');
    name = name.replaceAll(RegExp(r'\[.*?\]'), ' ');
    name = name.replaceAll(RegExp(r'\{.*?\}'), ' ');

    name = name.replaceAll(
      RegExp(
        r'\b(?:anime|tv\s+series|tv\s+show|series|show|movies|cartoons)\b',
        caseSensitive: false,
      ),
      ' ',
    );

    // strip noise patterns
    for (final pattern in _noisePatterns) {
      name = name.replaceAll(pattern, ' ');
    }

    // replace separators, collapse whitespace
    name = name.replaceAll(RegExp(r'[._]'), ' ');
    name = name.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return CleanResult(title: _titleCase(name), year: year);
  }

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
          final sGroup = match.group(1)!;
          season = int.tryParse(sGroup) ?? _parseRoman(sGroup);
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

    // strip entire brackets content [SubGroup], {info}
    rawName = rawName.replaceAll(RegExp(r'\[.*?\]'), ' ');
    rawName = rawName.replaceAll(RegExp(r'\{.*?\}'), ' ');

    // replace underscores and remaining brackets/parentheses with spaces
    rawName = rawName.replaceAll(RegExp(r'[_\[\]\(\)]'), ' ');

    // strip noise
    for (final pattern in _noisePatterns) {
      rawName = rawName.replaceAll(pattern, ' ');
    }

    // replace dots with spaces
    rawName = rawName.replaceAll('.', ' ');

    // remove standalone dashes and dash+word tags
    rawName = rawName.replaceAll(RegExp(r'\s+-(?:\s+|\w+)'), ' ');
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

  static int? _parseRoman(String roman) {
    const map = {
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
      'VIII': 8,
      'IX': 9,
      'X': 10,
    };
    return map[roman.toUpperCase()];
  }
}
