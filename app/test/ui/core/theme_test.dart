import 'package:candle/ui/core/themes/candle_theme.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every profile builds and uses its own background', () {
    for (final profile in candleThemes) {
      expect(CThemeData.theme(profile).scaffoldBackgroundColor, profile.bg, reason: profile.id);
    }
  });

  test('darkTheme is the first (default) profile', () {
    expect(CThemeData.darkTheme.scaffoldBackgroundColor, candleThemes.first.bg);
  });

  testWidgets('changing the profile recolours the app live', (tester) async {
    final id = ValueNotifier<String>('amber_dark');
    addTearDown(id.dispose);
    await tester.pumpWidget(ValueListenableBuilder<String>(
      valueListenable: id,
      builder: (_, value, _) => MaterialApp(
        theme: CThemeData.theme(candleThemes.firstWhere((t) => t.id == value)),
        home: Builder(
          builder: (context) =>
              ColoredBox(key: const Key('probe'), color: Theme.of(context).scaffoldBackgroundColor),
        ),
      ),
    ));
    BuildContext ctx() => tester.element(find.byKey(const Key('probe')));
    expect(Theme.of(ctx()).scaffoldBackgroundColor, const Color(0xFF000000));

    id.value = 'black_light';
    await tester.pumpAndSettle(); // MaterialApp animates the theme change

    expect(Theme.of(ctx()).scaffoldBackgroundColor, const Color(0xFFFFFFFF));
  });
}
