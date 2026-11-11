import 'package:flutter_test/flutter_test.dart';
import 'package:movie_utils/movie_utils.dart';

void main() {
  test('retains the requested playback options', () {
    const screen = MoviePlayerScreen(path: 'movie.mp4', forceMediaKit: true);

    expect(screen.path, 'movie.mp4');
    expect(screen.forceMediaKit, isTrue);
  });
}
