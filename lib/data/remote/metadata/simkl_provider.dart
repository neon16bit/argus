import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:argus/core/constants.dart';
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

  // TODO: wip simkl search, episode names

  // search by title
  @override
  Future<ShowMetadata?> fetchMetadata(String title, {int? year}) async {
    if (_clientId.isEmpty) return null;
    try {
      debugPrint('[Simkl] Searching for: "$title"');
      // try TV first, then anime then movie
      final tvResult = await _searchByText('tv', title);
      if (tvResult != null) {
        debugPrint('[Simkl] Found TV match: "${tvResult.title}"');
        return tvResult;
      }

      final animeResult = await _searchByText('anime', title);
      if (animeResult != null) {
        debugPrint('[Simkl] Found anime match: "${animeResult.title}"');
        return animeResult;
      }

      final movieResult = await _searchByText('movie', title);
      if (movieResult != null) {
        debugPrint('[Simkl] Found movie match: "${movieResult.title}"');
      } else {
        debugPrint('[Simkl] No results for: "$title"');
      }
      return movieResult;
    } catch (e) {
      debugPrint('[Simkl] Error searching "$title": $e');
      return null;
    }
  }

  Future<ShowMetadata?> _searchByText(String type, String query) async {
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

    final first = results[0] as Map<String, dynamic>;
    return _parseResult(first);
  }

  // search by filename
  Future<ShowMetadata?> fetchMetadataByFilename(String filename) async {
    try {
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
      if (json is! List || json.isEmpty) return null;

      final first = json[0] as Map<String, dynamic>;

      // search file returns type, movie/show/anime
      final type = first['type'] as String?;
      final mediaObject =
          (first[type] ?? first['show'] ?? first['movie'])
              as Map<String, dynamic>?;
      if (mediaObject == null) return null;

      return _parseResult(mediaObject);
    } catch (_) {
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
  static String? posterUrl(String? posterPath, {String size = '_m'}) {
    if (posterPath == null) return null;
    return '$kSimklImageBase/posters/$posterPath$size.webp&q=90';
  }

  // build a fanart URL from a Simkl fanart path.
  //
  // size suffixes: _medium, _mobile, _w, _s48
  static String? fanartUrl(String? fanartPath, {String size = '_mobile'}) {
    if (fanartPath == null) return null;
    return '$kSimklImageBase/fanart/$fanartPath$size.webp&q=90';
  }

  ShowMetadata _parseResult(Map<String, dynamic> data) {
    final title = (data['title'] ?? data['title_en'] ?? '') as String;
    final year = data['year'] as int?;
    final poster = data['poster'] as String?;
    final fanart = data['fanart'] as String?;

    // ratings TODO: mal for anime, imdb for movie/show maybe multiple ratings
    double? rating;
    final ratings = data['ratings'];
    if (ratings is Map<String, dynamic>) {
      final simklRating = ratings['simkl'];
      if (simklRating is Map<String, dynamic>) {
        rating = (simklRating['rating'] as num?)?.toDouble();
      }
      // fallback to imdb
      if (rating == null) {
        final imdbRating = ratings['imdb'];
        if (imdbRating is Map<String, dynamic>) {
          rating = (imdbRating['rating'] as num?)?.toDouble();
        }
      }
    }

    return ShowMetadata(
      title: title,
      overview: data['overview'] as String?,
      posterUrl: posterUrl(poster),
      backdropUrl: fanartUrl(fanart),
      rating: rating,
      year: year,
      genres: const [],
      cast: const [],
    );
  }
}
