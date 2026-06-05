// ignore_for_file: avoid_print
// this is a simple test script to run the scraper and print results to console it does not save anything to disk
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
    final results = await DirectoryScraper.scrapeDirectory(targetUrl);

    print('Scraping Complete in ${stopwatch.elapsed.inSeconds}s');
    print('Found ${results.length} files:\n');

    for (var i = 0; i < results.length; i++) {
      print('${i + 1}. ${results[i]}');
    }
  } catch (e) {
    print('\nFatal Error: $e');
  }
}
