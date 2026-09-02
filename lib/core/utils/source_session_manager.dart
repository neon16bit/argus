import 'package:shared_preferences/shared_preferences.dart';

class SourceSessionManager {
  static const String _cookiePrefix = 'src_cookie_';
  static const String _userAgentPrefix = 'src_ua_';

  static final Map<String, String> _sessionCookies = {};
  static final Map<String, String> _sessionUserAgents = {};

  static String _extractHost(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.toLowerCase();
    } catch (_) {
      return url;
    }
  }

  // retrieves http headers
  static Future<Map<String, String>> getHeadersForUrl(String url) async {
    final host = _extractHost(url);
    if (host.isEmpty) return {};

    final cookie = _sessionCookies[host];
    final userAgent = _sessionUserAgents[host];

    final headers = <String, String>{};
    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }
    if (userAgent != null && userAgent.isNotEmpty) {
      headers['User-Agent'] = userAgent;
    }
    try {
      final uri = Uri.parse(url);
      headers['Referer'] = '${uri.scheme}://${uri.host}/';
      headers['Origin'] = '${uri.scheme}://${uri.host}';
    } catch (_) {}
    return headers;
  }

  // saves session cookies and user agent in mamory for the active playback
  static Future<void> saveSessionForUrl(
    String url, {
    required String cookies,
    String? userAgent,
  }) async {
    final host = _extractHost(url);
    if (host.isEmpty) return;

    if (cookies.isNotEmpty) {
      _sessionCookies[host] = cookies;
    }
    if (userAgent != null && userAgent.isNotEmpty) {
      _sessionUserAgents[host] = userAgent;
    }
  }

  // clears active session headers for the given url host
  static Future<void> clearSessionForUrl(String url) async {
    final host = _extractHost(url);
    if (host.isEmpty) return;

    _sessionCookies.remove(host);
    _sessionUserAgents.remove(host);

    // clean up any persisted entries in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cookiePrefix$host');
      await prefs.remove('$_userAgentPrefix$host');
    } catch (_) {}
  }
}
