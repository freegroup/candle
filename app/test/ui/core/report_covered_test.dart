import 'dart:async';

import 'package:candle/ui/core/widgets/report_covered.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Target implements CoveredAware {
  final calls = <String>[];

  @override
  void onCovered() => calls.add('covered');

  @override
  void onUncovered() => calls.add('uncovered');
}

void main() {
  testWidgets('reports when a screen or dialog covers it and when it is on top again',
      (tester) async {
    final target = _Target();
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [candleRouteObserver],
      home: ReportCovered(target: target, child: const Text('below')),
    ));
    final context = tester.element(find.text('below'));

    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Text('on top'))));
    await tester.pumpAndSettle();
    expect(target.calls, ['covered']);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(target.calls, ['covered', 'uncovered']);

    unawaited(showDialog<void>(context: context, builder: (_) => const Text('dialog')));
    await tester.pumpAndSettle();
    expect(target.calls, ['covered', 'uncovered', 'covered']);
  });
}
