import 'package:candle/screens/camera.dart';
import 'package:candle/screens/navigator.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (await Permission.location.isGranted && await Permission.microphone.isGranted) {
      _navigateToMainApp();
    }
  }

  Future<void> _requestPermissions() async {
    final locationStatus = await Permission.location.request();
    final microphoneStatus = await Permission.microphone.request();
    final cameraStatus = await Permission.camera.request();
    if (locationStatus.isGranted && microphoneStatus.isGranted && cameraStatus.isGranted) {
      _navigateToMainApp();
    } else {
      // Handle the case when one or both permissions are denied
    }
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const NavigatorScreen(),
      //builder: (context) => const CameraScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CandleAppBar(
        talkback: l10n.permissions_dialog_t,
        title: Text(l10n.permissions_dialog),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.label_permissions_explain,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: l10n.button_permissions_request,
              child: Center(
                child: Container(
                  width: screenWidth * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _requestPermissions,
                        child: Container(
                          width: screenWidth / 3,
                          height: screenWidth / 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor,
                          ),
                          child: Icon(
                            Icons.verified,
                            size: screenWidth / 4,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ExcludeSemantics(
                        child: Text(
                          l10n.button_permissions_request,
                          style: theme.textTheme.headlineSmall!.copyWith(color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
