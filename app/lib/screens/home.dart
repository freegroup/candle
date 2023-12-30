import 'package:candle/icons/compass.dart';
import 'package:candle/icons/poi_favorite.dart';
import 'package:candle/models/location_address.dart';
import 'package:candle/screens/compass.dart';
import 'package:candle/screens/screens.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/dialogs.dart';
import 'package:candle/widgets/appbar.dart';

import 'package:candle/widgets/location_tile.dart';
import 'package:candle/widgets/tile_button.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

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
                          title: l10n.button_compass,
                          talkback: l10n.button_compass_t,
                          icon: const CompassIcon(rotationDegrees: 30),
                          onPressed: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const CompassScreen()));
                          },
                        ),
                        TileButton(
                          title: l10n.button_favorite,
                          talkback: l10n.button_favorite_t,
                          icon: const PoiFavoriteIcon(),
                          onPressed: () async {
                            showLoadingDialog(context);

                            try {
                              var coord = await LocationService.instance.location;
                              if (coord != null) {
                                var geo =
                                    Provider.of<GeoServiceProvider>(context, listen: false).service;
                                LocationAddress? address = await geo.getGeolocationAddress(coord);
                                if (!mounted) return;
                                Navigator.pop(context); // Close the loading dialog
                                if (mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => FavoriteCreateUpdateScreen(
                                        initialLocation: address,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                if (!mounted) return;
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (!mounted) return;
                              Navigator.pop(context);
                            }
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
