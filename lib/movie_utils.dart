import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

// === CRITICAL: Movie Player Lifecycle Management ===
// The media_kit Player is extremely sensitive to overlapping instances.
// Problem: If two Player instances exist simultaneously or if a Player is
// created before the previous one is fully disposed, an exception occurs.
//
// Why MoviePlayerWidget.didUpdateWidget will not work:
// - didUpdateWidget() is called while the old State is still alive
// - Creating a new Player in didUpdateWidget() causes overlap with the old one
// - The old Player is still alive when the new Player is created, which will always throw an exception
//
// Why simply returning a new MoviePlayerWidget widget doesn't work:
// - Flutter may reuse the same State object if it thinks widgets are the same type
// - Even with ValueKey(path), Flutter might update the State in-place first
// - This causes the old player to outlive the new one during transition
//
// Solution: Force complete disposal before recreation which should be done via onDisposedPlayer.

/// A widget that displays a movie and manages media playback.
class MoviePlayerWidget extends StatefulWidget {
  /// The path or URL of the movie to play.
  final String path;

  /// Whether media_kit should be used instead of the platform player.
  final bool? forceMediaKit;

  /// Whether desktop controls should be preferred for playback.
  final bool? preferDesktopControls;

  /// Called when playback reaches the end of the movie.
  final VoidCallback? onPlaybackFinished;

  /// Called after the media player has been fully disposed.
  final VoidCallback? onDisposedPlayer;

  /// Creates a [MoviePlayerWidget].
  const MoviePlayerWidget({
    super.key,
    required this.path,
    this.forceMediaKit,
    this.preferDesktopControls,
    this.onPlaybackFinished,
    this.onDisposedPlayer,
  });

  @override
  State<MoviePlayerWidget> createState() => _MoviePlayerWidget();
}

class _MoviePlayerWidget extends State<MoviePlayerWidget> {
  late String path;
  late bool forceMediaKit;
  late bool preferDesktopControls;
  late VoidCallback? onPlaybackFinished;
  late VoidCallback? onDisposedPlayer;

  late bool _useMediaKit;
  Player? _player;
  VideoController? _controller;
  bool isReady = false;
  String? _movieError;
  bool _playbackFinishedNotified = false;

  _MoviePlayerWidget();

