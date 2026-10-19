import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/data/remote/metadata/simkl_provider.dart';

const _kSimklAccessToken = 'simkl_access_token';
const _kSimklRefreshToken = 'simkl_refresh_token';
const _kSimklExpiresAt = 'simkl_expires_at';
const _kSimklUserName = 'simkl_user_name';
const _kSimklUserAvatar = 'simkl_user_avatar';
const _kSimklUserId = 'simkl_user_id';
const _kSimklAutoSync = 'simkl_auto_sync';

class SimklUser {
  final int? id;
  final String name;
  final String? avatarHash;
  final String? avatarUrl;

  const SimklUser({
    this.id,
    required this.name,
    this.avatarHash,
    this.avatarUrl,
  });

  factory SimklUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final avatar = user['avatar'] as String?;
    final ids = user['ids'] as Map<String, dynamic>? ?? {};

    String? resolvedAvatarUrl;
    if (avatar != null && avatar.trim().isNotEmpty) {
      final clean = avatar.trim();
      if (clean.startsWith('http://') || clean.startsWith('https://')) {
        resolvedAvatarUrl = clean;
      } else {
        resolvedAvatarUrl =
            'https://wsrv.nl/?url=https://simkl.in/avatars/${clean}_w.jpg&q=90';
      }
    }

    return SimklUser(
      id: (ids['simkl'] as num?)?.toInt(),
      name: user['name'] as String? ?? 'Simkl User',
      avatarHash: avatar,
      avatarUrl: resolvedAvatarUrl,
    );
  }
}

class SimklAccountState {
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final SimklUser? user;
  final bool autoSync;
  final bool isConnecting;
  final String? errorMessage;

  const SimklAccountState({
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.user,
    this.autoSync = true,
    this.isConnecting = false,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      (expiresAt == null || DateTime.now().isBefore(expiresAt!));

  SimklAccountState copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    SimklUser? user,
    bool? autoSync,
    bool? isConnecting,
    String? errorMessage,
    bool clearTokens = false,
  }) {
    return SimklAccountState(
      accessToken: clearTokens ? null : (accessToken ?? this.accessToken),
      refreshToken: clearTokens ? null : (refreshToken ?? this.refreshToken),
      expiresAt: clearTokens ? null : (expiresAt ?? this.expiresAt),
      user: clearTokens ? null : (user ?? this.user),
      autoSync: autoSync ?? this.autoSync,
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: errorMessage,
    );
  }
}

