import 'package:argus/core/constants.dart';
import 'package:argus/core/utils/name_cleaner.dart';
import 'package:argus/core/utils/url_utils.dart';
import 'package:argus/data/scrapers/scrape_result.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class ScrapeProgress {
  final String message;
  final String? currentUrl;
  final int urlsVisited;
  final int urlsQueued;
  final int filesFound;
  final bool isDone;
  final String? error;
  final List<ScrapeResult> results;

  const ScrapeProgress({
    required this.message,
    this.currentUrl,
    this.urlsVisited = 0,
    this.urlsQueued = 0,
    this.filesFound = 0,
    this.isDone = false,
    this.error,
    this.results = const [],
  });
}

class DirectoryScraper {
  static Stream<ScrapeProgress> scrapeWithProgress(String baseUrl) async* {
    final baseUri = Uri.parse(baseUrl);
    final results = <ScrapeResult>[];
    final visited = <String>{};
    final queue = <String>[baseUrl];
    int urlsVisited = 0;

    yield ScrapeProgress(
      message: 'Starting scrape of ${baseUri.host}...',
      currentUrl: baseUrl,
      urlsQueued: 1,
    );

    while (queue.isNotEmpty) {
      final url = queue.removeAt(0);
      if (visited.contains(url)) continue;
      visited.add(url);
      urlsVisited++;

      yield ScrapeProgress(
        message: 'Fetching page...',
        currentUrl: url,
        urlsVisited: urlsVisited,
        urlsQueued: queue.length,
        filesFound: results.length,
      );

      try {
        final uri = Uri.parse(url);
        final response = await http.get(uri).timeout(kScrapeTimeout);

        if (response.statusCode != 200) {
          yield ScrapeProgress(
            message: 'HTTP ${response.statusCode} — skipping',
            currentUrl: url,
            urlsVisited: urlsVisited,
            urlsQueued: queue.length,
            filesFound: results.length,
            error: 'HTTP ${response.statusCode}',
          );
          continue;
        }

        final document = html_parser.parse(response.body);
        final links = document.querySelectorAll('a[href]');

        int newDirs = 0;
        int newFiles = 0;
        int skippedOutOfScope = 0;

        for (final link in links) {
          final href = link.attributes['href'];
          if (href == null || href.isEmpty) continue;
          if (isNavigationLink(href)) continue;

          final resolved = resolveUrl(uri, href);
          final resolvedStr = resolved.toString();

          if (isDirectoryPath(href)) {
            if (!isSubpath(baseUri, resolved)) {
              skippedOutOfScope++;
              continue;
            }
            if (!visited.contains(resolvedStr)) {
              queue.add(resolvedStr);
              newDirs++;
            }
          } else {
            if (!isSubpath(baseUri, resolved)) {
              skippedOutOfScope++;
              continue;
            }
            final filename = filenameFromUrl(resolved);
            final ext = extensionFromFilename(filename);
            if (ext != null && kMediaExtensions.contains(ext)) {
              final cleaned = NameCleaner.clean(filename);
              final parentFolder = extractShowFolder(baseUri, resolved);
              final group = NameCleaner.cleanFolderName(parentFolder);

              int? season = cleaned.season;
              int? episode = cleaned.episode;
              String title = cleaned.title;

              if (season == null) {
                final segments = resolved.pathSegments
                    .where((s) => s.isNotEmpty)
                    .toList();
                if (segments.length >= 2) {
                  final parent = Uri.decodeComponent(
                    segments[segments.length - 2],
                  );
                  if (isSeasonFolder(parent)) {
                    final match = RegExp(
                      r'\b(?:Season\s*|S)(\d{1,2})\b',
                      caseSensitive: false,
                    ).firstMatch(parent);
                    if (match != null) {
                      season = int.tryParse(match.group(1)!);
                      if (episode == null) {
                        String tempTitle = title;
                        final groupTitleLower = group.title.toLowerCase();
                        final titleLower = tempTitle.toLowerCase();

                        if (groupTitleLower.isNotEmpty &&
                            titleLower.startsWith(groupTitleLower)) {
                          tempTitle = tempTitle
                              .substring(groupTitleLower.length)
                              .trim();
                        }

                        final epMatch = RegExp(
                          r'\b(\d{1,4})\b',
                        ).firstMatch(tempTitle);
                        if (epMatch != null) {
                          episode = int.tryParse(epMatch.group(1)!);
                          title = tempTitle
                              .replaceFirst(epMatch.group(0)!, ' ')
                              .trim();
                          title = '${group.title} $title'
                              .replaceAll(RegExp(r'\s{2,}'), ' ')
                              .trim();
                        }
                      }
                    }
                  } else {
                    final cleanParent = parent.trim().toLowerCase();
                    if (RegExp(
                      r'^(specials?|movies?|extras?|ovas?|nc|op-?ed|op|ed|s00?)$',
                    ).hasMatch(cleanParent)) {
                      if (parentFolder.trim().toLowerCase() != cleanParent) {
                        season = 0;
                      }
                    }
                  }
                }
              }

              results.add(
                ScrapeResult(
                  rawName: filename,
                  cleanTitle: title,
                  groupTitle: group.title.isEmpty ? cleaned.title : group.title,
                  year: group.year ?? cleaned.year,
                  directUrl: resolvedStr,
                  type: ScrapeItemType.file,
                  season: season,
                  episode: episode,
                  fileExtension: ext,
                ),
              );
              newFiles++;
            }
          }
        }

        final scopeMsg = skippedOutOfScope > 0
            ? ' ($skippedOutOfScope external skipped)'
            : '';
        yield ScrapeProgress(
          message: 'Found $newFiles files, $newDirs subdirs$scopeMsg',
          currentUrl: url,
          urlsVisited: urlsVisited,
          urlsQueued: queue.length,
          filesFound: results.length,
        );
      } catch (e) {
        yield ScrapeProgress(
          message: 'Error: $e',
          currentUrl: url,
          urlsVisited: urlsVisited,
          urlsQueued: queue.length,
          filesFound: results.length,
          error: e.toString(),
        );
        continue;
      }
    }

    yield ScrapeProgress(
      message: 'Done! Found ${results.length} files in $urlsVisited pages.',
      urlsVisited: urlsVisited,
      urlsQueued: 0,
      filesFound: results.length,
      isDone: true,
      results: results,
    );
  }
}
