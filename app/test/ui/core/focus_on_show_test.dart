import 'package:candle/ui/core/widgets/focus_on_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('moves the screen reader focus to its child once, when shown', (tester) async {
    final semantics = tester.ensureSemantics();
    final focused = <int>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final map = message! as Map<Object?, Object?>;
        if (map['type'] == 'focus') focused.add(map['nodeId']! as int);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, null));

    await tester.pumpWidget(MaterialApp(
      home: Column(children: [
        const Text('before'),
        FocusOnShow(child: Semantics(header: true, child: const Text('Willkommen'))),
      ]),
    ));
    await tester.pump();
    final title = tester.semantics.find(find.bySemanticsLabel('Willkommen'));
    expect(focused, [title.id]);

    await tester.pump();
    expect(focused, hasLength(1));
    semantics.dispose();
  });
}
