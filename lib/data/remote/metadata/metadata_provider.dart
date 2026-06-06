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
