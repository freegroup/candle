import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/settings/widgets/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('the screen reader reads name and hint of each colour theme', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: buildSettingsScreen(),
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Gelb auf Schwarz. gut bei Lichtempfindlichkeit'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'\$')), findsNothing);

    // let the delayed screen announcement run out
    await tester.pump(const Duration(seconds: 5));
  });
}
