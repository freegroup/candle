import 'dart:async';

import 'package:candle/ui/core/utils/semantic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Screen extends StatefulWidget {
  const _Screen();

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> with SemanticAnnouncer {
  @override
  Widget build(BuildContext context) => const Text('screen');
}

void main() {
  testWidgets('a screen is on top until another one covers it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Screen()));
    final screen = tester.state<_ScreenState>(find.byType(_Screen));
    expect(screen.isOnTop, isTrue);

    unawaited(Navigator.of(screen.context)
        .push(MaterialPageRoute<void>(builder: (_) => const Text('on top'))));
    await tester.pumpAndSettle();
    expect(screen.isOnTop, isFalse);

    Navigator.of(screen.context).pop();
    await tester.pumpAndSettle();
    expect(screen.isOnTop, isTrue);
  });
}
