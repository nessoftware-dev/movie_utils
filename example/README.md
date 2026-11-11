# movie_utils example

This app lets you choose the movie type and where playback appears:

- **Movie type**: choose MP4 or m3u8; the dropdown loads that type's preset URL.
- **Playback**: choose **New page** or **Embedded** independently of movie type.
- Edit the URL field to play a custom URL with the selected playback placement.

The embedded mode plays in the current page's player area. Its button changes
to **Stop** during playback. New page mode pushes a full-screen page. The
`forceMediaKit` parameter controls the iOS playback backend, not where the
player appears.

The movie type dropdown includes these preset URLs:

```text
https://www.nessoftware.de/Flutter/media_examples/movie.mp4
https://www.nessoftware.de/Flutter/media_examples/movie.m3u8
```

Changing the movie type resets the URL to that type's preset. The app calls
`MediaKit.ensureInitialized()` before `runApp`.