  @override
  void initState() {
    super.initState();
    path = widget.path;
    forceMediaKit = widget.forceMediaKit ?? false;
    preferDesktopControls = widget.preferDesktopControls ?? false;
    onPlaybackFinished = widget.onPlaybackFinished;
    onDisposedPlayer = widget.onDisposedPlayer;
    // Analyse whether media_kit should be used
    _useMediaKit = !Platform.isIOS || forceMediaKit || preferDesktopControls || (onPlaybackFinished != null);
    if (_useMediaKit) {
      _player = Player();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Add listeners
        _installErrorListener();
        _installDurationListener();
        if (onPlaybackFinished != null) {
          _installCompletionListener();
        }
        // Open the movie with no auto play
        await _player!.open(Media(path), play: false);
        if (!mounted) return;
        // Set the video controller and update widget
        setState(() {
          _controller = VideoController(_player!);
        });
      });
    }
  }

  @override
  void dispose() {
    if (_useMediaKit) {
      if (onDisposedPlayer == null) {
        _player?.dispose();
      } else {
        _player?.dispose().then((_) {
          onDisposedPlayer?.call();
        });
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SizedBox.expand(child: _moviePlayerView()),
    );
  }

  /// Clamps a seek position to the valid duration range
  Duration _clampSeekPosition(Duration position) {
    final maxDuration = _player?.state.duration ?? Duration.zero;
    if (position < Duration.zero) {
      return Duration.zero;
    }
    if (maxDuration > Duration.zero && position > maxDuration) {
      return maxDuration;
    }
    return position;
  }

  /// Return the required shortcuts for keyboard control without arrow up/down keys
  Map<ShortcutActivator, void Function()> _materialDesktopKeyboardShortcuts(
    BuildContext context,
  ) {
    return {
      // Keep the media_kit defaults for play/pause, seeking and fullscreen,
      // but intentionally omit the volume hotkeys to avoid accidental volume changes.
      SingleActivator(LogicalKeyboardKey.space): () => _player?.playOrPause(),
      SingleActivator(LogicalKeyboardKey.arrowLeft): () {
        final nextPosition = _clampSeekPosition(
          _player!.state.position - const Duration(seconds: 2),
        );
        _player!.seek(nextPosition);
      },
      SingleActivator(LogicalKeyboardKey.arrowRight): () {
        final nextPosition = _clampSeekPosition(
          _player!.state.position + const Duration(seconds: 2),
        );
        _player!.seek(nextPosition);
      },
      SingleActivator(LogicalKeyboardKey.keyJ): () {
        final nextPosition = _clampSeekPosition(
          _player!.state.position - const Duration(seconds: 10),
        );
        _player!.seek(nextPosition);
      },
      SingleActivator(LogicalKeyboardKey.keyI): () {
        final nextPosition = _clampSeekPosition(
          _player!.state.position + const Duration(seconds: 2),
        );
        _player!.seek(nextPosition);
      },
      SingleActivator(LogicalKeyboardKey.keyF): () => toggleFullscreen(context),
      SingleActivator(LogicalKeyboardKey.escape): () => exitFullscreen(context),
    };
  }

  Widget _moviePlayerView() {
    final String? movieError = _movieError;
    if (movieError != null) {
      return Center(
        child: Text(
          '${isReady ? 'Playback error' : 'Unable to open movie'}.\n$movieError',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    if (_useMediaKit && (_controller == null)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_useMediaKit) {
      // Return the video widget with controller and controls
      final Video video = Video(
        controller: _controller!,
        controls: (VideoState state) {
          if (!isReady) return const SizedBox.shrink();
          if (!preferDesktopControls) return AdaptiveVideoControls(state);
          return Builder(
            builder: (context) {
              final keyboardShortcuts = _materialDesktopKeyboardShortcuts(context);
              return MaterialDesktopVideoControlsTheme(
                normal: MaterialDesktopVideoControlsThemeData(
                  keyboardShortcuts: keyboardShortcuts,
                ),
                fullscreen: MaterialDesktopVideoControlsThemeData(
                  keyboardShortcuts: keyboardShortcuts,
                ),
                child: MaterialDesktopVideoControls(state),
              );
            },
          );
        },
      );
      return video;
    } else {
      // Return native iOS player widget with optional AirPlay support
      return FlutterAVPlayerView(urlString: path);
    }
  }

  /// Installs the error listener for error display (5 secs) and calling playback finished afterwards
  void _installErrorListener() {
    _player!.stream.error.listen((String error) {
      if (!mounted || _movieError != null) return;
      setState(() {
        _movieError = error;
      });
      if ((onPlaybackFinished != null) && !_playbackFinishedNotified) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _notifyPlaybackFinished();
          }
        });
      }
    });
  }

  /// Installs the duration listener for starting playback
  void _installDurationListener() {
    _player!.stream.duration.listen((Duration duration) {
      if (duration > Duration.zero) {
        if (!mounted || _movieError != null) return;
        if (!isReady) {
          _player!.play();
        }
        isReady = true;
        setState(() {});
      }
    });
  }

  /// Installs the completion listener for calling playback finished
  void _installCompletionListener() {
    _player!.stream.completed.listen((bool completed) {
      if (completed) {
        _notifyPlaybackFinished();
      }
    });
  }

  /// Notifies the caller that playback has finished
  void _notifyPlaybackFinished() {
    if (_playbackFinishedNotified) return;
    _playbackFinishedNotified = true;
    onPlaybackFinished?.call();
  }
}
