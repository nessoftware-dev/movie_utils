import 'package:flutter/material.dart';
import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows movie type and playback placement controls', (tester) async {
    await tester.pumpWidget(const MovieUtilsExampleApp());

    expect(find.text('New Window'), findsOneWidget);
    expect(find.text('Embedded'), findsOneWidget);
    expect(find.text('Movie type'), findsOneWidget);
    expect(find.text('https://www.nessoftware.de/Flutter/media_examples/movie.mp4'), findsOneWidget);
    expect(find.text('Choose a movie type and tap Play.'), findsOneWidget);
  });

  testWidgets('selecting a movie type loads its preset URL', (tester) async {
    await tester.pumpWidget(const MovieUtilsExampleApp());

    await tester.tap(find.byKey(const ValueKey('movie-type-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('m3u8').last);
    await tester.pumpAndSettle();

    final urlField = tester.widget<TextField>(find.byKey(const ValueKey('movie-url-field')));
    expect(urlField.controller!.text, 'https://www.nessoftware.de/Flutter/media_examples/movie.m3u8');
  });

  testWidgets('movie type and playback placement can be selected independently', (tester) async {
    await tester.pumpWidget(const MovieUtilsExampleApp());

    await tester.tap(find.text('Embedded'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('movie-type-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('m3u8').last);
    await tester.pumpAndSettle();

    expect(find.text('m3u8'), findsOneWidget);
    final urlField = tester.widget<TextField>(find.byKey(const ValueKey('movie-url-field')));
    expect(urlField.controller!.text, 'https://www.nessoftware.de/Flutter/media_examples/movie.m3u8');
  });

  testWidgets('can edit the selected movie URL', (tester) async {
    await tester.pumpWidget(const MovieUtilsExampleApp());
    await tester.enterText(find.byKey(const ValueKey('movie-url-field')), 'https://example.com/custom.mp4');

    final urlField = tester.widget<TextField>(find.byKey(const ValueKey('movie-url-field')));
    expect(urlField.controller!.text, 'https://example.com/custom.mp4');
  });
}
