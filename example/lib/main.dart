import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:movie_utils/movie_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MovieUtilsExampleApp());
}

class MovieUtilsExampleApp extends StatelessWidget {
  const MovieUtilsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Utils Example',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const PlaybackExamplePage(),
    );
  }
}

enum _MovieType { mp4, m3u8 }

class PlaybackExamplePage extends StatefulWidget {
  const PlaybackExamplePage({super.key});

  @override
  State<PlaybackExamplePage> createState() => _PlaybackExamplePageState();
}

class _PlaybackExamplePageState extends State<PlaybackExamplePage> {
  static const _defaultMp4Url = 'https://www.nessoftware.de/Flutter/media_examples/movie.mp4';
  static const _defaultM3u8Url = 'https://www.nessoftware.de/Flutter/media_examples/movie.m3u8';

  final _urlController = TextEditingController(text: _defaultMp4Url);
  _MovieType _movieType = _MovieType.mp4;
  bool _useEmbed = false;
  String? _playingUrl;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Utils Example')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlaybackOptions(),
              const SizedBox(height: 12),
              Expanded(child: _buildPlayerView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('New Window')),
            ButtonSegment(value: true, label: Text('Embedded')),
          ],
          selected: {_useEmbed},
          onSelectionChanged: (selection) {
            setState(() {
              _useEmbed = selection.first;
              if (!_useEmbed) {
                _playingUrl = null;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        Text('New Window shows the movie in a new screen without using onPlaybackFinished.'),
        Text('Embedded displays the movie below with using onPlaybackFinished.'),
        const SizedBox(height: 20),
        DropdownButtonFormField<_MovieType>(
          key: const ValueKey('movie-type-dropdown'),
          initialValue: _movieType,
          decoration: const InputDecoration(labelText: 'Movie type', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: _MovieType.mp4, child: Text('MP4')),
            DropdownMenuItem(value: _MovieType.m3u8, child: Text('m3u8')),
          ],
          onChanged: _selectMovieType,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('movie-url-field'),
          controller: _urlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Movie URL',
            border: OutlineInputBorder(),
            helperText: 'The movie type selects a preset URL. You can edit it.',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _useEmbed && _playingUrl != null ? _stopMovie : _playMovie,
          child: Text(_useEmbed && _playingUrl != null ? 'Stop' : 'Play'),
        ),
      ],
    );
  }

  Widget _buildPlayerView() {
    final playingUrl = _playingUrl;
    return ColoredBox(
      color: Colors.black,
      child: playingUrl != null
          ? MoviePlayerWidget(
              path: playingUrl,
              forceMediaKit: _useEmbed,
              onPlaybackFinished: () => _onPlaybackFinished(stopEmbedded: true),
            )
          : const Center(child: Text('Choose a movie type and tap Play.')),
    );
  }

  void _onPlaybackFinished({bool stopEmbedded = false}) {
    if (!mounted) return;
    if (stopEmbedded) {
      _stopMovie();
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playback finished.')));
  }

  void _selectMovieType(_MovieType? movieType) {
    if (movieType == null) return;
    setState(() {
      _movieType = movieType;
      _urlController.text = movieType == _MovieType.mp4 ? _defaultMp4Url : _defaultM3u8Url;
    });
  }

  void _playMovie() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!_useEmbed) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _MoviePlaybackPage(path: url),
        ),
      );
      return;
    }
    setState(() {
      _playingUrl = url;
    });
  }

  void _stopMovie() {
    setState(() {
      _playingUrl = null;
    });
  }
}

class _MoviePlaybackPage extends StatelessWidget {
  final String path;

  const _MoviePlaybackPage({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Playback')),
      body: MoviePlayerWidget(path: path),
    );
  }
}
