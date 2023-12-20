import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/buttonbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CandleAppBar(
          title: Text(AppLocalizations.of(context)!.settings_mainmenu),
          talkback: AppLocalizations.of(context)!.settings_mainmenu_t,
        ),
        bottomNavigationBar: const CandleButtonBar(),
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
