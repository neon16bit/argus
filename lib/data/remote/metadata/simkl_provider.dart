import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:argus/core/constants.dart';
import 'package:argus/core/utils/name_cleaner.dart';
import 'metadata_provider.dart';

class SimklProvider extends MetadataProvider {
  static const _clientId = String.fromEnvironment('SIMKL_CLIENT_ID');
  static const _timeout = Duration(seconds: 8);

  final String appName;
  final String appVersion;

  SimklProvider({required this.appName, required this.appVersion}) {
    if (_clientId.isEmpty) {
      debugPrint(
        '[Simkl] WARNING: SIMKL_CLIENT_ID is empty.'
        'Pass --dart-define=SIMKL_CLIENT_ID=your_key',
      );
    } else {
      debugPrint(
        '[Simkl] Initialized with client_id: '
        '${_clientId.substring(0, 8)}...',
      );
    }
  }

  @override
  String get name => 'Simkl';

  Map<String, String> get _headers => {
    'simkl-api-key': _clientId,
    'User-Agent': '$appName/$appVersion',
    'Content-Type': 'application/json',
  };

  // search by title
  @override
  Future<ShowMetadata?> fetchMetadata(String title, {int? year}) async {
    if (_clientId.isEmpty) return null;
    try {
      debugPrint('[Simkl] Searching for: "$title" (year: $year)');
      // try anime first, then TV, then movie
      final animeResult = await _searchByText('anime', title, year: year);
      if (animeResult != null) {
        debugPrint('[Simkl] Found anime match: "${animeResult.title}"');
        if (animeResult.simklId != null) {
          final full = await fetchMetadataById(animeResult.simklId!, 'anime');
          if (full != null) return full;
        }
        return animeResult;
      }

      final tvResult = await _searchByText('tv', title, year: year);
      if (tvResult != null) {
        debugPrint('[Simkl] Found TV match: "${tvResult.title}"');
        if (tvResult.simklId != null) {
          final full = await fetchMetadataById(tvResult.simklId!, 'tv');
          if (full != null) return full;
        }
        return tvResult;
      }

      final movieResult = await _searchByText('movie', title, year: year);
      if (movieResult != null) {
        debugPrint('[Simkl] Found movie match: "${movieResult.title}"');
        if (movieResult.simklId != null) {
          final full = await fetchMetadataById(movieResult.simklId!, 'movie');
          if (full != null) return full;
        }
        return movieResult;
      }
      debugPrint('[Simkl] No results for: "$title"');
      return null;
    } catch (e) {
      debugPrint('[Simkl] Error searching "$title": $e');
      return null;
    }
  }

  Future<ShowMetadata?> _searchByText(
    String type,
    String query, {
    int? year,
  }) async {
    final uri = Uri.parse('$kSimklBaseUrl/search/$type').replace(
      queryParameters: {
        'q': query,
        'extended': 'full',
        'client_id': _clientId,
        'app-name': appName,
        'app-version': appVersion,
      },
    );

    final response = await http.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode != 200) return null;

    final results = jsonDecode(response.body);
    if (results is! List || results.isEmpty) return null;

    // client side year filtering to mitigate false positives
    if (year != null) {
      for (final item in results) {
        if (item is Map<String, dynamic>) {
          final itemYear = item['year'] as int?;
          if (itemYear == year) {
            return _parseResult(item, endpointType: type);
          }
        }
      }
      // if we had a year query but none of the search results matched that year,
      // return null to prevent false positives and let waterfall fallback continue.
      debugPrint(
        '[Simkl] No results matched target year $year for query "$query".',
      );
      return null;
    }

