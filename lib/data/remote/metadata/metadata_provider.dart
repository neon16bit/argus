abstract class MetadataProvider {
  // display name for the provider
  String get name;

  Future<ShowMetadata?> fetchMetadata(String title, {int? year});

  Future<String?> fetchPosterUrl(String title, {int? year});
}

class ShowMetadata {
  final String title;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final double? rating;
  final int? year;
  final List<String> genres;
  final List<String> cast;

  const ShowMetadata({
    required this.title,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.year,
    this.genres = const [],
    this.cast = const [],
  });
}

// result from Simkl /search/file
class SimklFileResult {
  final String title;
  final String? mediaType; // tv, anime, movie
  final String? animeType; // tv, movie, ova, ona, special
  final int? year;
  final int? totalEpisodes;
  final String? posterPath; // raw path, not full URL
  final String? fanartPath;
  final String? overview;

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
    this.mediaType,
    this.animeType,
    this.year,
    this.totalEpisodes,
    this.posterPath,
    this.fanartPath,
    this.overview,
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