class SimklAuthNotifier extends Notifier<SimklAccountState> {
  @override
  SimklAccountState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _loadFromPrefs(prefs);
  }

  static SimklAccountState _loadFromPrefs(SharedPreferences prefs) {
    final token = prefs.getString(_kSimklAccessToken);
    final refresh = prefs.getString(_kSimklRefreshToken);
    final expiresMillis = prefs.getInt(_kSimklExpiresAt);
    final userName = prefs.getString(_kSimklUserName);
    var userAvatar = prefs.getString(_kSimklUserAvatar);
    if (userAvatar != null && userAvatar.contains('simkl.in/avatars/http')) {
      final sub = userAvatar.substring(
        userAvatar.indexOf('simkl.in/avatars/') + 'simkl.in/avatars/'.length,
      );
      final innerMatch = RegExp(
        r'https?://[^\s&_]+(?:\.png|\.jpg|\.jpeg|\.webp)',
      ).firstMatch(sub);
      if (innerMatch != null) {
        userAvatar = innerMatch.group(0);
        if (userAvatar != null) {
          prefs.setString(_kSimklUserAvatar, userAvatar);
        }
      }
    }
    final userId = prefs.getInt(_kSimklUserId);
    final autoSync = prefs.getBool(_kSimklAutoSync) ?? true;

    SimklUser? user;
    if (userName != null) {
      user = SimklUser(id: userId, name: userName, avatarUrl: userAvatar);
    }

    return SimklAccountState(
      accessToken: token,
      refreshToken: refresh,
      expiresAt: expiresMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(expiresMillis)
          : null,
      user: user,
      autoSync: autoSync,
    );
  }

  static String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  SimklAccountState get currentState => state;

  static String _generateCodeChallenge(String verifier) {
    final bytes = ascii.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<bool> login() async {
    final clientId = SimklProvider.clientId;
    if (clientId.isEmpty) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'SIMKL_CLIENT_ID is not configured.',
      );
      return false;
    }

    state = state.copyWith(isConnecting: true, errorMessage: null);

    HttpServer? server;
    try {
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // local loopback server on available port
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://localhost:$port/argus/auth/simkl';

      final authUrl = Uri.https('simkl.com', '/oauth2/authorize', {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'scope': 'media:write',
      });

      debugPrint('[SimklAuth] Opening browser: $authUrl');
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);

      // wait for redirect
      String? authCode;
      String? authError;

      await for (final request in server.timeout(const Duration(minutes: 3))) {
        if (request.uri.path == '/argus/auth/simkl') {
          authCode = request.uri.queryParameters['code'];
          authError = request.uri.queryParameters['error'];

          request.response.headers.contentType = ContentType.html;
          if (authCode != null) {
            request.response.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Argus - Connected to Simkl</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #1e1e2e;
      color: #cdd6f4;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
    }
    .box {
      background: #181825;
      padding: 36px 48px;
      border-radius: 16px;
      border: 1px solid #313244;
      text-align: center;
      box-shadow: 0 12px 36px rgba(0,0,0,0.5);
    }
    h2 { color: #a6e3a1; margin: 0 0 12px 0; }
    p { color: #a6adc8; margin: 0; font-size: 16px; }
  </style>
</head>
<body>
  <div class="box">
    <h2>✓ Connected to Simkl</h2>
    <p>You can close this window and return to Argus.</p>
  </div>
</body>
</html>
''');
          } else {
            request.response.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Argus - Sign-in Failed</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #1e1e2e;
      color: #cdd6f4;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
    }
    .box {
      background: #181825;
      padding: 36px 48px;
      border-radius: 16px;
      border: 1px solid #313244;
      text-align: center;
    }
    h2 { color: #f38ba8; margin: 0 0 12px 0; }
    p { color: #a6adc8; margin: 0; }
  </style>
</head>
<body>
  <div class="box">
    <h2>Authorization Denied</h2>
    <p>${authError ?? 'The sign-in request was rejected or failed.'}</p>
  </div>
</body>
</html>
''');
          }
          await request.response.close();
          break;
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      }

      await server.close(force: true);
      server = null;

      if (authCode == null) {
        throw Exception(authError ?? 'Authorization was not completed.');
      }

      // exchange code for token
      debugPrint('[SimklAuth] Exchanging code for token...');
      final tokenResponse = await http.post(
        Uri.parse('https://api.simkl.com/oauth2/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': authCode,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        }),
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception(
          'Failed to exchange token: ${tokenResponse.statusCode} ${tokenResponse.body}',
        );
      }

      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = tokenData['access_token'] as String;
      final refreshToken = tokenData['refresh_token'] as String;
      final expiresIn = (tokenData['expires_in'] as num?)?.toInt() ?? 604800;
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      // fetch user profile
      debugPrint('[SimklAuth] Fetching user profile...');
      SimklUser? user;
      try {
        final userResponse = await http.get(
          Uri.parse('https://api.simkl.com/users/settings'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'simkl-api-key': clientId,
            'Content-Type': 'application/json',
          },
        );
        if (userResponse.statusCode == 200) {
          final userData =
              jsonDecode(userResponse.body) as Map<String, dynamic>;
          user = SimklUser.fromJson(userData);
          debugPrint('[SimklAuth] Logged in as: ${user.name}');
        }
      } catch (e) {
        debugPrint('[SimklAuth] Warning: Could not fetch user settings: $e');
      }

      // save to SharedPreferences
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_kSimklAccessToken, accessToken);
      await prefs.setString(_kSimklRefreshToken, refreshToken);
      await prefs.setInt(_kSimklExpiresAt, expiresAt.millisecondsSinceEpoch);
      if (user != null) {
        await prefs.setString(_kSimklUserName, user.name);
        if (user.avatarUrl != null) {
          await prefs.setString(_kSimklUserAvatar, user.avatarUrl!);
        }
        if (user.id != null) {
          await prefs.setInt(_kSimklUserId, user.id!);
        }
      }

      state = state.copyWith(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        user: user ?? const SimklUser(name: 'Simkl User'),
        isConnecting: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      debugPrint('[SimklAuth] Login error: $e');
      state = state.copyWith(
        isConnecting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    } finally {
      if (server != null) {
        await server.close(force: true);
      }
    }
  }

  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kSimklAccessToken);
    await prefs.remove(_kSimklRefreshToken);
    await prefs.remove(_kSimklExpiresAt);
    await prefs.remove(_kSimklUserName);
    await prefs.remove(_kSimklUserAvatar);
    await prefs.remove(_kSimklUserId);

    state = state.copyWith(clearTokens: true, errorMessage: null);
  }

  Future<void> setAutoSync(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kSimklAutoSync, enabled);
    state = state.copyWith(autoSync: enabled);
  }

  Future<String?> getValidAccessToken() async {
    final token = state.accessToken;
    if (token == null) return null;

    final isNearExpiry =
        state.expiresAt == null ||
        DateTime.now().isAfter(
          state.expiresAt!.subtract(const Duration(hours: 2)),
        );

    if (!isNearExpiry) {
      return token;
    }

    final refreshToken = state.refreshToken;
    if (refreshToken == null) return token;

    final clientId = SimklProvider.clientId;
    if (clientId.isEmpty) return token;

    try {
      debugPrint('[SimklAuth] Refreshing access token...');
      final response = await http.post(
        Uri.parse('https://api.simkl.com/oauth2/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'client_id': clientId,
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken =
            (data['refresh_token'] as String?) ?? refreshToken;
        final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 604800;
        final newExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString(_kSimklAccessToken, newAccessToken);
        await prefs.setString(_kSimklRefreshToken, newRefreshToken);
        await prefs.setInt(
          _kSimklExpiresAt,
          newExpiresAt.millisecondsSinceEpoch,
        );

        state = state.copyWith(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          expiresAt: newExpiresAt,
        );
        return newAccessToken;
      } else {
        debugPrint('[SimklAuth] Failed to refresh token: ${response.body}');
        return token;
      }
    } catch (e) {
      debugPrint('[SimklAuth] Error refreshing token: $e');
      return token;
    }
  }
}
