import 'dart:async';

import 'package:candle/screens/fab.dart';
import 'package:candle/screens/home.dart';
import 'package:candle/screens/locations.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/screens/poi_radar.dart';
import 'package:candle/screens/recorder_controller.dart';
import 'package:candle/screens/routes.dart';
import 'package:candle/screens/voicepins.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/recorder.dart';
import 'package:candle/utils/featureflag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

class ButtonBarEntry {
  final Icon icon;
  final String label;
  final String talkback;
  final bool isVisible;
  ButtonBarEntry({
    required this.icon,
    required this.label,
    required this.talkback,
    this.isVisible = true,
  });
}

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  State<NavigatorScreen> createState() => _ScreenState();
}

class _ScreenState extends State<NavigatorScreen> {
  int currentIndex = 0;
  late Future<LatLng?> _locationFuture;

  final List<GlobalKey> pageKeys = List.generate(6, (index) => GlobalKey());

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomeScreen(key: pageKeys[0]),
      LocationsScreen(key: pageKeys[1]),
      RoutesScreen(key: pageKeys[2]),
      VoicePinsScreen(key: pageKeys[3]),
      PoiCategoriesScreen(key: pageKeys[4]),
      PoiRadarScreen(key: pageKeys[5]),
    ];
    _initLocationFuture();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initLocationFuture() {
    _locationFuture = LocationService.instance.location;
  }

  void _retryFetchingLocation() {
    setState(() => _initLocationFuture());
  }

  @override
  Widget build(BuildContext context) {
    var currentScreenState = pageKeys[currentIndex].currentState;
    Widget? fab;
    if (currentScreenState is FloatingActionButtonProvider) {
      FloatingActionButtonProvider fabProvider = currentScreenState as FloatingActionButtonProvider;
      fab = fabProvider.floatingActionButton(context);
    }

    return FutureBuilder<LatLng?>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(context);
        } else if (snapshot.hasData && snapshot.data != null) {
          return _buildContent(context, fab);
        } else {
          return _buildError(context);
        }
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildError(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error obtaining GPS signal'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryFetchingLocation,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Widget? fab) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    // Open the Route Recording Screen again if the recording is still running. This
    // is the default if we allow "locationAllways" and terminate the app. In this
    // case the recording continues even if the app is closed.
    //
    if (RecorderService.isRecordingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const RecorderControllerScreen()));
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      floatingActionButton: fab,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 1), // Top border
          ),
        ),
        child: BottomAppBar(
          color: theme.primaryColor,
          padding: EdgeInsets.zero,
          child: ValueListenableBuilder(
            valueListenable: AppFeatures.featuresUpdateNotifier,
            builder: (context, _, __) {
              List<ButtonBarEntry> navBarItems = [
                ButtonBarEntry(
                  label: l10n.buttonbar_home,
                  talkback: l10n.buttonbar_home_t,
                  icon: const Icon(Icons.view_module),
                ),
                ButtonBarEntry(
                  label: l10n.buttonbar_locations,
                  talkback: l10n.buttonbar_locations_t,
                  icon: const Icon(Icons.location_on),
                ),
                ButtonBarEntry(
                  label: l10n.buttonbar_routes,
                  talkback: l10n.buttonbar_routes_t,
                  icon: const Icon(Icons.route),
                  isVisible: AppFeatures.betaRecording.isEnabled,
                ),
                ButtonBarEntry(
                  label: l10n.buttonbar_voicepins,
                  talkback: l10n.buttonbar_voicepins_t,
                  icon: const Icon(Icons.mic),
                ),
                ButtonBarEntry(
                  label: l10n.buttonbar_explore,
                  talkback: l10n.buttonbar_explore_t,
                  icon: const Icon(Icons.travel_explore),
                ),
                ButtonBarEntry(
                  label: l10n.buttonbar_radar,
                  talkback: l10n.buttonbar_radar_t,
                  icon: const Icon(Icons.radar_outlined),
                ),
              ];

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navBarItems.length, (index) {
                  bool isSelected = currentIndex == index;
                  var item = navBarItems[index];
                  return Visibility(
                    visible: item.isVisible,
                    child: Expanded(
                      child: InkWell(
                        onTap: () => setState(() => currentIndex = index),
                        child: Semantics(
                          label: item.talkback,
                          child: Container(
                            color: isSelected ? theme.cardColor : Colors.transparent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon.icon,
                                  color: isSelected ? theme.primaryColor : theme.cardColor,
                                  size: 40,
                                ),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected ? theme.primaryColor : theme.cardColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
