import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:argus/core/constants.dart';
import 'metadata_provider.dart';
import 'tvdb_models.dart';

export 'tvdb_models.dart';

class TvdbProvider extends MetadataProvider {
  static const _defaultApiKey = String.fromEnvironment('TVDB_API_KEY');
  static const _timeout = Duration(seconds: 10);

  final String? appName;
  final String? appVersion;
  final String? customApiKey;

  String? _token;
  DateTime? _tokenExpiry;

  TvdbProvider({this.appName, this.appVersion, this.customApiKey}) {
    if (_apiKey.isEmpty) {
      debugPrint(
        '[TheTVDB] WARNING: TVDB_API_KEY is empty. '
        'Pass --dart-define=TVDB_API_KEY=your_key or configure custom key in Settings.',
      );
    } else {
      debugPrint(
        '[TheTVDB] Initialized with ${isCustomKey ? "custom" : "built-in"} api_key: '
        '${_apiKey.substring(0, _apiKey.length > 8 ? 8 : _apiKey.length)}...',
      );
    }
  }

  String get _apiKey {
    final custom = customApiKey?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return _defaultApiKey;
  }

  bool get isConfigured => _apiKey.isNotEmpty;
  bool get isCustomKey =>
      customApiKey != null && customApiKey!.trim().isNotEmpty;
  static bool get hasDefaultKey => _defaultApiKey.isNotEmpty;