    final first = results[0] as Map<String, dynamic>;
    return _parseResult(first, endpointType: type);
  }

  // fetch full metadata by simkl ID directly
  Future<ShowMetadata?> fetchMetadataById(int simklId, String mediaType) async {
    if (_clientId.isEmpty) return null;
    try {
      final type = mediaType == 'anime'
          ? 'anime'
          : (mediaType == 'movie' ? 'movies' : 'tv');
      final uri = Uri.parse('$kSimklBaseUrl/$type/$simklId').replace(
        queryParameters: {
          'extended': 'full',
          'client_id': _clientId,
          'app-name': appName,
          'app-version': appVersion,
        },
      );

      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final meta = _parseResult(data, endpointType: mediaType);
      return ShowMetadata(
        title: meta.title,
        titleEn: meta.titleEn,
        overview: meta.overview,
        posterUrl: meta.posterUrl,
        posterPath: meta.posterPath,
        backdropUrl: meta.backdropUrl,
        fanartPath: meta.fanartPath,
        rating: meta.rating,
        ratingSimkl: meta.ratingSimkl,
        ratingMal: meta.ratingMal,
        ratingImdb: meta.ratingImdb,
        year: meta.year,
        simklId: simklId,
        mediaType: meta.mediaType,
        slug: (data['ids']?['slug'] ?? data['slug']) as String?,
        imdbId: meta.imdbId,
        tmdbId: meta.tmdbId,
        malId: meta.malId,
        anilistId: meta.anilistId,
        tvdbId: meta.tvdbId,
        anidbId: meta.anidbId,
      );
    } catch (e) {
      debugPrint('[Simkl] Error fetching metadata by ID $simklId: $e');
      return null;
    }
  }

  // global queue lock for filename search
  static Future<dynamic>? _lastFileSearch;

  // search by filename
  Future<SimklFileResult?> fetchMetadataByFilename(
    String filename, {
    int? targetYear,
  }) async {
    if (_clientId.isEmpty) return null;

    // one second delay between filename searches sequentially
    final previous = _lastFileSearch;
    final completer = Completer<void>();
    _lastFileSearch = completer.future;

    if (previous != null) {
      await previous;
      await Future.delayed(const Duration(seconds: 1));
    }

    try {
      return await _fetchMetadataByFilenameInternal(
        filename,
        targetYear: targetYear,
      );
    } finally {
      completer.complete();
    }
  }

  Future<SimklFileResult?> _fetchMetadataByFilenameInternal(
    String filename, {
    int? targetYear,
  }) async {
    try {
      debugPrint('[Simkl] File search: "$filename"');
      final uri = Uri.parse('$kSimklBaseUrl/search/file').replace(
        queryParameters: {
          'client_id': _clientId,
          'app-name': appName,
          'app-version': appVersion,
        },
      );

      final response = await http
          .post(uri, headers: _headers, body: jsonEncode({'file': filename}))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;

      // file search returns
      final type = json['type'] as String?;
      final mediaKey = (type == 'episode') ? 'show' : (type ?? 'show');
      final mediaObject =
          (json[mediaKey] ?? json['show'] ?? json['movie'])
              as Map<String, dynamic>?;
      if (mediaObject == null) return null;

      final ids = mediaObject['ids'] as Map<String, dynamic>? ?? {};
      final title = _unescapeHtml((mediaObject['title'] ?? '') as String) ?? '';

      int? parseIntSafe(dynamic val) {
        if (val == null) return null;
        if (val is int) return val;
        if (val is String) return int.tryParse(val);
        return null;
      }

      // year mismatch checking to mitigate false positives
      final clean = NameCleaner.clean(filename);
      final filterYear = clean.year ?? targetYear;
      final resolvedYear = parseIntSafe(mediaObject['year']);
      if (filterYear != null &&
          resolvedYear != null &&
          resolvedYear != filterYear) {
        debugPrint(
          '[Simkl] Year mismatch for "$filename": '
          'extracted/target $filterYear vs resolved $resolvedYear. Ignoring match.',
        );
        return null;
      }

      int? malId = parseIntSafe(ids['mal']);
      int? anilistId = parseIntSafe(ids['anilist']);
      int? tvdbId = parseIntSafe(ids['tvdb']);
      String? anidbId = ids['anidb']?.toString();

      // determine media type for anime, also extract anime_type
      final isAnime =
          mediaObject['anime_type'] != null ||
          malId != null ||
          anilistId != null ||
          anidbId != null;

      String? resolvedMediaType;
      String? animeType;
      if (isAnime) {
        resolvedMediaType = 'anime';
        animeType = (mediaObject['anime_type'] as String?) ?? 'tv';
      } else if (type == 'movie' || mediaObject['type'] == 'movie') {
        resolvedMediaType = 'movie';
      } else {
        resolvedMediaType = 'tv';
      }

      debugPrint('[Simkl] File match: "$title" ($resolvedMediaType)');

      int? simklId = parseIntSafe(ids['simkl']);
      String? posterPath = mediaObject['poster'] as String?;
      String? fanartPath = mediaObject['fanart'] as String?;
      String? overview = _unescapeHtml(mediaObject['overview'] as String?);
      String? titleEn = _unescapeHtml(
        (mediaObject['en_title'] ?? mediaObject['title_en']) as String?,
      );

      String? imdbId = ids['imdb'] as String?;
      String? tmdbId = (ids['tmdbtv'] ?? ids['tmdb'])?.toString();

      double? ratingSimkl;
      double? ratingMal;
      double? ratingImdb;

      if (simklId != null) {
        final fullMeta = await fetchMetadataById(simklId, resolvedMediaType);
        if (fullMeta != null) {
          posterPath = fullMeta.posterPath ?? posterPath;
          fanartPath = fullMeta.fanartPath ?? fanartPath;
          overview = fullMeta.overview ?? overview;
          titleEn = fullMeta.titleEn ?? titleEn;
          imdbId = fullMeta.imdbId ?? imdbId;
          tmdbId = fullMeta.tmdbId ?? tmdbId;
          malId = fullMeta.malId ?? malId;
          anilistId = fullMeta.anilistId ?? anilistId;
          tvdbId = fullMeta.tvdbId ?? tvdbId;
          anidbId = fullMeta.anidbId ?? anidbId;
          ratingSimkl = fullMeta.ratingSimkl;
          ratingMal = fullMeta.ratingMal;
          ratingImdb = fullMeta.ratingImdb;
        }
      } else {
        final fullMeta = await fetchMetadata(title, year: resolvedYear);
        if (fullMeta != null) {
          posterPath = fullMeta.posterPath ?? posterPath;
          fanartPath = fullMeta.fanartPath ?? fanartPath;
          overview = fullMeta.overview ?? overview;
          titleEn = fullMeta.titleEn ?? titleEn;
          imdbId = fullMeta.imdbId ?? imdbId;
          tmdbId = fullMeta.tmdbId ?? tmdbId;
          malId = fullMeta.malId ?? malId;
          anilistId = fullMeta.anilistId ?? anilistId;
          tvdbId = fullMeta.tvdbId ?? tvdbId;
          anidbId = fullMeta.anidbId ?? anidbId;
          ratingSimkl = fullMeta.ratingSimkl;
          ratingMal = fullMeta.ratingMal;
          ratingImdb = fullMeta.ratingImdb;
        }
      }

      return SimklFileResult(
        title: title,
        titleEn: titleEn,
        mediaType: resolvedMediaType,
        animeType: animeType,
        year: resolvedYear,
        totalEpisodes: parseIntSafe(mediaObject['total_episodes']),
        posterPath: posterPath,
        fanartPath: fanartPath,
        overview: overview,
        ratingSimkl: ratingSimkl,
        ratingMal: ratingMal,
        ratingImdb: ratingImdb,
        simklId: simklId,
        slug: ids['slug'] as String?,
        imdbId: imdbId,
        tmdbId: tmdbId,
        malId: malId,
        anilistId: anilistId,
        tvdbId: tvdbId,
        anidbId: anidbId,
      );
    } catch (e) {
      debugPrint('[Simkl] File search error: $e');
      return null;
    }
  }

  @override
  Future<String?> fetchPosterUrl(String title, {int? year}) async {
    final metadata = await fetchMetadata(title, year: year);
    return metadata?.posterUrl;
  }

  // build a poster url from simkl poster path
  //
  // size suffixes: _w (large), _m (medium), _ca (card)
  // _c (compact), _cm (compact medium), _s (small/40px).
  static String? posterUrl(
    String? posterPath, {
    String size = '_m',
    String ext = '.jpg',
  }) {
    if (posterPath == null || posterPath.isEmpty) return null;
    return '$kSimklImageBase/posters/$posterPath$size$ext&q=90';
  }

  // build a fanart URL from a Simkl fanart path.
  //
  // size suffixes: _medium, _mobile, _w, _s48
  static String? fanartUrl(
    String? fanartPath, {
    String size = '_mobile',
    String ext = '.jpg',
  }) {
    if (fanartPath == null || fanartPath.isEmpty) return null;
    return '$kSimklImageBase/fanart/$fanartPath$size$ext&q=90';
  }

  ShowMetadata _parseResult(Map<String, dynamic> data, {String? endpointType}) {
    final title = _unescapeHtml((data['title'] ?? '') as String) ?? '';
    final titleEn = _unescapeHtml(
      (data['en_title'] ?? data['title_en']) as String?,
    );
    final year = data['year'] as int?;
    final poster = data['poster'] as String?;
    final fanart = data['fanart'] as String?;

    final ids = data['ids'] as Map<String, dynamic>? ?? {};

    int? parseIntSafe(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) return int.tryParse(val);
      return null;
    }

    String? parseStringSafe(dynamic val) {
      if (val == null) return null;
      return val.toString();
    }

    final simklId = parseIntSafe(ids['simkl'] ?? ids['simkl_id']);
    final slug = ids['slug'] as String?;
    final imdbId = parseStringSafe(ids['imdb']);
    final tmdbId = parseStringSafe(ids['tmdb']);
    final malId = parseIntSafe(ids['mal']);
    final anilistId = parseIntSafe(ids['anilist']);
    final tvdbId = parseIntSafe(ids['tvdb']);
    final anidbId = parseStringSafe(ids['anidb']);

    // ratings
    double? ratingSimkl;
    double? ratingMal;
    double? ratingImdb;
    final ratings = data['ratings'];
    if (ratings is Map<String, dynamic>) {
      final simklRating = ratings['simkl'];
      if (simklRating is Map<String, dynamic>) {
        ratingSimkl = (simklRating['rating'] as num?)?.toDouble();
      }
      final malRating = ratings['mal'];
      if (malRating is Map<String, dynamic>) {
        ratingMal = (malRating['rating'] as num?)?.toDouble();
      }
      final imdbRating = ratings['imdb'];
      if (imdbRating is Map<String, dynamic>) {
        ratingImdb = (imdbRating['rating'] as num?)?.toDouble();
      }
    }
    final rating = ratingImdb ?? ratingMal ?? ratingSimkl;

    final isAnime =
        endpointType == 'anime' ||
        data['endpoint_type'] == 'anime' ||
        data['anime_type'] != null ||
        malId != null ||
        anilistId != null ||
        anidbId != null;

    final mediaType = isAnime
        ? 'anime'
        : (endpointType == 'movies' ||
                  endpointType == 'movie' ||
                  data['endpoint_type'] == 'movies' ||
                  data['endpoint_type'] == 'movie' ||
                  data['type'] == 'movie'
              ? 'movie'
              : 'tv');

    return ShowMetadata(
      title: title,
      titleEn: titleEn,
      overview: _unescapeHtml(data['overview'] as String?),
      posterUrl: posterUrl(poster),
      posterPath: poster,
      backdropUrl: fanartUrl(fanart),
      fanartPath: fanart,
      rating: rating,
      ratingSimkl: ratingSimkl,
      ratingMal: ratingMal,
      ratingImdb: ratingImdb,
      year: year,
      simklId: simklId,
      mediaType: mediaType,
      slug: slug,
      imdbId: imdbId,
      tmdbId: tmdbId,
      malId: malId,
      anilistId: anilistId,
      tvdbId: tvdbId,
      anidbId: anidbId,
      genres: const [],
      cast: const [],
    );
  }
}

String? _unescapeHtml(String? input) {
  if (input == null) return null;
  return html_parser.parseFragment(input).text;
}
