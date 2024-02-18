import 'package:candle/screens/navigator.dart';
import 'package:candle/screens/permissions_screen.dart';
import 'package:candle/utils/featureflag.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsCheckWidget extends StatelessWidget {
  const PermissionsCheckWidget({super.key});

  Future<bool> _checkPermissions() async {
    var locationStatus = await Permission.location.status;
    var microphoneStatus = await Permission.microphone.status;
    var speechStatus = await Permission.speech.status;
    var locationAlwaysStatus = await Permission.locationAlways.status;

    print("Permission.speech.isGranted : ${await Permission.speech.isGranted}");
    print("Permission.location.isGranted : ${await Permission.location.isGranted}");
    print("Permission.microphone.isGranted : ${await Permission.microphone.isGranted}");
    print("Permission.locationAlways.isGranted : ${await Permission.locationAlways.isGranted}");
    print(
        "Permission.locationAlways.isPermanentlyDenied : ${await Permission.locationAlways.isPermanentlyDenied}");
    // Switch off the feature if the user has removed the permissions in the
    // android settings. Never ask here in the initial screen for the permissions.
    // The user MUST always activate them in the settings screen (again)
    //
    if (AppFeatures.allwaysAccessGps.isEnabled && !locationAlwaysStatus.isGranted) {
      AppFeatures.allwaysAccessGps.setEnabled(false);
    }

    // Ensure all required permissions are granted
    return locationStatus.isGranted && microphoneStatus.isGranted && speechStatus.isGranted;
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
