import 'dart:io';
import 'package:flutter/material.dart';
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

class MoviePlayerWidget extends StatefulWidget {
  final String path;
  final bool? forceMediaKit;
  final VoidCallback? onPlaybackFinished;
  final VoidCallback? onDisposedPlayer;

  const MoviePlayerWidget({
    super.key,
    required this.path,
    this.forceMediaKit,
    this.onPlaybackFinished,
    this.onDisposedPlayer,
  });

  @override
  State<MoviePlayerWidget> createState() => _MoviePlayerWidget();
}

class _MoviePlayerWidget extends State<MoviePlayerWidget> {
  late String path;
  late bool forceMediaKit;
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
    onPlaybackFinished = widget.onPlaybackFinished;
    onDisposedPlayer = widget.onDisposedPlayer;
    _useMediaKit = !Platform.isIOS || forceMediaKit || (onPlaybackFinished != null);
    if (_useMediaKit) {
      _player = Player();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _installErrorListener();
        _installDurationListener();
        if (onPlaybackFinished != null) {
          _installCompletionListener();
        }
        await _player!.open(Media(path), play: false);
        if (!mounted) return;
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
      return Video(
        controller: _controller!,
        controls: (VideoState state) {
          if (isReady) {
            return AdaptiveVideoControls(state);
          } else {
            return const SizedBox.shrink();
          }
        },
      );
    } else {
      return FlutterAVPlayerView(urlString: path);
    }
  }

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

  void _installDurationListener() {
    _player!.stream.duration.listen((Duration duration) {
      if (duration > Duration.zero) {
        if (!isReady) {
          _player!.play();
        }
        isReady = true;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _installCompletionListener() {
    _player!.stream.completed.listen((bool completed) {
      if (completed) {
        _notifyPlaybackFinished();
      }
    });
  }

  void _notifyPlaybackFinished() {
    if (_playbackFinishedNotified) return;
    _playbackFinishedNotified = true;
    onPlaybackFinished?.call();
  }
}
