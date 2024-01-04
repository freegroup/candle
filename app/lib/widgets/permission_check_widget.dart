import 'package:candle/screens/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:candle/screens/navigator.dart';
import 'package:candle/screens/permissions_screen.dart';

class PermissionsCheckWidget extends StatelessWidget {
  const PermissionsCheckWidget({super.key});

  Future<bool> _checkPermissions() async {
    bool locationGranted = await Permission.location.isGranted;
    bool microphoneGranted = await Permission.microphone.isGranted;
    bool cameraGranted = await Permission.camera.isGranted;
    return locationGranted && microphoneGranted && cameraGranted;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPermissions(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            return const NavigatorScreen(); // If both permissions are granted, go to main app
            //return const CameraScreen(); // If both permissions are granted, go to main app
          } else {
            return const PermissionsScreen(); // Otherwise, show permissions request screen
          }
        }
        return const Center(child: CircularProgressIndicator()); // Show loading indicator
      },
    );
  }
}
