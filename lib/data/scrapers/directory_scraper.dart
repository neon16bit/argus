import 'dart:collection';
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

class FolderEntry {
  final String rawName;
  final String cleanTitle;
  final String folderUrl;
  final int? year;
  const FolderEntry({
    required this.rawName,
    required this.cleanTitle,
    required this.folderUrl,
    this.year,
  });
}

class DirectoryScraper {
  static const int _initialDepth = 0;

  static final _seasonFolderPattern = RegExp(
    r'\b(?:Season\s*|S)(\d{1,2})\b',
    caseSensitive: false,
  );
  static final _episodeNumberPattern = RegExp(r'\b(\d{1,4})\b');
  static final _specialFolderPattern = RegExp(
    r'^(specials?|movies?|extras?|ovas?|nc|op-?ed|op|ed|s00?)$',
  );

  // fetches only the root page and returns top level directory entries
  // returns null if the page looks like a show level source (dirs are season folders)
  static Future<List<FolderEntry>?> shallowIndex(
    String baseUrl, {
    int maxDepth = 1,
  }) async {
    final baseUri = Uri.parse(baseUrl);
    final results = <FolderEntry>[];
    final success = await _shallowIndexRecurse(
      baseUri,
      baseUri,
      results,
      _initialDepth,
      maxDepth,
    );
    if (!success) return null;
    return results;
  }

  static Future<bool> _shallowIndexRecurse(
    Uri baseUri,
    Uri currentUri,
    List<FolderEntry> results,
    int depth,
    int maxDepth,
  ) async {
    if (depth > maxDepth) return true;
    try {
      final response = await http.get(currentUri).timeout(kScrapeTimeout);
      if (response.statusCode != 200) return true;

      final links = html_parser
          .parse(response.body)
          .querySelectorAll('a[href]');

      final dirs = <FolderEntry>[];
      int seasonLike = 0;
      final needsRecursion = depth < maxDepth - 1;
      final nextLevelDirs = <Uri>[];
      bool hasMediaFiles = false;

      for (final link in links) {
        final href = link.attributes['href'];
        if (href == null || href.isEmpty) continue;
        if (isNavigationLink(href)) continue;

        final resolved = resolveUrl(currentUri, href);
        if (!isSubpath(baseUri, resolved)) continue;

        if (isDirectoryPath(href)) {
          final rawName = resolved.pathSegments
              .where((s) => s.isNotEmpty)
              .lastOrNull;
          if (rawName == null) continue;

          if (isFolderToClimb(rawName)) {
            seasonLike++;
            continue;
          }

          if (needsRecursion) {
            nextLevelDirs.add(resolved);
          } else {
            final cleaned = NameCleaner.cleanFolderName(rawName);
            final baseCleanTitle = cleaned.title.isEmpty
                ? rawName
                : cleaned.title;
            final cleanTitleWithYear = (cleaned.year != null)
                ? '$baseCleanTitle (${cleaned.year})'
                : baseCleanTitle;
            dirs.add(
              FolderEntry(
                rawName: rawName,
                cleanTitle: cleanTitleWithYear,
                folderUrl: resolved.toString(),
                year: cleaned.year,
              ),
            );
          }
        } else if (depth > 0 && !hasMediaFiles) {
          // only check for media files inside subdirectories (leaf detection)
          final filename = filenameFromUrl(resolved);
          final ext = extensionFromFilename(filename);
          if (ext != null && kMediaExtensions.contains(ext)) {
            hasMediaFiles = true;
          }
        }
      }

      if (depth > 0 &&
          (hasMediaFiles || (dirs.isEmpty && nextLevelDirs.isEmpty))) {
        final rawName =
            currentUri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
        if (rawName.isNotEmpty) {
          final cleaned = NameCleaner.cleanFolderName(rawName);
          final baseCleanTitle = cleaned.title.isEmpty
              ? rawName
              : cleaned.title;
          final cleanTitleWithYear = (cleaned.year != null)
              ? '$baseCleanTitle (${cleaned.year})'
              : baseCleanTitle;
          results.add(
            FolderEntry(
              rawName: rawName,
              cleanTitle: cleanTitleWithYear,
              folderUrl: currentUri.toString(),
              year: cleaned.year,
            ),
          );
        }
        return true;
      }

      if (seasonLike > (dirs.length + nextLevelDirs.length)) {
        return depth > 0;
      }

      results.addAll(dirs);

      for (final groupUri in nextLevelDirs) {
        final ok = await _shallowIndexRecurse(
          baseUri,
          groupUri,
          results,
          depth + 1,
          maxDepth,
        );
        if (!ok) return false;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  static Stream<ScrapeProgress> scrapeWithProgress(
    String baseUrl, {
    Duration requestDelay = Duration.zero,
    String? groupTitle,
  }) async* {
    final baseUri = Uri.parse(baseUrl);
    final results = <ScrapeResult>[];
    final visited = <String>{};
    final queue = Queue<String>()..add(baseUrl);
    int urlsVisited = 0;

    final groupFromParam = groupTitle != null
        ? NameCleaner.cleanFolderName(groupTitle)
        : null;

    yield ScrapeProgress(
      message: 'Starting scrape of ${baseUri.host}...',
      currentUrl: baseUrl,
      urlsQueued: 1,
    );

    while (queue.isNotEmpty) {
      final url = queue.removeFirst();
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
        if (requestDelay > Duration.zero) await Future.delayed(requestDelay);
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

              final String parentFolder;
              final CleanResult group;
              if (groupTitle != null) {
                parentFolder = groupTitle;
                group = groupFromParam!;
              } else {
                parentFolder = extractShowFolder(baseUri, resolved);
                group = NameCleaner.cleanFolderName(parentFolder);
              }

              int? season = cleaned.season;
              int? episode = cleaned.episode;
              String title = cleaned.title;

              if (season == null) {
                final segments = resolved.pathSegments
                    .where((s) => s.isNotEmpty)
                    .toList();
                if (segments.length >= 2) {
                  final parent = segments[segments.length - 2];
                  if (isSeasonFolder(parent)) {
                    final match = _seasonFolderPattern.firstMatch(parent);
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

                        final epMatch = _episodeNumberPattern.firstMatch(
                          tempTitle,
                        );
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
                    if (_specialFolderPattern.hasMatch(cleanParent)) {
                      if (parentFolder.trim().toLowerCase() != cleanParent) {
                        season = 0;
                      }
                    }
                  }
                }
              }

              if (cleaned.isSample && season == null && episode == null) {
                continue;
              }

              final cleanGroupTitle = group.title.isEmpty
                  ? cleaned.title
                  : group.title;
              final year = group.year ?? cleaned.year;
              final groupTitleWithYear = (year != null)
                  ? '$cleanGroupTitle ($year)'
                  : cleanGroupTitle;

              results.add(
                ScrapeResult(
                  rawName: filename,
                  cleanTitle: title,
                  groupTitle: groupTitleWithYear,
                  year: year,
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
