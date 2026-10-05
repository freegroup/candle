import 'dart:async';

import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the screen reader reaches the title first, then back, then the actions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: CandleAppBar(
                title: const Text('Kompass'),
                talkback: 'Kompass Screen',
                actions: [IconButton(tooltip: 'Hilfe', icon: const Icon(Icons.help), onPressed: () {})],
              ),
              body: const Text('Inhalt'),
            ),
          ))),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final labels = [
      for (final node in tester.semantics.simulatedAccessibilityTraversal())
        if (node.label.isNotEmpty) node.label else if (node.tooltip.isNotEmpty) node.tooltip,
    ];
    expect(labels.take(3), ['Kompass Screen', 'Zurück', 'Hilfe']);
    semantics.dispose();
  });

  testWidgets('a new app bar moves the screen reader focus to its title', (tester) async {
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
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(appBar: CandleAppBar(title: Text('Orte'), talkback: 'Meine Orte')),
    ));
    await tester.pump();

    final title = tester.semantics.find(find.bySemanticsLabel('Meine Orte'));
    expect(focused, [title.id]);
    semantics.dispose();
  });
}
