import 'dart:async';

import 'package:candle/ui/shell/widgets/shared_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NavigatorState navigator;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        navigator = Navigator.of(context);
        return const Text('home');
      }),
    ));
  }

  testWidgets('a second shared content replaces the first; only one is on the stack',
      (tester) async {
    await pump(tester);

    showSharedContent(navigator, const Text('first'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);

    showSharedContent(navigator, const Text('second'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });

  testWidgets('a screen opened from the preview is cleared with it', (tester) async {
    await pump(tester);

    showSharedContent(navigator, const Text('preview'));
    await tester.pumpAndSettle();
    // the user chose an action, e.g. the target compass, still part of the flow
    unawaited(navigator.pushReplacement(sharedFlowRoute(const Text('compass'))));
    await tester.pumpAndSettle();
    expect(find.text('compass'), findsOneWidget);

    showSharedContent(navigator, const Text('new link'));
    await tester.pumpAndSettle();
    expect(find.text('compass'), findsNothing);
    expect(find.text('preview'), findsNothing);
    expect(find.text('new link'), findsOneWidget);
  });

  testWidgets('a plain screen on top of the preview is not cleared', (tester) async {
    await pump(tester);

    showSharedContent(navigator, const Text('preview'));
    await tester.pumpAndSettle();
    // the running map navigation is a normal route, not part of the flow
    unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => const Text('navigation'))));
    await tester.pumpAndSettle();

    showSharedContent(navigator, const Text('new link'));
    await tester.pumpAndSettle();
    expect(find.text('new link'), findsOneWidget);

    // the navigation was not cleared: it is still underneath the new preview
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('navigation'), findsOneWidget);
  });
}
