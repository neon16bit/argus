// ignore_for_file: avoid_print
// this is a simple test script to run the scraper and print results to console it does not save anything to disk
import 'package:argus/data/scrapers/scrape_result.dart';
import 'package:argus/data/scrapers/directory_scraper.dart';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Error: Missing target URL.');
    print('Usage: dart run bin/scrape.dart <http://example.com/>\n');
    exit(1);
  }

  final targetUrl = args.first;

  print('\n=== ARGUS SCRAPER TEST ===');
  print('Target: $targetUrl\n');

  final stopwatch = Stopwatch()..start();

  try {
    var results = <ScrapeResult>[];
    await for (final progress in DirectoryScraper.scrapeWithProgress(
      targetUrl,
    )) {
      if (progress.isDone) {
        results = progress.results;
        break;
      }
      stdout.write(
        '\r${progress.message}                                     ',
      );
    }
    print('');

    print('Scraping Complete in ${stopwatch.elapsed.inSeconds}s');
    print('Found ${results.length} files:\n');

    // group results by groupTitle for display
    final grouped = <String, List<ScrapeResult>>{};
    for (final r in results) {
      (grouped[r.groupTitle] ??= []).add(r);
    }

    for (final entry in grouped.entries) {
      print('\n--- ${entry.key} (${entry.value.length} files) ---');
      for (var i = 0; i < entry.value.length; i++) {
        print('  ${i + 1}. ${entry.value[i]}');
      }
    }
  } catch (e) {
    print('\nFatal Error: $e');
  }
}
