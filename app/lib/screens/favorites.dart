import 'package:candle/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CandleAppBar(
          title: Text(AppLocalizations.of(context)!.favorite_mainmenu),
          talkback: AppLocalizations.of(context)!.favorite_mainmenu_t,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("User Name:"),
              ElevatedButton(
                onPressed: () {},
                child: const Text("To First"),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text("To Third"),
              )
            ],
          ),
        ));
  }
}
