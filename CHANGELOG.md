## 1.1.0

* Added `preferDesktopControls` to `MoviePlayerWidget` to force media_kit's
  desktop-style controls in keyboard-driven or focus-sensitive layouts.
  The desktop shortcut set keeps the standard seek/fullscreen controls while
  intentionally omitting Arrow Up/Down volume shortcuts so those keys remain
  available for Flutter focus navigation instead of triggering accidental volume
  changes.

## 1.0.0

* Initial release of `MoviePlayerWidget` with platform-specific video playback
  and optional playback-finished and player-disposed callbacks.
