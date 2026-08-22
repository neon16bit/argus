import 'dart:async';
import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:argus/features/player/widgets/player_bottom_bar.dart';
import 'package:argus/features/player/widgets/player_center_controls.dart';
import 'package:argus/features/player/widgets/player_top_bar.dart';
import 'package:argus/features/player/widgets/track_selector_sheet.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String? title;

  const VideoPlayerScreen({super.key, required this.url, this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  // player state
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = true;
  bool _isBuffering = false;
  double _volume = 100.0;
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

  // stream subs
  final List<StreamSubscription> _subscriptions = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
        if (mounted && !_isSeeking) {
          setState(() => _position = pos);
        }
      }),
      _player.stream.duration.listen((dur) {
        if (mounted) setState(() => _duration = dur);
      }),
      _player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
          if (playing) {
            _resetHideTimer();
          } else {
            _showControls();
          }
        }
      }),
      _player.stream.buffering.listen((buffering) {
        if (mounted) setState(() => _isBuffering = buffering);
      }),
      _player.stream.rate.listen((rate) {
        if (mounted && !_isHolding2x) {
          setState(() => _playbackRate = rate);
        }
      }),
      _player.stream.volume.listen((vol) {
        if (mounted) {
          setState(() {
            _volume = vol;
            _isMuted = vol == 0;
          });
        }
      }),
      _player.stream.track.listen((track) {
        if (mounted && _player.platform is NativePlayer) {
          (_player.platform as NativePlayer).setProperty(
            'sub-visibility',
            track.subtitle.id == 'no' ? 'no' : 'yes',
          );
        }
      }),
    ]);

    _player.open(Media(widget.url));
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _doubleTapResetTimer?.cancel();
    _focusNode.dispose();
    for (final s in _subscriptions) {
      s.cancel();
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
    _player.dispose();
    if (_isFullscreen) {
      defaultExitNativeFullscreen();
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

  void _setVolume(double newVolume) {
    final clamped = newVolume.clamp(0.0, 100.0);
    _player.setVolume(clamped);
    setState(() {
      _volume = clamped;
      _isMuted = clamped == 0;
    });
    _resetHideTimer();
  }

  void _toggleMute() {
    if (_isMuted) {
      _setVolume(_volume > 0 ? _volume : 100);
    } else {
      _player.setVolume(0);
      setState(() => _isMuted = true);
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

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyK:
        _player.playOrPause();
        _resetHideTimer();
        break;
      case LogicalKeyboardKey.arrowLeft:
        _seekRelative(-5);
        break;
      case LogicalKeyboardKey.arrowRight:
        _seekRelative(5);
        break;
      case LogicalKeyboardKey.keyJ:
        _seekRelative(-10);
        break;
      case LogicalKeyboardKey.keyL:
        _seekRelative(10);
        break;
      case LogicalKeyboardKey.arrowUp:
        _setVolume(_volume + 5);
        break;
      case LogicalKeyboardKey.arrowDown:
        _setVolume(_volume - 5);
        break;
      case LogicalKeyboardKey.keyM:
        _toggleMute();
        break;
      case LogicalKeyboardKey.keyF:
        _toggleFullscreen();
        break;
      case LogicalKeyboardKey.bracketLeft:
        final newRate = (_playbackRate - 0.25).clamp(0.25, 3.0);
        _player.setRate(newRate);
        _resetHideTimer();
        break;
      case LogicalKeyboardKey.bracketRight:
        final newRate = (_playbackRate + 0.25).clamp(0.25, 3.0);
        _player.setRate(newRate);
        _resetHideTimer();
        break;
      case LogicalKeyboardKey.escape:
        if (_isFullscreen) {
          _toggleFullscreen();
        } else {
          Navigator.of(context).maybePop();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (_, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onDoubleTapDown: (d) => _handleDoubleTap(d, constraints),
              onDoubleTap: () {},
              onLongPressStart: (_) => _startHolding2x(),
              onLongPressEnd: (_) => _stopHolding2x(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Video(
                      controller: _controller,
                      fit: BoxFit.contain,
                      controls: NoVideoControls,
                      subtitleViewConfiguration:
                          const SubtitleViewConfiguration(visible: false),
                    ),
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
                                onBack: () => Navigator.of(context).maybePop(),
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
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
