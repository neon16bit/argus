import 'package:flutter_test/flutter_test.dart';
import 'package:argus/core/utils/url_utils.dart';

void main() {
  group('resolveUrl', () {
    test('resolves relative href against base URL', () {
      final base = Uri.parse('http://example.com/movies/');
      final result = resolveUrl(base, 'file.mkv');
      expect(result.toString(), 'http://example.com/movies/file.mkv');
    });

    test('preserves absolute URLs', () {
      final base = Uri.parse('http://example.com/');
      final result = resolveUrl(base, 'http://other.com/file.mp4');
      expect(result.toString(), 'http://other.com/file.mp4');
    });

    test('preserves https URLs', () {
      final base = Uri.parse('http://example.com/');
      final result = resolveUrl(base, 'https://secure.com/file.mp4');
      expect(result.toString(), 'https://secure.com/file.mp4');
    });

    test('decodes HTML entities', () {
      final base = Uri.parse('http://example.com/');
      final result = resolveUrl(base, 'file.mkv?a=1&amp;b=2');
      expect(result.toString(), contains('a=1&b=2'));
    });

    test('resolves parent directory hrefs', () {
      final base = Uri.parse('http://example.com/a/b/');
      final result = resolveUrl(base, '../file.mkv');
      expect(result.path, '/a/file.mkv');
    });
  });

  group('isNavigationLink', () {
    test('returns true for parent links', () {
      expect(isNavigationLink('../'), isTrue);
      expect(isNavigationLink('./'), isTrue);
      expect(isNavigationLink('/'), isTrue);
      expect(isNavigationLink('..'), isTrue);
      expect(isNavigationLink('.'), isTrue);
    });

    test('returns true for query/hash/mailto/javascript', () {
      expect(isNavigationLink('?sort=name'), isTrue);
      expect(isNavigationLink('#top'), isTrue);
      expect(isNavigationLink('mailto:a@b.com'), isTrue);
      expect(isNavigationLink('javascript:void(0)'), isTrue);
      expect(isNavigationLink('tel:+1234567890'), isTrue);
      expect(isNavigationLink('data:image/png;base64,...'), isTrue);
      expect(isNavigationLink(''), isTrue);
    });

    test('returns false for regular hrefs', () {
      expect(isNavigationLink('movie.mkv'), isFalse);
      expect(isNavigationLink('subfolder/'), isFalse);
      expect(isNavigationLink('file.mp4'), isFalse);
    });
  });

  group('isDirectoryPath', () {
    test('returns true for paths ending with /', () {
      expect(isDirectoryPath('subfolder/'), isTrue);
      expect(isDirectoryPath('/movies/action/'), isTrue);
    });

    test('returns false for file paths', () {
      expect(isDirectoryPath('movie.mkv'), isFalse);
      expect(isDirectoryPath('/path/file.mp4'), isFalse);
    });
  });

  group('filenameFromUrl', () {
    test('extracts filename from URL', () {
      final url = Uri.parse('http://example.com/movies/file.mkv');
      expect(filenameFromUrl(url), 'file.mkv');
    });

    test('decodes URL-encoded filenames', () {
      final url = Uri.parse('http://example.com/My%20Movie.mkv');
      expect(filenameFromUrl(url), 'My Movie.mkv');
    });

    test('returns empty for root URL', () {
      final url = Uri.parse('http://example.com/');
      expect(filenameFromUrl(url), isEmpty);
    });
  });

  group('extensionFromFilename', () {
    test('extracts extension', () {
      expect(extensionFromFilename('file.mkv'), 'mkv');
      expect(extensionFromFilename('file.MP4'), 'mp4');
    });

    test('returns null for no extension', () {
      expect(extensionFromFilename('README'), isNull);
    });

    test('returns null for trailing dot', () {
      expect(extensionFromFilename('file.'), isNull);
    });

    test('gets last extension for multiple dots', () {
      expect(extensionFromFilename('file.name.srt'), 'srt');
    });
  });
}
