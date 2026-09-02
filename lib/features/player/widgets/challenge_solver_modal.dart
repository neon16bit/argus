import 'dart:io' show Platform;
import 'package:argus/core/utils/source_session_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChallengeResult {
  final String resolvedUrl;
  final String cookies;
  final String? userAgent;

  const ChallengeResult({
    required this.resolvedUrl,
    required this.cookies,
    this.userAgent,
  });
}

Future<ChallengeResult?> showChallengeSolverModal(
  BuildContext context, {
  required String url,
  String? hostTitle,
}) async {
  final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  if (!isMobile) {
    return _showDesktopChallengeDialog(context, url: url, hostTitle: hostTitle);
  }

  final result = await showModalBottomSheet<ChallengeResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: false,
    isDismissible: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _MobileWebViewChallengeSolver(url: url),
  );

  return result;
}

Future<ChallengeResult?> _showDesktopChallengeDialog(
  BuildContext context, {
  required String url,
  String? hostTitle,
}) async {
  final host = Uri.tryParse(url)?.host ?? url;
  final displayTitle = hostTitle ?? host;

  final openBrowser = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 24),
          SizedBox(width: 8),
          Text('Verification Required'),
        ],
      ),
      content: Text(
        'Playback from "$displayTitle" is blocked/limited by bot protection (Cloudflare / CAPTCHA).\n\n'
        'Open the link in your browser to stream directly.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.open_in_browser_rounded, size: 18),
          label: const Text('Open in Browser'),
        ),
      ],
    ),
  );

  if (openBrowser == true) {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  return null;
}

class _MobileWebViewChallengeSolver extends StatefulWidget {
  final String url;
  const _MobileWebViewChallengeSolver({required this.url});

  @override
  State<_MobileWebViewChallengeSolver> createState() =>
      _MobileWebViewChallengeSolverState();
}

class _MobileWebViewChallengeSolverState
    extends State<_MobileWebViewChallengeSolver> {
  static const String _prefKeyHideGuide = 'hide_challenge_guide';

  late final WebViewController _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
  String _pageTitle = 'Loading challenge...';
  bool _saving = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowInstructions();
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isLoading = true);
              _currentUrl = url;
            }
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            _currentUrl = url;
            final title = await _controller.getTitle();
            setState(() {
              _isLoading = false;
              if (title != null && title.isNotEmpty) {
                _pageTitle = title;
              }
            });
          },
          onNavigationRequest: (request) {
            _currentUrl = request.url;
            return NavigationDecision.navigate;
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _checkAndShowInstructions({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force) {
      final hide = prefs.getBool(_prefKeyHideGuide) ?? false;
      if (hide || !mounted) return;
    }
    if (!mounted) return;

    bool dontShowAgain = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'How to Solve',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Wait for the CAPTCHA or challenge to finish loading.\n\n'
                    '2. Complete the challenge on the webpage.\n\n'
                    '3. After solving, press the "Solved It" button above to start playback.',
                    style: TextStyle(fontSize: 14, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setDialogState(() {
                        dontShowAgain = !dontShowAgain;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: dontShowAgain,
                            onChanged: (val) {
                              setDialogState(() {
                                dontShowAgain = val ?? false;
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "Don't show again",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (dontShowAgain) {
      await prefs.setBool(_prefKeyHideGuide, true);
    }
  }

  Future<String> _extractCookies(String currentUrl) async {
    final uri = Uri.tryParse(currentUrl) ?? Uri.tryParse(widget.url);
    final cookiesSet = <String>{};

    if (uri != null) {
      try {
        final originUri = Uri(scheme: uri.scheme, host: uri.host);
        final cookieObjects = await _cookieManager.getCookies(
          domain: originUri,
        );
        for (final c in cookieObjects) {
          if (c.name.isNotEmpty) {
            cookiesSet.add('${c.name}=${c.value}');
          }
        }
      } catch (_) {}

      try {
        final cookieObjects = await _cookieManager.getCookies(domain: uri);
        for (final c in cookieObjects) {
          if (c.name.isNotEmpty) {
            cookiesSet.add('${c.name}=${c.value}');
          }
        }
      } catch (_) {}
    }

    try {
      final jsCookies = await _controller.runJavaScriptReturningResult(
        'document.cookie',
      );
      var cookieString = jsCookies.toString().trim();
      if (cookieString.startsWith('"') && cookieString.endsWith('"')) {
        cookieString = cookieString.substring(1, cookieString.length - 1);
      }
      cookieString = cookieString.replaceAll(r'\"', '"');
      if (cookieString.isNotEmpty &&
          cookieString != 'null' &&
          cookieString != '""') {
        for (final part in cookieString.split(';')) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty) {
            cookiesSet.add(trimmed);
          }
        }
      }
    } catch (_) {}

    return cookiesSet.join('; ');
  }

  Future<void> _applyAndClose() async {
    if (_saving || !mounted) return;
    setState(() => _saving = true);

    try {
      var liveUrl = (await _controller.currentUrl()) ?? _currentUrl;
      if (liveUrl.isEmpty) liveUrl = widget.url;

      var cookies = await _extractCookies(liveUrl);

      if (cookies.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 600));
        cookies = await _extractCookies(liveUrl);
      }

      String? userAgent;
      try {
        final uaResult = await _controller.runJavaScriptReturningResult(
          'navigator.userAgent',
        );
        userAgent = uaResult.toString().trim();
        if (userAgent.startsWith('"') && userAgent.endsWith('"')) {
          userAgent = userAgent.substring(1, userAgent.length - 1);
        }
      } catch (_) {}

      await SourceSessionManager.saveSessionForUrl(
        widget.url,
        cookies: cookies,
        userAgent: userAgent,
      );

      // save the live url host if different
      if (liveUrl != widget.url) {
        await SourceSessionManager.saveSessionForUrl(
          liveUrl,
          cookies: cookies,
          userAgent: userAgent,
        );
      }

      if (mounted) {
        Navigator.pop(
          context,
          ChallengeResult(
            resolvedUrl: liveUrl,
            cookies: cookies,
            userAgent: userAgent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context, null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Web Verification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _pageTitle,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            tooltip: 'How to use',
            onPressed: () => _checkAndShowInstructions(force: true),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reload page',
            onPressed: () => _controller.reload(),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: _saving ? null : _applyAndClose,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Solved It'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
