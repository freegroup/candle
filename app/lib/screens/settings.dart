import 'package:candle/widgets/appbar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: CandleAppBar(
          title: Text(l10n.screen_header_settings),
          talkback: l10n.screen_header_settings_t,
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text("To First"),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text("To Second"),
            )
          ]),
        ));
  }
}
