import 'package:candle/icons/compass.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/buttonbar.dart';
import 'package:candle/widgets/location_tile.dart';
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
        bottomNavigationBar: const CandleButtonBar(),
        body: Padding(
          padding: EdgeInsets.all(18.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                LocationAddressTile(),
                SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                      crossAxisCount: 2, // Two columns
                      childAspectRatio: 1.0, // Aspect ratio of 1.0 (width == height)
                      crossAxisSpacing: 10, // Spacing in between items horizontally
                      mainAxisSpacing: 10, // Spacing in between items vertically
                      children: [
                        // Replace 10 with the number of buttons you have
                        ElevatedButton(
                          onPressed: () {
                            // Your action for this button
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate icon size (half the button's height)
                              double iconSize = constraints.maxHeight / 2;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CompassSvgIcon(
                          
                                    height: iconSize,
                                  ),
                                  SizedBox(height: 20),
                                  Text("Button"),
                                ],
                              );
                            },
                          ),
                        )
                      ]),
                )
              ],
            ),
          ),
        ));
  }
}
