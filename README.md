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

On iOS, `MoviePlayerWidget` uses `FlutterAVPlayerView` by default. Providing
`onPlaybackFinished` automatically selects media_kit instead. You can also set
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

On iOS, `MoviePlayerWidget` uses `FlutterAVPlayerView` by default. Set
`forceMediaKit: true` to use media_kit instead:

```dart
MoviePlayerWidget(
  path: videoPath,
  forceMediaKit: true,
  onPlaybackFinished: playNextItem,
)
```

Use `forceMediaKit` when the app needs media_kit features such as
`onPlaybackFinished` to advance e.g. a continuous sequence of movies and images;
`FlutterAVPlayerView` does not expose playback-finished control. On platforms
other than iOS, media_kit is already used, so `forceMediaKit` has no effect.
The parameter controls the playback backend, not widget layout or navigation.

## Playback lifecycle

The playback configuration (`path`, `forceMediaKit`, and callbacks) is read when
`MoviePlayerWidget` is mounted and is not updated while it remains mounted.
To play another movie or change the configuration, replace its state: remove
the current widget from the tree before adding it again, or give each playback
a distinct key so Flutter creates a new state and disposes the previous player.

If media_kit reports a playback error, the player shows an error message for
five seconds and then calls `onPlaybackFinished`, if provided. Disposing the
widget before the five seconds elapse cancels that callback.

`onPlaybackFinished` and `onDisposedPlayer` are only called when using the
media_kit player. On iOS, `FlutterAVPlayerView` is used unless
`forceMediaKit: true`; that native view does not expose playback-finished or
error callbacks.

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
