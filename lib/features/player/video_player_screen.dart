import 'dart:async';
import 'dart:io' show Platform, SocketException;
import 'package:android_intent_plus/android_intent.dart';
import 'package:argus/core/providers/database_providers.dart';
import 'package:argus/core/utils/source_session_manager.dart';
import 'package:argus/data/database/app_database.dart';
import 'package:argus/features/player/widgets/challenge_solver_modal.dart';
import 'package:argus/features/player/widgets/player_bottom_bar.dart';
import 'package:argus/features/player/widgets/player_center_controls.dart';
import 'package:argus/features/player/widgets/player_top_bar.dart';
import 'package:argus/features/player/widgets/track_selector_sheet.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volume_controller/volume_controller.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String url;
  final String? title;
  final String? groupTitle;
  final int? season;
  final int? episode;
  final int? mediaItemId;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    this.title,
    this.groupTitle,
    this.season,
    this.episode,
    this.mediaItemId,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  late final AppDatabase _db;

  // progress persistence
  Timer? _progressSaveTimer;
  bool _hasResumed = false;

  // player state
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = true;
  bool _isBuffering = false;
  double _volume = 100.0;
  double _lastNonZeroVolume = 100.0;
  bool _isMuted = false;
  double _playbackRate = 1.0;
  double _previousRate = 1.0;
  bool _isHolding2x = false;
  bool _isFullscreen = false;

  // controls overlay state
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isSeeking = false;
  Duration _seekPosition = Duration.zero;

  // double tap seek feedback
  int _accumulatedSeekSeconds = 0;
  Timer? _doubleTapResetTimer;

  // volume swipe gesture & hud
  bool _isDraggingVolume = false;
  bool _isAdjustingVolume = false;
  Timer? _volumeHudResetTimer;

  // stream subs
  final List<StreamSubscription> _subscriptions = [];
  final FocusNode _focusNode = FocusNode();
  bool _isDisposed = false;
  bool _isClosing = false;
  bool _playerDisposed = false;

  @override
  void initState() {
    super.initState();
    _db = ref.read(databaseProvider);
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    if (!kIsWeb && Platform.isAndroid) {
      VolumeController.instance.showSystemUI = false;
      VolumeController.instance.getVolume().then((vol) {
        if (mounted) {
          setState(() {
            _volume = (vol * 100.0).clamp(0.0, 100.0);
            _isMuted = _volume == 0;
            if (_volume > 0) _lastNonZeroVolume = _volume;
          });
        }
      });
      VolumeController.instance.addListener((vol) {
        if (!mounted || _isDraggingVolume) return;
        setState(() {
          _volume = (vol * 100.0).clamp(0.0, 100.0);
          _isMuted = _volume == 0;
          if (_volume > 0) _lastNonZeroVolume = _volume;
        });
        _showVolumeHud();
      });
    }

    _player = Player();
    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    if (_player.platform is NativePlayer) {
      final nativePlayer = _player.platform as NativePlayer;
      nativePlayer.setProperty('sub-visibility', 'yes');
      nativePlayer.setProperty('sub-ass', 'yes');
      nativePlayer.setProperty('sub-ass-override', 'no');
      nativePlayer.setProperty('sub-auto', 'fuzzy');
    }

    _controller.waitUntilFirstFrameRendered.then((_) {
      if (mounted && _player.platform is NativePlayer) {
        (_player.platform as NativePlayer).setProperty('sub-visibility', 'yes');
      }
    });

    _subscriptions.addAll([
      _player.stream.position.listen((pos) {
        if (!mounted || _isSeeking) return;
        setState(() => _position = pos);
      }),
      _player.stream.duration.listen((dur) {
        if (!mounted) return;
        setState(() => _duration = dur);
      }),
      _player.stream.playing.listen((playing) {
        if (!mounted) return;
        setState(() => _isPlaying = playing);
        if (playing) {
          _resetHideTimer();
        } else {
          _showControls();
          _saveProgress();
        }
      }),
      _player.stream.buffering.listen((buffering) {
        if (!mounted) return;
        setState(() => _isBuffering = buffering);
      }),
      _player.stream.rate.listen((rate) {
        if (!mounted || _isHolding2x) return;
        setState(() => _playbackRate = rate);
      }),
      _player.stream.volume.listen((vol) {
        if (!mounted) return;
        setState(() {
          _volume = vol;
          _isMuted = vol == 0;
        });
      }),
      _player.stream.track.listen((track) {
        if (!mounted) return;
        if (_player.platform is NativePlayer) {
          (_player.platform as NativePlayer).setProperty(
            'sub-visibility',
            track.subtitle.id == 'no' ? 'no' : 'yes',
          );
        }
      }),
      _player.stream.error.listen((err) {
        if (!mounted || _isDisposed) return;
        _handlePlaybackError(err);
      }),
    ]);

    _initPlayerAndResume();
    _resetHideTimer();

    _progressSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _isPlaying && _position.inSeconds > 0) {
        _saveProgress();
      }
    });
  }

  bool _isHandlingChallenge = false;
  String? _resolvedPlayUrl;

  Future<void> _handleChallengeRequired() async {
    if (_isHandlingChallenge || !mounted || _isDisposed) return;
    _isHandlingChallenge = true;

    try {
      final result = await showChallengeSolverModal(
        context,
        url: widget.url,
        hostTitle: widget.groupTitle ?? widget.title,
      );

      if (result != null && mounted && !_isDisposed) {
        final playUrl = result.resolvedUrl.isNotEmpty
            ? result.resolvedUrl
            : widget.url;
        _resolvedPlayUrl = playUrl;
        final headers = await SourceSessionManager.getHeadersForUrl(playUrl);
        if (result.cookies.isNotEmpty) {
          headers['Cookie'] = result.cookies;
        }
        if (result.userAgent != null && result.userAgent!.isNotEmpty) {
          headers['User-Agent'] = result.userAgent!;
        }

        if (!mounted || _isDisposed) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification session captured. Loading stream...'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _openStream(playUrl, headers: headers);
      }
    } finally {
      _isHandlingChallenge = false;
    }
  }

  bool _isDiagnosingError = false;

  Future<void> _handlePlaybackError(String rawError) async {
    if (!mounted || _isDisposed || _isDiagnosingError) return;
    _isDiagnosingError = true;

    try {
      final info = await _diagnosePlaybackError(rawError);
      if (!mounted || _isDisposed) return;

      final theme = Theme.of(context);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          showCloseIcon: true,
          closeIconColor: theme.colorScheme.primary,
          content: Text(info.message),
          action: info.actionLabel != null && info.onAction != null
              ? SnackBarAction(
                  label: info.actionLabel!,
                  textColor: theme.colorScheme.primary,
                  onPressed: info.onAction!,
                )
              : null,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _isDiagnosingError = false;
    }
  }

  Future<_PlaybackErrorInfo> _diagnosePlaybackError(String rawError) async {
    final lower = rawError.toLowerCase();

    if (lower.contains('403') ||
        lower.contains('forbidden') ||
        lower.contains('503')) {
      unawaited(SourceSessionManager.clearSessionForUrl(widget.url));
      if (_resolvedPlayUrl != null) {
        unawaited(SourceSessionManager.clearSessionForUrl(_resolvedPlayUrl!));
      }
      return _PlaybackErrorInfo(
        type: _PlaybackErrorType.challenge,
        message:
            'Playback protected (403 / Cloudflare). Solve verification to continue.',
        actionLabel: 'Open in webview',
        onAction: _handleChallengeRequired,
      );
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return const _PlaybackErrorInfo(
        type: _PlaybackErrorType.notFound,
        message: 'Stream not found (404). This source link is dead or expired.',
      );
    }
    if (lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('connection refused') ||
        lower.contains('cannot resolve')) {
      return _PlaybackErrorInfo(
        type: _PlaybackErrorType.network,
        message: 'Network error: Unable to reach stream server.',
        actionLabel: 'Retry',
        onAction: _retryPlayback,
      );
    }
    if (lower.contains('demux') ||
        lower.contains('codec') ||
        lower.contains('format') ||
        lower.contains('unsupported')) {
      return _PlaybackErrorInfo(
        type: _PlaybackErrorType.format,
        message: 'Playback failed: Unsupported format or corrupted stream.',
        actionLabel: 'External Player',
        onAction: _openInExternalPlayer,
      );
    }

    // probe http status if the error is a generic
    final url = widget.url;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        final headers = await SourceSessionManager.getHeadersForUrl(url);
        final res = await _probeUrl(url, headers);

        if (res != null) {
          if (res.statusCode == 404 || res.statusCode == 410) {
            return const _PlaybackErrorInfo(
              type: _PlaybackErrorType.notFound,
              message:
                  'Stream not found (404). This source link is dead or expired.',
            );
          }
          if (res.statusCode == 403 || res.statusCode == 503) {
            return _PlaybackErrorInfo(
              type: _PlaybackErrorType.challenge,
              message:
                  'Playback protected (${res.statusCode} / Cloudflare). Solve verification to continue.',
              actionLabel: 'Open in webview',
              onAction: _handleChallengeRequired,
            );
          }
          final contentType = res.headers['content-type']?.toLowerCase() ?? '';
          if (contentType.contains('text/html')) {
            return _PlaybackErrorInfo(
              type: _PlaybackErrorType.challenge,
              message:
                  'Playback protected by verification. Solve verification to continue.',
              actionLabel: 'Open in webview',
              onAction: _handleChallengeRequired,
            );
          }
          if (res.statusCode >= 200 && res.statusCode < 300) {
            return _PlaybackErrorInfo(
              type: _PlaybackErrorType.format,
              message: 'Playback failed: Cannot decode stream format.',
              actionLabel: 'External Player',
              onAction: _openInExternalPlayer,
            );
          }
          if (res.statusCode >= 500) {
            return _PlaybackErrorInfo(
              type: _PlaybackErrorType.network,
              message:
                  'Server error (${res.statusCode}): Stream provider is unreachable.',
              actionLabel: 'Retry',
              onAction: _retryPlayback,
            );
          }
        }
      } on SocketException {
        return _PlaybackErrorInfo(
          type: _PlaybackErrorType.network,
          message: 'Network error: Cannot reach server. Check connection.',
          actionLabel: 'Retry',
          onAction: _retryPlayback,
        );
      } on TimeoutException {
        return _PlaybackErrorInfo(
          type: _PlaybackErrorType.network,
          message: 'Connection timed out while loading stream.',
          actionLabel: 'Retry',
          onAction: _retryPlayback,
        );
      } catch (e) {
        debugPrint('[VideoPlayer] Diagnostic probe error: $e');
      }
    }

    String cleanMsg = 'Playback error: Unable to load stream.';
    if (rawError.isNotEmpty &&
        !rawError.contains('http://') &&
        !rawError.contains('https://')) {
      cleanMsg = 'Playback error: $rawError';
    }

    return _PlaybackErrorInfo(
      type: _PlaybackErrorType.general,
      message: cleanMsg,
      actionLabel: 'Retry',
      onAction: _retryPlayback,
    );
  }

  Future<void> _openStream(
    String url, {
    Duration? startPosition,
    Map<String, String>? headers,
  }) async {
    if (!mounted || _isDisposed) return;
    final effectiveHeaders =
        headers ?? await SourceSessionManager.getHeadersForUrl(url);
    if (!mounted || _isDisposed) return;
    await _player.open(
      Media(
        url,
        start: startPosition ?? (_position > Duration.zero ? _position : null),
        httpHeaders: effectiveHeaders.isNotEmpty ? effectiveHeaders : null,
      ),
    );
  }

  Future<void> _retryPlayback() async {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await _openStream(widget.url);
  }

  Future<http.Response?> _probeUrl(
    String url,
    Map<String, String> headers,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final client = http.Client();
    try {
      try {
        return await client
            .head(uri, headers: headers)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        return await client
            .get(uri, headers: {...headers, 'Range': 'bytes=0-10'})
            .timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('[VideoPlayer] Probe request error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  Future<bool> _probeChallenge(String url, Map<String, String> headers) async {
    final res = await _probeUrl(url, headers);
    if (res == null) return false;
    if (res.statusCode == 403 || res.statusCode == 503) return true;
    final contentType = res.headers['content-type']?.toLowerCase() ?? '';
    return contentType.contains('text/html');
  }

  void _saveProgress() {
    final group = widget.groupTitle ?? widget.title;
    if (group == null || group.isEmpty) return;
    if (_duration.inMilliseconds <= 0) return;

    _db.savePlaybackProgress(
      groupTitle: group,
      mediaItemId: widget.mediaItemId,
      season: widget.season,
      episode: widget.episode,
      episodeTitle: widget.title,
      streamUrl: widget.url,
      positionMs: _position.inMilliseconds,
      durationMs: _duration.inMilliseconds,
    );
  }

  Future<void> _initPlayerAndResume() async {
    final group = widget.groupTitle ?? widget.title;
    Duration? startPosition;

    if (group != null && group.isNotEmpty && !_hasResumed) {
      final progress = await _db.getPlaybackProgress(
        group,
        season: widget.season,
        episode: widget.episode,
        streamUrl: widget.url,
      );

      if (progress != null &&
          !progress.isCompleted &&
          progress.positionMs > 5000) {
        _hasResumed = true;
        // rewind 5 seconds to provide context when resuming
        final resumeMs = (progress.positionMs - 5000).clamp(
          0,
          progress.positionMs,
        );
        startPosition = Duration(milliseconds: resumeMs);
      }
    }

    var playUrl = widget.url;
    var headers = await SourceSessionManager.getHeadersForUrl(playUrl);
    final challengeNeeded = await _probeChallenge(playUrl, headers);
    if (challengeNeeded && mounted && !_isDisposed) {
      final result = await showChallengeSolverModal(
        context,
        url: widget.url,
        hostTitle: widget.groupTitle ?? widget.title,
      );
      if (result != null) {
        if (result.resolvedUrl.isNotEmpty) {
          playUrl = result.resolvedUrl;
        }
        _resolvedPlayUrl = playUrl;
        headers = await SourceSessionManager.getHeadersForUrl(playUrl);
        if (result.cookies.isNotEmpty) {
          headers['Cookie'] = result.cookies;
        }
        if (result.userAgent != null && result.userAgent!.isNotEmpty) {
          headers['User-Agent'] = result.userAgent!;
        }
      }
    }

    if (!mounted || _isDisposed) return;
    await _openStream(playUrl, startPosition: startPosition, headers: headers);

    if (startPosition != null && mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Resumed from ${_formatProgressDuration(startPosition)}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatProgressDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(SourceSessionManager.clearSessionForUrl(widget.url));
    if (_resolvedPlayUrl != null && _resolvedPlayUrl != widget.url) {
      unawaited(SourceSessionManager.clearSessionForUrl(_resolvedPlayUrl!));
    }
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _progressSaveTimer?.cancel();
    _hideTimer?.cancel();
    _doubleTapResetTimer?.cancel();
    _volumeHudResetTimer?.cancel();
    _focusNode.dispose();
    if (!kIsWeb && Platform.isAndroid) {
      VolumeController.instance.removeListener();
      VolumeController.instance.showSystemUI = false;
    }
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (_isFullscreen) {
      defaultExitNativeFullscreen();
    }
    _saveProgress();
    if (!_playerDisposed) {
      _playerDisposed = true;
      unawaited(_player.dispose());
    }
    super.dispose();
  }

  void _showControls() {
    _hideTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    if (!_isHolding2x && !_isSeeking && _isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() => _controlsVisible = false);
        }
      });
    }
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _resetHideTimer();
    }
  }

  void _seekRelative(int seconds) {
    final target = _position + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(
        0,
        _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 0,
      ),
    );
    _player.seek(clamped);
    setState(() => _position = clamped);
    _resetHideTimer();
  }

  void _handleDoubleTap(TapDownDetails details, BoxConstraints constraints) {
    final isLeft = details.localPosition.dx < constraints.maxWidth / 2;
    final delta = isLeft ? -10 : 10;

    if ((isLeft && _accumulatedSeekSeconds > 0) ||
        (!isLeft && _accumulatedSeekSeconds < 0)) {
      _accumulatedSeekSeconds = delta;
    } else {
      _accumulatedSeekSeconds += delta;
    }

    _seekRelative(delta);

    setState(() {});
    _doubleTapResetTimer?.cancel();
    _doubleTapResetTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _accumulatedSeekSeconds = 0);
    });
  }

  void _startHolding2x() {
    if (!_isPlaying) return;
    _hideTimer?.cancel();
    _previousRate = _playbackRate;
    _player.setRate(2.0);
    setState(() {
      _isHolding2x = true;
    });
  }

  void _stopHolding2x() {
    if (!_isHolding2x) return;
    _player.setRate(_previousRate);
    setState(() {
      _isHolding2x = false;
    });
    _resetHideTimer();
  }

  void _showVolumeHud() {
    _volumeHudResetTimer?.cancel();
    if (!_isAdjustingVolume) {
      setState(() => _isAdjustingVolume = true);
    }
    _volumeHudResetTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isAdjustingVolume = false);
    });
  }

  void _handleVerticalDragStart(
    DragStartDetails details,
    BoxConstraints constraints,
  ) {
    final isRight = details.localPosition.dx > constraints.maxWidth * 0.5;
    final inVerticalZone =
        details.localPosition.dy > 40 &&
        details.localPosition.dy < (constraints.maxHeight - 40);

    if (isRight && inVerticalZone) {
      _isDraggingVolume = true;
      _showVolumeHud();
    } else {
      _isDraggingVolume = false;
    }
  }

  void _handleVerticalDragUpdate(
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) {
    if (!_isDraggingVolume) return;
    final delta = -details.delta.dy;
    final deltaVolume = (delta / (constraints.maxHeight * 0.5)) * 100;
    _setVolume((_volume + deltaVolume).clamp(0.0, 100.0), showControls: false);
    _showVolumeHud();
  }

  void _handleVerticalDragEnd() {
    if (!_isDraggingVolume) return;
    _isDraggingVolume = false;
    _showVolumeHud();
  }

  void _setVolume(double newVolume, {bool showControls = true}) {
    final clamped = newVolume.clamp(0.0, 100.0);
    if (!kIsWeb && Platform.isAndroid) {
      VolumeController.instance.setVolume(clamped / 100.0);
    } else {
      _player.setVolume(clamped);
    }
    setState(() {
      _volume = clamped;
      _isMuted = clamped == 0;
      if (clamped > 0) {
        _lastNonZeroVolume = clamped;
      }
    });
    if (showControls) {
      _resetHideTimer();
    }
  }

  void _toggleMute() {
    if (_isMuted) {
      _setVolume(_lastNonZeroVolume > 0 ? _lastNonZeroVolume : 100);
    } else {
      _setVolume(0);
    }
    _resetHideTimer();
  }

  Future<void> _openInExternalPlayer() async {
    _player.pause();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'action_view',
          data: widget.url,
          type: 'video/*',
        );
        await intent.launch();
      } else {
        final uri = Uri.parse(widget.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch URL';
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to open external player.')),
        );
      }
    }
  }

  Future<void> _closePlayer() async {
    if (_isClosing || !mounted) return;
    setState(() {
      _isClosing = true;
    });

    // detach video from the tree before destroying its native player
    await WidgetsBinding.instance.endOfFrame;
    if (!_playerDisposed) {
      _playerDisposed = true;
      await _player.dispose();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleFullscreen() async {
    final nextState = !_isFullscreen;
    setState(() {
      _isFullscreen = nextState;
    });
    if (nextState) {
      await defaultEnterNativeFullscreen();
    } else {
      await defaultExitNativeFullscreen();
    }
    _resetHideTimer();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyK:
        _player.playOrPause();
        _resetHideTimer();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _seekRelative(-5);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _seekRelative(5);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyJ:
        _seekRelative(-10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyL:
        _seekRelative(10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _setVolume(_volume + 5);
        _showVolumeHud();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _setVolume(_volume - 5);
        _showVolumeHud();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyM:
        _toggleMute();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyF:
        _toggleFullscreen();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.bracketLeft:
        final newRate = (_playbackRate - 0.25).clamp(0.25, 3.0);
        _player.setRate(newRate);
        _resetHideTimer();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.bracketRight:
        final newRate = (_playbackRate + 0.25).clamp(0.25, 3.0);
        _player.setRate(newRate);
        _resetHideTimer();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (_isFullscreen) {
          _toggleFullscreen();
        } else {
          _closePlayer();
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closePlayer();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (_, event) => _handleKeyEvent(event),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                onDoubleTapDown: (d) => _handleDoubleTap(d, constraints),
                onDoubleTap: () {},
                onLongPressStart: (_) => _startHolding2x(),
                onLongPressEnd: (_) => _stopHolding2x(),
                onVerticalDragStart: (details) =>
                    _handleVerticalDragStart(details, constraints),
                onVerticalDragUpdate: (details) =>
                    _handleVerticalDragUpdate(details, constraints),
                onVerticalDragEnd: (_) => _handleVerticalDragEnd(),
                onVerticalDragCancel: _handleVerticalDragEnd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      key: ValueKey(_isClosing),
                      child:
                          constraints.maxWidth > 0 &&
                              constraints.maxHeight > 0 &&
                              !_isClosing
                          ? Video(
                              controller: _controller,
                              fit: BoxFit.contain,
                              controls: NoVideoControls,
                              subtitleViewConfiguration:
                                  const SubtitleViewConfiguration(
                                    visible: false,
                                  ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    AnimatedOpacity(
                      opacity: _controlsVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_controlsVisible,
                        child: MouseRegion(
                          opaque: false,
                          onHover: (_) => _resetHideTimer(),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: PlayerTopBar(
                                  title: widget.title,
                                  onBack: _closePlayer,
                                  onAudio: () =>
                                      TrackSelectorSheet.showAudioSelector(
                                        context: context,
                                        player: _player,
                                        onClosed: _resetHideTimer,
                                      ),
                                  onSubtitles: () =>
                                      TrackSelectorSheet.showSubtitleSelector(
                                        context: context,
                                        player: _player,
                                        onClosed: _resetHideTimer,
                                      ),
                                  onSpeed: () =>
                                      TrackSelectorSheet.showSpeedSelector(
                                        context: context,
                                        currentRate: _playbackRate,
                                        onRateSelected: (rate) {
                                          _player.setRate(rate);
                                          _resetHideTimer();
                                        },
                                      ),
                                  onOpenExternal: _openInExternalPlayer,
                                  onSolveChallenge: _handleChallengeRequired,
                                  onMenuOpened: () => _hideTimer?.cancel(),
                                  onMenuClosed: _resetHideTimer,
                                ),
                              ),

                              PlayerCenterControls(
                                isPlaying: _isPlaying,
                                isBuffering: _isBuffering,
                                onPlayPause: () {
                                  _player.playOrPause();
                                  _resetHideTimer();
                                },
                                onReplay10: () => _seekRelative(-10),
                                onForward10: () => _seekRelative(10),
                              ),

                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: PlayerBottomBar(
                                  position: _position,
                                  duration: _duration,
                                  isSeeking: _isSeeking,
                                  seekPosition: _seekPosition,
                                  onSeekStart: (pos) {
                                    setState(() {
                                      _isSeeking = true;
                                      _seekPosition = pos;
                                    });
                                    _hideTimer?.cancel();
                                  },
                                  onSeekChanged: (pos) {
                                    setState(() => _seekPosition = pos);
                                  },
                                  onSeekEnd: (pos) {
                                    _player.seek(pos);
                                    setState(() {
                                      _position = pos;
                                      _isSeeking = false;
                                    });
                                    _resetHideTimer();
                                  },
                                  volume: _volume,
                                  isMuted: _isMuted,
                                  onVolumeChanged: _setVolume,
                                  onToggleMute: _toggleMute,
                                  playbackRate: _playbackRate,
                                  isFullscreen: _isFullscreen,
                                  onToggleFullscreen: _toggleFullscreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    IgnorePointer(
                      child: PlayerHud(
                        isHolding2x: _isHolding2x,
                        accumulatedSeekSeconds: _accumulatedSeekSeconds,
                        isBuffering: _isBuffering,
                        controlsVisible: _controlsVisible,
                        constraints: constraints,
                        isAdjustingVolume: _isAdjustingVolume,
                        volume: _volume,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _PlaybackErrorType { challenge, notFound, network, format, general }

class _PlaybackErrorInfo {
  final _PlaybackErrorType type;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PlaybackErrorInfo({
    required this.type,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
}
