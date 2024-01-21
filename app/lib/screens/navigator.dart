import 'dart:async';

import 'package:candle/screens/fab.dart';
import 'package:candle/screens/home.dart';
import 'package:candle/screens/locations.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/screens/recorder_controller.dart';
import 'package:candle/screens/routes.dart';
import 'package:candle/screens/voicepins.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

class ButtonBarEntry {
  final Icon icon;
  final String label;
  final String talkback;

  ButtonBarEntry({required this.icon, required this.label, required this.talkback});
}

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  State<NavigatorScreen> createState() => _ScreenState();
}

class _ScreenState extends State<NavigatorScreen> {
  int currentIndex = 0;
  late Future<LatLng?> _locationFuture;

  final List<GlobalKey> pageKeys = List.generate(5, (index) => GlobalKey());

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
      //SettingsScreen(),
      //AboutScreen(),
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
      fab = fabProvider!.floatingActionButton(context);
    }

    return FutureBuilder<LatLng?>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(context);
        } else if (snapshot.hasData && snapshot.data != null) {
          return _buildMainContent(context, fab);
        } else {
          return _buildErrorScreen(context);
        }
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildErrorScreen(BuildContext context) {
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

  Widget _buildMainContent(BuildContext context, Widget? fab) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    if (RecorderService.isRecordingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const RecorderControllerScreen()));
      });
    }

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
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      floatingActionButton: fab,
      bottomNavigationBar: BottomAppBar(
        color: theme.primaryColor,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navBarItems.length, (index) {
            bool isSelected = currentIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () {
                  //SemanticsService.announce(pages[index].getTalkback(context), TextDirection.ltr);
                  setState(() {
                    currentIndex = index;
                  });
                },
                child: Semantics(
                  label: navBarItems[index].talkback,
                  child: Container(
                    color: isSelected ? theme.cardColor : Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          navBarItems[index].icon.icon,
                          color: isSelected ? theme.primaryColor : theme.cardColor,
                          size: 40, // Icon size can be adjusted as needed
                        ),
                        Text(
                          navBarItems[index].label,
                          style: TextStyle(
                            color: isSelected ? theme.primaryColor : theme.cardColor,
                            fontSize: 12, // Font size can be adjusted as needed
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
