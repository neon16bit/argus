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
  });

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
