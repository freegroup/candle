import 'package:candle/screens/favorites.dart';
import 'package:candle/screens/home.dart';
import 'package:candle/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  State<NavigatorScreen> createState() => _ScreenState();
}

class _ScreenState extends State<NavigatorScreen> {
  int currentIndex = 0;
  final List<Widget> pages = const [
    HomeScreen(),
    FavoriteScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Request permissions on app startup
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request(); // Request location permission
    // Add more permission requests here if needed
  }

  @override
  Widget build(BuildContext context) {
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
          BottomNavigationBarItem(label: "Favoriten", icon: Icon(Icons.bookmarks)),
          BottomNavigationBarItem(label: "Einstellungen", icon: Icon(Icons.settings))
        ],
      ),
    );
  }
}
