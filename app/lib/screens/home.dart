import 'package:candle/icons/compass.dart';
import 'package:candle/screens/compass.dart';
import 'package:candle/widgets/appbar.dart';

import 'package:candle/widgets/location_tile.dart';
import 'package:candle/widgets/tile_button.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CandleAppBar(
          title: Text(AppLocalizations.of(context)!.home_mainmenu),
          talkback: AppLocalizations.of(context)!.home_mainmenu_t,
        ),
        body: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const LocationAddressTile(),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                      crossAxisCount: 2, // Two columns
                      childAspectRatio: 1.0, // Aspect ratio of 1.0 (width == height)
                      crossAxisSpacing: 10, // Spacing in between items horizontally
                      mainAxisSpacing: 10, // Spacing in between items vertically
                      children: [
                        TileButton(
                          title: AppLocalizations.of(context)!.button_compass,
                          talkback: AppLocalizations.of(context)!.button_compass_t,
                          icon: const CompassSvgIcon(rotationDegrees: 30),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  CompassScreen(), // Replace with your new screen widget
                            ));
                          },
                        )
                      ]),
                )
              ],
            ),
          ),
        ));
  }
}
