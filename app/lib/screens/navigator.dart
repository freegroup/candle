import 'package:candle/screens/favorites.dart';
import 'package:candle/screens/home.dart';
import 'package:candle/screens/settings.dart';
import 'package:candle/services/location.dart';
import 'package:flutter/material.dart';
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
    FavoriteScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initLocationFuture();
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
          return _buildLoadingScreen();
        } else if (snapshot.hasData && snapshot.data != null) {
          // GPS signal obtained, show main content
          return _buildMainContent();
        } else {
          // GPS signal not found or error occurred
          return _buildErrorScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error obtaining GPS signal'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryFetchingLocation,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        iconSize: 50,
        selectedItemColor: Colors.black,
        onTap: (newIndex) {
          setState(() {
            currentIndex = newIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(label: "Home", icon: Icon(Icons.view_module)),
          BottomNavigationBarItem(label: "Favoriten", icon: Icon(Icons.location_on)),
          BottomNavigationBarItem(label: "Einstellungen", icon: Icon(Icons.settings))
        ],
      ),
    );
  }
}
