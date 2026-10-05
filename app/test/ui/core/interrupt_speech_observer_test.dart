import 'dart:async';

import 'package:candle/ui/core/utils/interrupt_speech_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stops the screen reader when a screen or dialog opens, closes or is replaced',
      (tester) async {
    var interruptions = 0;
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [InterruptSpeechObserver(() async => interruptions++)],
      home: const Text('home'),
    ));
    final navigator = Navigator.of(tester.element(find.text('home')));
    final start = interruptions;

    unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => const Text('screen'))));
    await tester.pumpAndSettle();
    expect(interruptions, start + 1);

    unawaited(navigator.pushReplacement(MaterialPageRoute<void>(builder: (_) => const Text('other'))));
    await tester.pumpAndSettle();
    expect(interruptions, start + 2);

    navigator.pop();
    await tester.pumpAndSettle();
    expect(interruptions, start + 3);

    unawaited(showDialog<void>(context: tester.element(find.text('home')), builder: (_) => const Text('dialog')));
    await tester.pumpAndSettle();
    expect(interruptions, start + 4);
  });
}
