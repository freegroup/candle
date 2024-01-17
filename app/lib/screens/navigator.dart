import 'dart:async';

import 'package:candle/screens/about.dart';
import 'package:candle/screens/favorites.dart';
import 'package:candle/screens/home.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/screens/recorder.dart';
import 'package:candle/screens/talkback.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/recorder.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/semantics.dart';

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  State<NavigatorScreen> createState() => _ScreenState();
}

class _ScreenState extends State<NavigatorScreen> {
  late StreamSubscription<RecordingState> recordingServiceSubscription;
  bool isRecording = false;

  int currentIndex = 0;
  late Future<LatLng?> _locationFuture;

  final List<TalkbackScreen> pages = const [
    HomeScreen(),
    FavoriteScreen(),
    PoiCategoriesScreen(),
    //SettingsScreen(),
    AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initLocationFuture();

    // Subscribe to the RecorderService state
    recordingServiceSubscription = RecorderService.recordingStateStream.listen(
      (RecordingState state) {
        setState(() {
          isRecording = (state == RecordingState.recording || state == RecordingState.paused);
        });
      },
    );

    // Initial check of the recording state
    _initialRecordingState();
  }

  @override
  void dispose() {
    super.dispose();
    recordingServiceSubscription.cancel();
  }

  void _initialRecordingState() async {
    isRecording = await FlutterBackgroundService().isRunning();
    setState(() {}); // Trigger a rebuild
  }

  void _initLocationFuture() {
    _locationFuture = LocationService.instance.location;
  }

  void _retryFetchingLocation() {
    setState(() {
      _initLocationFuture(); // Reset the future to trigger a rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng?>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // GPS signal not obtained yet, show loading screen
          return _buildLoadingScreen(context);
        } else if (snapshot.hasData && snapshot.data != null) {
          // GPS signal obtained, show main content
          return _buildMainContent(context);
        } else {
          // GPS signal not found or error occurred
          return _buildErrorScreen(context);
        }
      },
    );
  }

  Widget _buildLoadingScreen(context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScreen(context) {
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

  Widget _buildMainContent(context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    List<BottomNavigationBarItem> navBarItems = [
      BottomNavigationBarItem(label: l10n.home_mainmenu, icon: const Icon(Icons.view_module)),
      BottomNavigationBarItem(label: l10n.favorite_mainmenu, icon: const Icon(Icons.location_on)),
      BottomNavigationBarItem(label: l10n.explore_mainmenu, icon: const Icon(Icons.travel_explore)),
      BottomNavigationBarItem(label: l10n.about_mainmenu, icon: const Icon(Icons.contact_support)),
    ];

    return isRecording
        ? const RecorderScreen()
        : Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              child: IndexedStack(
                key: ValueKey<int>(currentIndex),
                index: currentIndex,
                children: pages,
              ),
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
                        SemanticsService.announce(
                            pages[index].getTalkback(context), TextDirection.ltr);
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
