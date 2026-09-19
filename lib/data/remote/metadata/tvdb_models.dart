import 'tvdb_provider.dart';

class TvdbSeries {
  final int id;
  final String name;
  final String? slug;
  final String? image;
  final String? year;
  final String? overview;
  final String? status;
  final double? score;
  final String? primaryLanguage;
  final List<String> genres;

  const TvdbSeries({
    required this.id,
    required this.name,
    this.slug,
    this.image,
    this.year,
    this.overview,
    this.status,
    this.score,
    this.primaryLanguage,
    this.genres = const [],
  });

  String? get posterUrl => TvdbProvider.buildImageUrl(image);

  factory TvdbSeries.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final id = parseInt(json['tvdb_id'] ?? json['id']) ?? 0;
    final name = (json['name'] ?? json['title'] ?? '') as String;
    final slug = json['slug'] as String?;
    final image =
        (json['image_url'] ?? json['image'] ?? json['thumbnail']) as String?;
    final year = json['year']?.toString();
    final overview = json['overview'] as String?;

    String? statusName;
    final statusObj = json['status'];
    if (statusObj is Map<String, dynamic>) {
      statusName = statusObj['name'] as String?;
    } else if (statusObj is String) {
      statusName = statusObj;
    }

    final score = parseDouble(json['score']);
    final primaryLanguage =
        (json['primary_language'] ?? json['language']) as String?;

    List<String> parsedGenres = [];
    final rawGenres = json['genres'];
    if (rawGenres is List) {
      parsedGenres = rawGenres
          .map((g) {
            if (g is Map<String, dynamic>) {
              return (g['name'] ?? '').toString();
            }
            return g.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return TvdbSeries(
      id: id,
      name: name,
      slug: slug,
      image: image,
      year: year,
      overview: overview,
      status: statusName,
      score: score,
      primaryLanguage: primaryLanguage,
      genres: parsedGenres,
    );
  }
}

class TvdbSeriesExtended {
  final TvdbSeries series;
  final List<TvdbSeason> seasons;
  final List<TvdbArtwork> artworks;

  const TvdbSeriesExtended({
    required this.series,
    this.seasons = const [],
    this.artworks = const [],
  });

  factory TvdbSeriesExtended.fromJson(Map<String, dynamic> json) {
    final series = TvdbSeries.fromJson(json);

    List<TvdbSeason> seasons = [];
    final rawSeasons = json['seasons'];
    if (rawSeasons is List) {
      seasons = rawSeasons
          .whereType<Map<String, dynamic>>()
          .map(TvdbSeason.fromJson)
          .toList();
    }

    List<TvdbArtwork> artworks = [];
    final rawArtworks = json['artworks'];
    if (rawArtworks is List) {
      artworks = rawArtworks
          .whereType<Map<String, dynamic>>()
          .map(TvdbArtwork.fromJson)
          .toList();
    }

    return TvdbSeriesExtended(
      series: series,
      seasons: seasons,
      artworks: artworks,
    );
  }
}

class TvdbSeason {
  final int id;
  final int? seriesId;
  final int number;
  final String? name;
  final String? image;
  final String? type;

  const TvdbSeason({
    required this.id,
    this.seriesId,
    required this.number,
    this.name,
    this.image,
    this.type,
  });

  String? get imageUrl => TvdbProvider.buildImageUrl(image);

  factory TvdbSeason.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? typeName;
    final typeObj = json['type'];
    if (typeObj is Map<String, dynamic>) {
      typeName = (typeObj['type'] ?? typeObj['name']) as String?;
    } else if (typeObj is String) {
      typeName = typeObj;
    }

    return TvdbSeason(
      id: parseInt(json['id']) ?? 0,
      seriesId: parseInt(json['seriesId']),
      number: parseInt(json['number']) ?? 0,
      name: json['name'] as String?,
      image: json['image'] as String?,
      type: typeName,
    );
  }
}

class TvdbEpisode {
  final int id;
  final int? seriesId;
  final String name;
  final int? number;
  final int? seasonNumber;
  final String? aired;
  final int? runtime;
  final String? overview;
  final String? image;
  final String? year;

  const TvdbEpisode({
    required this.id,
    this.seriesId,
    required this.name,
    this.number,
    this.seasonNumber,
    this.aired,
    this.runtime,
    this.overview,
    this.image,
    this.year,
  });

  String? get imageUrl => TvdbProvider.buildImageUrl(image);

  TvdbEpisode copyWith({
    int? id,
    int? seriesId,
    String? name,
    int? number,
    int? seasonNumber,
    String? aired,
    int? runtime,
    String? overview,
    String? image,
    String? year,
  }) {
    return TvdbEpisode(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      name: name ?? this.name,
      number: number ?? this.number,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      aired: aired ?? this.aired,
      runtime: runtime ?? this.runtime,
      overview: overview ?? this.overview,
      image: image ?? this.image,
      year: year ?? this.year,
    );
  }

  factory TvdbEpisode.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return TvdbEpisode(
      id: parseInt(json['id']) ?? 0,
      seriesId: parseInt(json['seriesId']),
      name: (json['name'] ?? '') as String,
      number: parseInt(json['number']),
      seasonNumber: parseInt(json['seasonNumber']),
      aired: json['aired'] as String?,
      runtime: parseInt(json['runtime']),
      overview: json['overview'] as String?,
      image: (json['image'] ?? json['thumbnail']) as String?,
      year: json['year']?.toString(),
    );
  }
}

class TvdbArtwork {
  final int id;
  final String image;
  final String? thumbnail;
  final String? language;
  final int type;
  final double? score;
  final int? width;
  final int? height;
  final int? seasonId;

  const TvdbArtwork({
    required this.id,
    required this.image,
    this.thumbnail,
    this.language,
    required this.type,
    this.score,
    this.width,
    this.height,
    this.seasonId,
  });

  String get fullImageUrl => TvdbProvider.buildImageUrl(image) ?? image;
  String? get thumbnailUrl => TvdbProvider.buildImageUrl(thumbnail);

  bool get isBanner =>
      type == 1 ||
      (width != null &&
          height != null &&
          height! > 0 &&
          (width! / height!) >= 2.5);

  bool get isPoster =>
      type == 2 || (width != null && height != null && height! > width!);

  bool get isBackground => type == 3;

  factory TvdbArtwork.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return TvdbArtwork(
      id: parseInt(json['id']) ?? 0,
      image: (json['image'] ?? '') as String,
      thumbnail: json['thumbnail'] as String?,
      language: json['language'] as String?,
      type: parseInt(json['type']) ?? 0,
      score: parseDouble(json['score']),
      width: parseInt(json['width']),
      height: parseInt(json['height']),
      seasonId: parseInt(json['seasonId']),
    );
  }
}

class TvdbArtworkType {
  final int id;
  final String name;
  final String? recordType;
  final String? slug;

  const TvdbArtworkType({
    required this.id,
    required this.name,
    this.recordType,
    this.slug,
  });

  factory TvdbArtworkType.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return TvdbArtworkType(
      id: parseInt(json['id']) ?? 0,
      name: (json['name'] ?? '') as String,
      recordType: json['recordType'] as String?,
      slug: json['slug'] as String?,
    );
  }
}
