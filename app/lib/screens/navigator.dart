import 'dart:async';

import 'package:candle/screens/home.dart';
import 'package:candle/screens/locations.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/screens/recorder_controller.dart';
import 'package:candle/screens/routes.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  State<NavigatorScreen> createState() => _ScreenState();
}

class _ScreenState extends State<NavigatorScreen> {
  int currentIndex = 0;
  late Future<LatLng?> _locationFuture;

  final List<Widget> pages = const [
    HomeScreen(),
    LocationsScreen(),
    RoutesScreen(),
    PoiCategoriesScreen(),
    //SettingsScreen(),
    //AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
    return FutureBuilder<LatLng?>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(context);
        } else if (snapshot.hasData && snapshot.data != null) {
          return _buildMainContent(context);
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

  Widget _buildMainContent(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    if (RecorderService.isRecordingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const RecorderControllerScreen()));
      });
    }

    List<BottomNavigationBarItem> navBarItems = [
      BottomNavigationBarItem(label: l10n.home_mainmenu, icon: const Icon(Icons.view_module)),
      BottomNavigationBarItem(label: l10n.locations_mainmenu, icon: const Icon(Icons.location_on)),
      BottomNavigationBarItem(label: l10n.routes_mainmenu, icon: const Icon(Icons.route)),
      BottomNavigationBarItem(label: l10n.explore_mainmenu, icon: const Icon(Icons.travel_explore)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
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
                child: Container(
                  color: isSelected ? theme.cardColor : Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (navBarItems[index].icon as Icon).icon,
                        color: isSelected ? theme.primaryColor : theme.cardColor,
                        size: 40, // Icon size can be adjusted as needed
                      ),
                      Text(
                        navBarItems[index].label!,
                        style: TextStyle(
                          color: isSelected ? theme.primaryColor : theme.cardColor,
                          fontSize: 12, // Font size can be adjusted as needed
                        ),
                      ),
                    ],
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
