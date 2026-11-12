# movie_utils

A ready-to-use Flutter video player built on [media_kit](https://pub.dev/packages/media_kit),
with AirPlay support on iOS via [flutter_to_airplay](https://pub.dev/packages/flutter_to_airplay).

Key benefits:

- **AirPlay on iOS** through the native iOS player.
- **HLS / m3u8 playback that worked better in our testing** than using media_kit
  directly.
- **Ready-to-use playback controls and callbacks**, including an optional
  playback-finished notification.

`MoviePlayerWidget` displays video in the space provided by its parent widget.

On iOS, `MoviePlayerWidget` uses `FlutterAVPlayerView` by default for AirPlay support. 
Providing `onPlaybackFinished` automatically selects media_kit instead. You can also set
`forceMediaKit: true` to explicitly select media_kit on iOS.

Use `onPlaybackFinished` when your app needs to know that playback has ended,
for example, to advance to the next movie or image in a continuous sequence.

## Installation

Add `movie_utils` and `media_kit` to your app:

```shell
flutter pub add movie_utils media_kit
```

## Initialization

Import both packages and initialize media_kit before starting the app:

```dart
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:movie_utils/movie_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}
```

## Usage

`MoviePlayerWidget` fills the bounded space provided by its parent. In a
`Scaffold`, it uses the available body area:

```dart
Scaffold(
  body: MoviePlayerWidget(path: videoPath),
)
```

For inline playback in a smaller area, give it a bounded area, for example:

```dart
SizedBox(
  height: 240,
  child: MoviePlayerWidget(path: videoPath),
)
```

If placing it in a `Column`, use `Expanded` when the parent has a bounded
height. The media_kit renderer preserves the video's aspect ratio by default,
leaving any extra space around the video.

On iOS, `MoviePlayerWidget` uses `FlutterAVPlayerView` by default for AirPlay support. 
Set `forceMediaKit: true` to use media_kit instead:

```dart
MoviePlayerWidget(
  path: videoPath,
  forceMediaKit: true,
)
```

On platforms other than iOS, media_kit is already used, so `forceMediaKit` has no effect. 
The parameter controls the playback backend, not widget layout or navigation.

Use `onPlaybackFinished` to advance e.g. a continuous sequence of movies and images. 
This automatically selects media_kit - explicit `forceMediaKit: true` is not necessary.

```dart
MoviePlayerWidget(
  path: videoPath,
  onPlaybackFinished: playNextItem,
)
```

`FlutterAVPlayerView` does not expose playback-finished control.

## Playback lifecycle

The playback configuration (`path`, `forceMediaKit`, and callbacks) is read when
`MoviePlayerWidget` is mounted and is not updated while it remains mounted.

To play another movie or change the configuration, replace the widget's state.
**When using media_kit, player replacement must be coordinated with disposal of the previous player.** 
Creating a new player before the previous one has been fully disposed can cause exceptions. 
Use `onDisposedPlayer` to coordinate this replacement. It is called when the widget has disposed 
its media_kit player, allowing the application to wait for the disposal process before creating 
the next player.

```dart
String? _currentPath;
String? _message;
bool _playlistDone = false;

@override
void initState() {
  super.initState();
  _currentPath = getNextMoviePath();
  _playlistDone = _currentPath == null;
}

@override
Widget build(BuildContext context) {
  final String? path = _currentPath;
  final Widget body;
  if (_message != null) {
    body = Center(child: Text(_message!));
  } else if (_playlistDone || path == null) {
    body = const Center(child: Text('Done.'));
  } else {
    body = MoviePlayerWidget(
      key: ValueKey(path),
      path: path,
      onPlaybackFinished: onPlaybackFinished,
      onDisposedPlayer: onDisposedPlayer,
    );
  }
  return SafeArea(
    child: Scaffold(
      appBar: AppBar(title: const Text('Presentation')),
      body: body,
    ),
  );
}

String? getNextMoviePath() {
  String? path = ...; // Replace ... with your playlist logic.
  // It should return each playlist item in order and return null when there are no more items.
  return path;
}

void onPlaybackFinished() {
  if (!mounted) return;
  setState(() {
    _currentPath = null;
    _message = 'Please wait a second.';
  });
}

void onDisposedPlayer() {
  if (!mounted) return;
  final String? nextPath = getNextMoviePath();
  setState(() {
    _currentPath = nextPath;
    _playlistDone = nextPath == null;
    _message = null;
  });
}
```

We use this approach because the playlist may contain both movies and images. 
Although `media_kit` can switch to the next movie by changing the media loaded in the player, 
doing so would require checking what comes next and handling movie-to-movie transitions 
differently from movie-to-image transitions. Recreating the player after disposal keeps 
the mixed-media playlist logic simpler and avoids reconfiguring playback listeners, such as 
duration handling.

If media_kit reports a playback error, the player shows an error message for
five seconds and then calls `onPlaybackFinished`, if provided. Disposing the
widget before the five seconds elapse cancels that callback.

`onPlaybackFinished` and `onDisposedPlayer` are only called when using the
media_kit player.

## HLS / m3u8 playback experience

We encountered m3u8 playback issues when using media_kit directly; the setup
in this package resolved the issue in our app.\
Other users have reported a similar HLS issue in
[media_kit](https://github.com/media-kit/media-kit/issues/733), including a
black screen with audio. The discussion suggests trying playback without
hardware acceleration, but does not confirm a fix; we tried that workaround
as well, and it did not help in our case.\
The native iOS player is used for AirPlay support, not as the m3u8 workaround.
Our m3u8 result is based on our own testing, may not apply to other HLS issues
or streams, and does not guarantee playback of every m3u8 stream.
