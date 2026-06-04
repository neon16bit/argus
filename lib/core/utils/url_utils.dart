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
