enum ScrapeItemType { file, folder }

class ScrapeResult {
  final String rawName;
  final String cleanTitle;
  final String groupTitle;
  final String directUrl;
  final ScrapeItemType type;
  final int? season;
  final int? episode;
  final String? fileExtension;
  final int? fileSize;
  final int? year;

  const ScrapeResult({
    required this.rawName,
    required this.cleanTitle,
    required this.groupTitle,
    required this.directUrl,
    required this.type,
    this.season,
    this.episode,
    this.fileExtension,
    this.fileSize,
    this.year,
  });

  ScrapeResult copyWith({
    String? rawName,
    String? cleanTitle,
    String? groupTitle,
    String? directUrl,
    ScrapeItemType? type,
    int? season,
    int? episode,
    String? fileExtension,
    int? fileSize,
    int? year,
  }) {
    return ScrapeResult(
      rawName: rawName ?? this.rawName,
      cleanTitle: cleanTitle ?? this.cleanTitle,
      groupTitle: groupTitle ?? this.groupTitle,
      directUrl: directUrl ?? this.directUrl,
      type: type ?? this.type,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      year: year ?? this.year,
    );
  }

  @override
  String toString() {
    if (type == ScrapeItemType.folder) {
      return 'FOLDER: $cleanTitle ($directUrl)';
    }

    final details = [
      if (season != null) 'S${season.toString().padLeft(2, '0')}',
      if (episode != null) 'E${episode.toString().padLeft(2, '0')}',
    ].join('|');

    return 'FILE: $cleanTitle ${details.isNotEmpty ? '[$details]' : ''}';
  }
}
