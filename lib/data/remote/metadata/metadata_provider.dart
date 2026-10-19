abstract class MetadataProvider {
  // display name for the provider
  String get name;

  Future<ShowMetadata?> fetchMetadata(String title, {int? year});

  Future<String?> fetchPosterUrl(String title, {int? year});
}

class ShowMetadata {
  final String title;
  final String? titleEn;
  final String? overview;
  final String? posterUrl;
  final String? posterPath;
  final String? backdropUrl;
  final String? fanartPath;
  final double? rating;
  final double? ratingSimkl;
  final double? ratingMal;
  final double? ratingImdb;
  final int? year;
  final int? simklId;
  final String? mediaType;
  final String? slug;
  final String? imdbId;
  final String? tmdbId;
  final int? malId;
  final int? anilistId;
  final int? tvdbId;
  final String? anidbId;
  final List<String> genres;
  final List<String> cast;

  const ShowMetadata({
    required this.title,
    this.titleEn,
    this.overview,
    this.posterUrl,
    this.posterPath,
    this.backdropUrl,
    this.fanartPath,
    this.rating,
    this.ratingSimkl,
    this.ratingMal,
    this.ratingImdb,
    this.year,
    this.simklId,
    this.mediaType,
    this.slug,
    this.imdbId,
    this.tmdbId,
    this.malId,
    this.anilistId,
    this.tvdbId,
    this.anidbId,
    this.genres = const [],
    this.cast = const [],
  });
}

// result from Simkl /search/file
class SimklFileResult {
  final String title;
  final String? titleEn;
  final String? mediaType; // tv, anime, movie
  final String? animeType; // tv, movie, ova, ona, special
  final int? season;
  final int? episode;
  final int? year;
  final int? totalEpisodes;
  final String? posterPath; // raw path, not full URL
  final String? fanartPath;
  final String? overview;
  final double? ratingSimkl;
  final double? ratingMal;
  final double? ratingImdb;

  // external IDs
  final int? simklId;
  final String? slug;
  final String? imdbId;
  final String? tmdbId;
  final int? malId;
  final int? anilistId;
  final int? tvdbId;
  final String? anidbId;

  const SimklFileResult({
    required this.title,
    this.titleEn,
    this.mediaType,
    this.animeType,
    this.season,
    this.episode,
    this.year,
    this.totalEpisodes,
    this.posterPath,
    this.fanartPath,
    this.overview,
    this.ratingSimkl,
    this.ratingMal,
    this.ratingImdb,
    this.simklId,
    this.slug,
    this.imdbId,
    this.tmdbId,
    this.malId,
    this.anilistId,
    this.tvdbId,
    this.anidbId,
  });
}
