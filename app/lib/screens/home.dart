import 'dart:convert';

import 'package:candle/icons/compass.dart';
import 'package:candle/icons/poi_favorite.dart';
import 'package:candle/models/location_address.dart';
import 'package:candle/screens/about.dart';
import 'package:candle/screens/compass.dart';
import 'package:candle/screens/poi_radar.dart';
import 'package:candle/screens/recorder_controller.dart';
import 'package:candle/screens/screens.dart';
import 'package:candle/screens/wikipedia.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/dialogs.dart';
import 'package:candle/utils/featureflag.dart';
import 'package:candle/utils/files.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/location_tile.dart';
import 'package:candle/widgets/tile_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _ScreenState();
}

class _ScreenState extends State<HomeScreen> {
  bool isRecordingServiceRunning = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: AppFeatures.featuresUpdateNotifier,
      builder: (context, _, __) {
        List<Widget?> buttons = [
          _buildTileButtonCompass(l10n, context),
          _buildTileButtonLocation(l10n, context),
          _buildTileButtonRecorder(l10n, context),
          _buildTileButtonRadar(l10n, context),
          _buildTileButtonShare(l10n, context),
          _buildTileButtonWikipedia(l10n, context),
          _buildTileButtonAbout(l10n, context),
        ];
        List<Widget> filteredButtons =
            buttons.where((widget) => widget != null).cast<Widget>().toList();

        return Scaffold(
            appBar: CandleAppBar(
              title: Text(l10n.screen_header_home),
              subtitle: Text(l10n.appbar_slogan, style: theme.textTheme.bodyMedium),
              talkback: l10n.screen_header_home_t,
              settingsEnabled: true,
            ),
            body: BackgroundWidget(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const LocationAddressTile(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: GridView.count(
                            crossAxisCount: 2, // Two columns
                            childAspectRatio: 1.0, // Aspect ratio of 1.0 (width == height)
                            crossAxisSpacing: 10, // Spacing in between items horizontally
                            mainAxisSpacing: 10, // Spacing in between items vertically
                            children: filteredButtons),
                      ),
                    )
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget? _buildTileButtonAbout(AppLocalizations l10n, BuildContext context) {
    return TileButton(
      title: l10n.button_about,
      talkback: l10n.button_about_t,
      icon: const Icon(Icons.info, size: 80),
      onPressed: () async {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AboutScreen()));
      },
    );
  }

  Widget? _buildTileButtonWikipedia(AppLocalizations l10n, BuildContext context) {
    if (!AppFeatures.overviewWikipedia.isEnabled) {
      return null;
    }
    return TileButton(
      title: l10n.button_wikipedia,
      talkback: l10n.button_wikipedia_t,
      icon: const Icon(Icons.school, size: 80),
      onPressed: () async {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const WikipediaScreen()));
      },
    );
  }

  Widget? _buildTileButtonShare(AppLocalizations l10n, BuildContext context) {
    if (!AppFeatures.overviewShare.isEnabled) {
      return null;
    }
    return TileButton(
      title: l10n.button_share_location,
      talkback: l10n.button_share_location_t,
      icon: const Icon(Icons.share, size: 80),
      onPressed: () async {
        showLoadingDialog(context);

        try {
          var coord = await LocationService.instance.location;
          if (context.mounted && coord != null) {
            var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
            LocationAddress address = (await geo.getGeolocationAddress(coord))!;
            LocationAddress sharingAddress = address.copyWith(name: "MyPosition");
            String message = l10n.location_share_message(coord.latitude, coord.longitude);
            message = "$message\n\n${sharingAddress.formattedAddress}";

            var dataMap = {
              "locations": [sharingAddress.toMap()]
            };
            String prettyJson = const JsonEncoder.withIndent('  ').convert(dataMap);
            final file = await createCandleFileWithData("my_location", prettyJson);

            // Share the file and text
            ShareExtend.share(file.path, "file", subject: message);
          }
        } finally {
          if (context.mounted) Navigator.pop(context);
        }
      },
    );
  }

  Widget? _buildTileButtonRecorder(AppLocalizations l10n, BuildContext context) {
    if (AppFeatures.betaRecording.isNotEnabled) {
      return null;
    }

    if (AppFeatures.overviewRecorder.isNotEnabled) {
      return null;
    }

    return TileButton(
      title: l10n.button_recording,
      talkback: l10n.button_recording_t,
      icon: const Icon(
        Icons.route,
        size: 80,
      ),
      onPressed: () async {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const RecorderControllerScreen()));
      },
    );
  }

  Widget? _buildTileButtonRadar(AppLocalizations l10n, BuildContext context) {
    if (AppFeatures.overviewRadar.isNotEnabled) {
      return null;
    }

    return TileButton(
      title: l10n.button_radar,
      talkback: l10n.button_radar_t,
      icon: const Icon(Icons.radar_outlined, size: 80),
      onPressed: () async {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => PoiRadarScreen()));
      },
    );
  }

  Widget? _buildTileButtonLocation(AppLocalizations l10n, BuildContext context) {
    if (!AppFeatures.overviewLocation.isEnabled) {
      return null;
    }
    return TileButton(
      title: l10n.button_location_create,
      talkback: l10n.button_location_create_t,
      icon: const PoiFavoriteIcon(),
      onPressed: () async {
        showLoadingDialog(context);

        try {
          var coord = await LocationService.instance.location;
          if (context.mounted && coord != null) {
            var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
            LocationAddress? address = await geo.getGeolocationAddress(coord);
            if (!context.mounted) return;
            Navigator.pop(context);
            if (mounted && address != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LocationCreateUpdateScreen(
                    initialLocation: address,
                  ),
                ),
              );
            }
          } else {
            if (!context.mounted) return;
            Navigator.pop(context);
          }
        } catch (e) {
          if (!context.mounted) return;
          Navigator.pop(context);
        }
      },
    );
  }

  Widget? _buildTileButtonCompass(AppLocalizations l10n, BuildContext context) {
    if (!AppFeatures.overviewCompass.isEnabled) {
      return null;
    }
    return TileButton(
      title: l10n.button_compass,
      talkback: l10n.button_compass_t,
      icon: const CompassIcon(rotationDegrees: 30),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CompassScreen()));
      },
    );
  }
}
