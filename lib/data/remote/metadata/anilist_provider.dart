import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AnilistMetadata {
  final int id;
  final int? malId;
  final double? score;
  final String? format;
  final String? titleEnglish;
  final String? titleRomaji;
  final String? description;
  final String? coverImageUrl;
  final String? bannerImageUrl;

  const AnilistMetadata({
    required this.id,
    this.malId,
    this.score,
    this.format,
    this.titleEnglish,
    this.titleRomaji,
    this.description,
    this.coverImageUrl,
    this.bannerImageUrl,
  });

  factory AnilistMetadata.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    final id = parseInt(json['id']) ?? 0;
    final malId = parseInt(json['idMal']);
    final scoreNum = (json['averageScore'] ?? json['meanScore']) as num?;
    final score = scoreNum != null ? (scoreNum / 10.0) : null;

    final rawFormat = (json['format'] as String?)?.toUpperCase();
    String? format;
    if (rawFormat != null) {
      switch (rawFormat) {
        case 'TV':
        case 'TV_SHORT':
          format = 'tv';
          break;
        case 'MOVIE':
          format = 'movie';
          break;
        case 'OVA':
          format = 'ova';
          break;
        case 'ONA':
          format = 'ona';
          break;
        case 'SPECIAL':
          format = 'special';
          break;
        default:
          format = rawFormat.toLowerCase();
      }
    }

    final titleObj = json['title'] as Map<String, dynamic>? ?? {};
    final titleEnglish = titleObj['english'] as String?;
    final titleRomaji = titleObj['romaji'] as String?;
    final rawDesc = json['description'] as String?;
    String? description = rawDesc?.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (description != null) {
      final sourceMatch = RegExp(
        r'\(\s*source\s*:',
        caseSensitive: false,
      ).firstMatch(description);
      if (sourceMatch != null) {
        description = description.substring(0, sourceMatch.start).trim();
      }
      if (description.isEmpty) description = null;
    }

    final coverObj = json['coverImage'] as Map<String, dynamic>? ?? {};
    final coverImageUrl =
        (coverObj['extraLarge'] ?? coverObj['large']) as String?;
    final bannerImageUrl = json['bannerImage'] as String?;

    return AnilistMetadata(
      id: id,
      malId: malId,
      score: score,
      format: format,
      titleEnglish: titleEnglish,
      titleRomaji: titleRomaji,
      description: description,
      coverImageUrl: coverImageUrl,
      bannerImageUrl: bannerImageUrl,
    );
  }
}

class AnilistProvider {
  static const _endpoint = 'https://graphql.anilist.co';
  static const _timeout = Duration(seconds: 5);

  static const _queryWithYear = r'''
query ($search: String, $year: Int) {
  Media(search: $search, seasonYear: $year, type: ANIME, sort: [POPULARITY_DESC]) {
    id
    idMal
    averageScore
    format
    description
    title {
      romaji
      english
    }
    coverImage {
      extraLarge
      large
    }
    bannerImage
  }
}
''';

  static const _queryWithoutYear = r'''
query ($search: String) {
  Media(search: $search, type: ANIME, sort: [POPULARITY_DESC]) {
    id
    idMal
    averageScore
    format
    description
    title {
      romaji
      english
    }
    coverImage {
      extraLarge
      large
    }
    bannerImage
  }
}
''';

  static const _queryById = r'''
query ($id: Int) {
  Media(id: $id, type: ANIME) {
    id
    idMal
    averageScore
    format
    description
    title {
      romaji
      english
    }
    coverImage {
      extraLarge
      large
    }
    bannerImage
  }
}
''';

  static const _queryByMalId = r'''
query ($idMal: Int) {
  Media(idMal: $idMal, type: ANIME) {
    id
    idMal
    averageScore
    format
    description
    title {
      romaji
      english
    }
    coverImage {
      extraLarge
      large
    }
    bannerImage
  }
}
''';

  Future<AnilistMetadata?> fetchAnimeById(int id) async {
    return _executeGraphQL(_queryById, {'id': id});
  }

  Future<AnilistMetadata?> fetchAnimeByMalId(int malId) async {
    return _executeGraphQL(_queryByMalId, {'idMal': malId});
  }

  Future<AnilistMetadata?> searchAnime(String title, {int? year}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    if (year != null) {
      final res = await _executeGraphQL(_queryWithYear, {
        'search': cleanTitle,
        'year': year,
      });
      if (res != null) return res;
    }

    return _executeGraphQL(_queryWithoutYear, {'search': cleanTitle});
  }

  Future<AnilistMetadata?> _executeGraphQL(
    String query,
    Map<String, dynamic> variables,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'query': query, 'variables': variables}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;

      final data = json['data'] as Map<String, dynamic>?;
      final media = data?['Media'] as Map<String, dynamic>?;
      if (media == null) return null;
      return AnilistMetadata.fromJson(media);
    } catch (e) {
      debugPrint('[AniList] Error querying "$variables": $e');
      return null;
    }
  }
}
