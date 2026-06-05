import 'package:argus/core/constants.dart';
import 'package:argus/core/utils/name_cleaner.dart';
import 'package:argus/core/utils/url_utils.dart';
import 'package:argus/data/scrapers/scrape_result.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class DirectoryScraper {
  static Future<List<ScrapeResult>> scrape(String baseUrl) async {
    final results = <ScrapeResult>[];
    return results;
  }

  static Future<List<ScrapeResult>> scrapeDirectory(String baseUrl) async {
    final results = <ScrapeResult>[];
    final visited = <String>{};
    final queue = <String>[baseUrl];

    while (queue.isNotEmpty) {
      final url = queue.removeAt(0);
      if (visited.contains(url)) continue;
      visited.add(url);

      try {
        final uri = Uri.parse(url);
        print('Fetching: $url');

        final response = await http.get(uri).timeout(kScrapeTimeout);
        if (response.statusCode != 200) {
          print('Bad Status: ${response.statusCode} on $url');
          continue;
        }

        final document = html_parser.parse(response.body);
        final links = document.querySelectorAll('a[href]');
        print('Found ${links.length} raw links on this page');

        for (final link in links) {
          final href = link.attributes['href'];
          if (href == null || href.isEmpty) continue;
          if (isNavigationLink(href)) continue;

          final resolved = resolveUrl(uri, href);
          final resolvedStr = resolved.toString();

          // avoid accidentally crawl external websites
          if (!isSameDomain(Uri.parse(baseUrl), resolved)) continue;

          if (isDirectoryPath(href)) {
            if (!visited.contains(resolvedStr)) {
              queue.add(resolvedStr);
            }
          } else {
            final filename = filenameFromUrl(resolved);

            // block hidden OS files
            if (isSystemFile(filename)) continue;

            final ext = extensionFromFilename(filename);
            if (ext != null && kMediaExtensions.contains(ext)) {
              final cleaned = NameCleaner.clean(filename);
              results.add(
                ScrapeResult(
                  rawName: filename,
                  cleanTitle: cleaned.title,
                  directUrl: resolvedStr,
                  type: ScrapeItemType.file,
                  season: cleaned.season,
                  episode: cleaned.episode,
                  fileExtension: ext,
                ),
              );
            }
          }
        }
      } catch (e) {
        print('Error fetching $url: $e');
        continue;
      }
    }

    return results;
  }
}