  Future<(bool, String?)> testConnection({String? testApiKey}) async {
    final key = testApiKey?.trim() ?? _apiKey;
    if (key.isEmpty) {
      return (false, 'API key cannot be empty');
    }
    try {
      final uri = Uri.parse('$kTvdbBaseUrl/login');
      final body = <String, dynamic>{'apikey': key};

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic> &&
            json['data'] is Map<String, dynamic> &&
            json['data']['token'] != null) {
          return (true, null);
        }
      }

      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['message'] != null) {
          return (false, '${json['message']} (${response.statusCode})');
        }
      } catch (_) {}

      return (
        false,
        'HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Authentication failed"}',
      );
    } catch (e) {
      return (false, 'Connection error: $e');
    }
  }

  @override
  String get name => 'TheTVDB';

  // build image url from image/artwork path
  static String? buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$kTvdbImageBase$cleanPath';
  }

  // authentication
  Future<String?> _getToken() async {
    if (_token != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _token;
    }
    return await _login();
  }

  Future<String?> _login() async {
    if (_apiKey.isEmpty) return null;
    try {
      final uri = Uri.parse('$kTvdbBaseUrl/login');
      final body = <String, dynamic>{'apikey': _apiKey};

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint(
          '[TheTVDB] Login failed (${response.statusCode}): ${response.body}',
        );
        return null;
      }

      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> &&
          json['data'] is Map<String, dynamic>) {
        final token = json['data']['token'] as String?;
        if (token != null && token.isNotEmpty) {
          _token = token;
          _tokenExpiry = DateTime.now().add(const Duration(days: 25));
          debugPrint('[TheTVDB] Authenticated successfully.');
          return _token;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[TheTVDB] Login error: $e');
      return null;
    }
  }

  Future<http.Response?> _get(Uri uri) async {
    final token = await _getToken();
    if (token == null) return null;

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (appName != null && appVersion != null)
        'User-Agent': '$appName/$appVersion',
    };

    var response = await http.get(uri, headers: headers).timeout(_timeout);
    if (response.statusCode == 401) {
      debugPrint(
        '[TheTVDB] 401 Unauthorized, refreshing token and retrying...',
      );
      _token = null;
      _tokenExpiry = null;
      final refreshed = await _login();
      if (refreshed == null) return null;

      headers['Authorization'] = 'Bearer $refreshed';
      response = await http.get(uri, headers: headers).timeout(_timeout);
    }
    return response;
  }

  // cross reference search
  Future<TvdbSeries?> fetchSeriesByRemoteId(String remoteId) async {
    if (_apiKey.isEmpty) return null;
    try {
      final cleanId = remoteId.trim();
      final uri = Uri.parse('$kTvdbBaseUrl/search/remoteid/$cleanId');
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;

      final data = json['data'];
      if (data is List && data.isNotEmpty) {
        for (final item in data) {
          if (item is Map<String, dynamic> && item['series'] != null) {
            return TvdbSeries.fromJson(item['series'] as Map<String, dynamic>);
          }
        }
        final first = data.first;
        if (first is Map<String, dynamic>) {
          if (first['series'] != null) {
            return TvdbSeries.fromJson(first['series'] as Map<String, dynamic>);
          }
          return TvdbSeries.fromJson(first);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[TheTVDB] Error searching remote ID "$remoteId": $e');
      return null;
    }
  }

  Future<TvdbSeries?> fetchSeries(int tvdbId) async {
    if (_apiKey.isEmpty) return null;
    try {
      final uri = Uri.parse('$kTvdbBaseUrl/series/$tvdbId');
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> &&
          json['data'] is Map<String, dynamic>) {
        return TvdbSeries.fromJson(json['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[TheTVDB] Error fetching series $tvdbId: $e');
      return null;
    }
  }

  // series extended record
  Future<TvdbSeriesExtended?> fetchSeriesExtended(int tvdbId) async {
    if (_apiKey.isEmpty) return null;
    try {
      final uri = Uri.parse('$kTvdbBaseUrl/series/$tvdbId/extended');
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> &&
          json['data'] is Map<String, dynamic>) {
        return TvdbSeriesExtended.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('[TheTVDB] Error fetching extended series $tvdbId: $e');
      return null;
    }
  }

  // movie extended record
  Future<TvdbSeriesExtended?> fetchMovieExtended(int tvdbId) async {
    if (_apiKey.isEmpty) return null;
    try {
      final uri = Uri.parse('$kTvdbBaseUrl/movies/$tvdbId/extended');
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> &&
          json['data'] is Map<String, dynamic>) {
        return TvdbSeriesExtended.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('[TheTVDB] Error fetching extended movie $tvdbId: $e');
      return null;
    }
  }

  // search by title text with optional type and year filter
  Future<List<TvdbSeries>> searchSeries(
    String query, {
    String? type,
    int? year,
  }) async {
    if (_apiKey.isEmpty) return const [];
    try {
      final params = <String, String>{
        'query': query,
        if (type != null && type.isNotEmpty) 'type': type,
        'year': ?year?.toString(),
      };
      final uri = Uri.parse(
        '$kTvdbBaseUrl/search',
      ).replace(queryParameters: params);
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return const [];

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return const [];

      final data = json['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TvdbSeries.fromJson)
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[TheTVDB] Error searching series "$query": $e');
      return const [];
    }
  }

  // translation for a single episode
  Future<String?> fetchEpisodeTranslation(
    int episodeId, {
    String lang = 'eng',
  }) async {
    if (_apiKey.isEmpty) return null;
    try {
      final uri = Uri.parse(
        '$kTvdbBaseUrl/episodes/$episodeId/translations/$lang',
      );
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> &&
          json['data'] is Map<String, dynamic>) {
        final name = json['data']['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          return name.trim();
        }
      }
      return null;
    } catch (e) {
      debugPrint(
        '[TheTVDB] Error fetching translation for episode $episodeId: $e',
      );
      return null;
    }
  }

  // translation for a series or movie
  Future<({String? name, String? overview})?> fetchSeriesTranslation(
    int seriesId, {
    bool isMovie = false,
    String lang = 'eng',
  }) async {
    if (_apiKey.isEmpty) return null;
    try {
      final type = isMovie ? 'movies' : 'series';
      final uri = Uri.parse('$kTvdbBaseUrl/$type/$seriesId/translations/$lang');
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> &&
          json['data'] is Map<String, dynamic>) {
        final data = json['data'] as Map<String, dynamic>;
        final name = (data['name'] as String?)?.trim();
        final overview = (data['overview'] as String?)?.trim();
        return (
          name: name?.isNotEmpty == true ? name : null,
          overview: overview?.isNotEmpty == true ? overview : null,
        );
      }
      return null;
    } catch (e) {
      debugPrint('[TheTVDB] Error fetching translation for $seriesId: $e');
      return null;
    }
  }

  // episodes by series TVDB ID
  Future<List<TvdbEpisode>> fetchEpisodes(
    int tvdbId, {
    String seasonType = 'official',
    String? lang = 'eng',
    int page = 0,
  }) async {
    if (_apiKey.isEmpty) return const [];
    try {
      final langSegment = (lang != null && lang.isNotEmpty) ? '/$lang' : '';

      final candidates = <String>[
        if (langSegment.isNotEmpty) '$seasonType$langSegment',
        if (langSegment.isNotEmpty && seasonType != 'official')
          'official$langSegment',
        if (langSegment.isNotEmpty && seasonType != 'default')
          'default$langSegment',
        seasonType,
        if (seasonType != 'official') 'official',
        if (seasonType != 'default') 'default',
      ];

      http.Response? response;
      for (final candidate in candidates) {
        final uri = Uri.parse(
          '$kTvdbBaseUrl/series/$tvdbId/episodes/$candidate',
        ).replace(queryParameters: {'page': page.toString()});
        response = await _get(uri);
        if (response != null && response.statusCode == 200) {
          debugPrint('[TheTVDB] Fetched episodes via route: $candidate');
          break;
        }
      }

      if (response == null || response.statusCode != 200) return const [];

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return const [];

      final data = json['data'];
      if (data is! Map<String, dynamic> || data['episodes'] is! List) {
        return const [];
      }

      final rawList = (data['episodes'] as List)
          .whereType<Map<String, dynamic>>();
      List<TvdbEpisode> episodes = rawList.map(TvdbEpisode.fromJson).toList();

      if (lang == 'eng' && episodes.isNotEmpty) {
        final needsTranslation = episodes.any(
          (ep) => _containsCjk(ep.name) || ep.name.isEmpty,
        );

        if (needsTranslation) {
          debugPrint(
            '[TheTVDB] Episode titles are non-English. Resolving English translations...',
          );
          final translated = await Future.wait(
            episodes.map((ep) async {
              if (_containsCjk(ep.name) || ep.name.isEmpty) {
                final enName = await fetchEpisodeTranslation(
                  ep.id,
                  lang: 'eng',
                );
                if (enName != null && enName.isNotEmpty) {
                  return ep.copyWith(name: enName);
                }
              }
              return ep;
            }),
          );
          episodes = translated;
        }
      }

      return episodes;
    } catch (e) {
      debugPrint('[TheTVDB] Error fetching episodes for series $tvdbId: $e');
      return const [];
    }
  }

  static bool _containsCjk(String text) {
    return RegExp(
      r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uff66-\uff9f]',
    ).hasMatch(text);
  }

  Future<List<TvdbArtwork>> fetchArtworks(
    int tvdbId, {
    String? lang,
    int? type,
  }) async {
    if (_apiKey.isEmpty) return const [];
    try {
      final params = <String, String>{'lang': ?lang, 'type': ?type?.toString()};
      final uri = Uri.parse(
        '$kTvdbBaseUrl/series/$tvdbId/artworks',
      ).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return const [];

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return const [];

      final data = json['data'];
      if (data is Map<String, dynamic> && data['artworks'] is List) {
        return (data['artworks'] as List)
            .whereType<Map<String, dynamic>>()
            .map(TvdbArtwork.fromJson)
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[TheTVDB] Error fetching artworks for series $tvdbId: $e');
      return const [];
    }
  }

  Future<List<TvdbArtwork>> fetchBanners(int tvdbId) async {
    final artworks = await fetchArtworks(tvdbId);
    return artworks.where((a) => a.isBanner).toList();
  }

  // artwork types
  Future<List<TvdbArtworkType>> fetchArtworkTypes() async {
    if (_apiKey.isEmpty) return const [];
    try {
      final uri = Uri.parse('$kTvdbBaseUrl/artwork/types');
      final response = await _get(uri);
      if (response == null || response.statusCode != 200) return const [];

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return const [];

      final data = json['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TvdbArtworkType.fromJson)
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[TheTVDB] Error fetching artwork types: $e');
      return const [];
    }
  }

  @override
  Future<ShowMetadata?> fetchMetadata(String title, {int? year}) async {
    final list = await searchSeries(title, year: year);
    if (list.isEmpty) return null;
    final first = list.first;
    return ShowMetadata(
      title: first.name,
      overview: first.overview,
      posterUrl: first.posterUrl,
      posterPath: first.image,
      year: int.tryParse(first.year ?? ''),
      tvdbId: first.id,
      mediaType: 'tv',
      genres: first.genres,
    );
  }

  @override
  Future<String?> fetchPosterUrl(String title, {int? year}) async {
    final meta = await fetchMetadata(title, year: year);
    return meta?.posterUrl;
  }
}
