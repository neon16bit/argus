// resolves a relative href against a base URL
Uri resolveUrl(Uri baseUrl, String href) {
  // decode HTML entities
  href = href.replaceAll('&amp;', '&');

  // handle already absolute URLs
  if (href.startsWith('http://') || href.startsWith('https://')) {
    return Uri.parse(href);
  }

  return baseUrl.resolve(href);
}

// returns true if href looks like a parent/navigation link that should be skipped during scraping
bool isNavigationLink(String href) {
  final lower = href.toLowerCase().trim();
  return lower.isEmpty ||
      lower == '../' ||
      lower == '..' ||
      lower == './' ||
      lower == '.' ||
      lower == '/' ||
      lower == '?' ||
      lower.startsWith('?') ||
      lower.startsWith('#') ||
      lower.startsWith('mailto:') ||
      lower.startsWith('javascript:') ||
      lower.startsWith('tel:') ||
      lower.startsWith('data:');
}

// returns true if the path looks like a directory listing (ends with /)
bool isDirectoryPath(String path) {
  return path.endsWith('/');
}

// Extracts the filename from a URL path, decoded
String filenameFromUrl(Uri url) {
  final segments = url.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return '';
  return Uri.decodeComponent(segments.last);
}

// Extracts the file extension from a filename (lowercase, no dot)
// returns null if no extension is found
String? extensionFromFilename(String filename) {
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == filename.length - 1) return null;
  return filename.substring(dotIndex + 1).toLowerCase();
}

bool isSameDomain(Uri baseUrl, Uri targetUrl) {
  // extract the hosts and force lowercase
  String baseHost = baseUrl.host.toLowerCase();
  String targetHost = targetUrl.host.toLowerCase();

  // strip 'www.' so 'www.example.com' and 'example.com' are treated as identical
  if (baseHost.startsWith('www.')) baseHost = baseHost.substring(4);
  if (targetHost.startsWith('www.')) targetHost = targetHost.substring(4);

  // strict match
  return baseHost == targetHost;
}

bool isSystemFile(String filename) {
  final lower = filename.toLowerCase().trim();

  // matches for useless system files/folders
  const exactMatches = {
    'thumbs.db', // windows thumbnail cache
    'desktop.ini', // windows folder customization
    '.ds_store', // macOS folder metadata
    '@eadir', // synology NAS indexing folders
    '\$recycle.bin', // windows trash
  };

  if (exactMatches.contains(lower)) return true;

  // Prefix matches for variable system files
  if (lower.startsWith('._')) return true; // macOS AppleDouble files
  if (lower.startsWith('.trash')) return true; // trash directories
  if (lower.startsWith('.spotlight-')) return true; // macOS Spotlight indexing
  if (lower.startsWith('.fseventsd')) return true; // macOS filesystem events

  return false;
}

// extracts the folder name from a file url
// if the immediate parent is a season folder, climbs to grandparent
String extractShowFolder(Uri baseUri, Uri fileUri) {
  final segments = fileUri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length < 2) return segments.lastOrNull ?? '';

  final parent = Uri.decodeComponent(segments[segments.length - 2]);

  // if parent looks like a season folder, use grandparent
  if (_isSeasonFolder(parent) && segments.length >= 3) {
    return Uri.decodeComponent(segments[segments.length - 3]);
  }
  return parent;
}

// loose match for season folders
// matches: "Season 1", "S01", "S1 1080p", "Season 2 BluRay", etc
bool _isSeasonFolder(String name) {
  return RegExp(
    r'^(Season\s*\d+|S\d{1,2})\b',
    caseSensitive: false,
  ).hasMatch(name);
}
