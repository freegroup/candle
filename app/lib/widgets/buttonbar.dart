import 'package:candle/screens/screens.dart';
import 'package:flutter/material.dart';

class CandleButtonBar extends StatefulWidget {
  const CandleButtonBar({super.key});

  @override
  CandleButtonBarState createState() => CandleButtonBarState();
}

class CandleButtonBarState extends State<CandleButtonBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '$HomeScreen');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '$FavoriteScreen');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '$SettingsScreen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optional: Determine the current route and set the selected index accordingly
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
    _selectedIndex = _getSelectedIndexFromRoute(currentRoute);

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      iconSize: 50,
      selectedItemColor: Colors.black,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(label: "Hauptmenü", icon: Icon(Icons.home_outlined)),
        BottomNavigationBarItem(label: "Favoriten", icon: Icon(Icons.favorite_border_outlined)),
        BottomNavigationBarItem(label: "Einstellungen", icon: Icon(Icons.settings_accessibility)),
      ],
    );
  }

  int _getSelectedIndexFromRoute(String route) {
    if (route == '$HomeScreen') {
      // Assuming '/' is the route for the home screen
      return 0;
    }
    if (route.startsWith('$FavoriteScreen')) {
      // Check if route string contains 'ThirdScreen'
      return 1;
    }
    if (route.startsWith('$SettingsScreen')) {
      // Check if route string contains 'SecondScreen'
      return 2;
    }
    return 0; // Default to the first tab if none of the above conditions are met
  }
}
