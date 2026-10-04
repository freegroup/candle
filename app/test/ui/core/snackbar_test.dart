import 'package:candle/config/app_config.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BuildContext screen;

  // Home with a second screen on top; snack bars are shown from the second one.
  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (home) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(home).push(MaterialPageRoute<void>(
              builder: (context) {
                screen = context;
                return const Scaffold(body: Text('screen'));
              },
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> waitLongerThanDuration(WidgetTester tester) async {
    await tester.pump(SnackbarConfig.duration * 2);
    await tester.pumpAndSettle();
  }

  testWidgets('a sticky message stays, is replaced by the next and leaves with its screen',
      (tester) async {
    await openScreen(tester);

    showSnackbar(screen, 'Stairs', sticky: true);
    await tester.pumpAndSettle();
    await waitLongerThanDuration(tester);
    expect(find.text('Stairs'), findsOneWidget);

    showSnackbar(screen, 'Door', sticky: true);
    await tester.pumpAndSettle();
    expect(find.text('Stairs'), findsNothing);
    expect(find.text('Door'), findsOneWidget);

    Navigator.of(screen).pop();
    await tester.pumpAndSettle();
    expect(find.text('Door'), findsNothing);
  });

  testWidgets('with a screen reader a sticky message goes after its duration', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openScreen(tester);

    showSnackbar(screen, 'Stairs', sticky: true);
    await tester.pumpAndSettle();
    expect(find.text('Stairs'), findsOneWidget);

    await waitLongerThanDuration(tester);
    expect(find.text('Stairs'), findsNothing);
  });

  testWidgets('a normal message goes after its duration', (tester) async {
    await openScreen(tester);

    showSnackbar(screen, 'Saved');
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);

    await waitLongerThanDuration(tester);
    expect(find.text('Saved'), findsNothing);
  });
}
