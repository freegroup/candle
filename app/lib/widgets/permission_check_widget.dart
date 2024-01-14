import 'dart:io'; 

import 'package:candle/screens/navigator.dart';
import 'package:candle/screens/permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsCheckWidget extends StatelessWidget {
  const PermissionsCheckWidget({super.key});

  Future<bool> _checkPermissions() async {
    var locationStatus = await Permission.location.status;
    var microphoneStatus = await Permission.microphone.status;
    var cameraStatus = await Permission.camera.status;
    var backgroundLocationStatus = PermissionStatus.granted;

    // Only check for background location on Android if foreground permission is granted
    if (Platform.isAndroid && locationStatus.isGranted) {
      backgroundLocationStatus = await Permission.locationAlways.status;
    }

    // Ensure all required permissions are granted
    return locationStatus.isGranted &&
        microphoneStatus.isGranted &&
        cameraStatus.isGranted &&
        backgroundLocationStatus.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPermissions(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            // If all required permissions are granted, navigate to the main app
            return const NavigatorScreen();
          } else {
            // If not all permissions are granted, navigate to the Permissions Screen
            return const PermissionsScreen();
          }
        }
        // While checking the permissions, show a loading indicator
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
