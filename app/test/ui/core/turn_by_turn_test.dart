import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/widgets/turn_by_turn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the meters and the turn of the guidance', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TurnByTurnInstructionWidget(
          guidance: NavigationGuidance(
            event: NavigationEvent.update,
            hasWaypoint: true,
            distanceToWaypoint: 50,
            turnAngle: 90,
            isAligned: true,
          ),
        ),
      ),
    ));

    expect(find.text('50 Meter'), findsOneWidget);
    expect(find.text('Nach 50 Metern, links abbiegen.'), findsOneWidget);
  });
}
