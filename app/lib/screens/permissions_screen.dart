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
    if (locationStatus.isGranted && microphoneStatus.isGranted) {
      _navigateToMainApp();
    } else {
      // Handle the case when one or both permissions are denied
    }
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const NavigatorScreen(),
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Information Text
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
            child: Text(
              l10n.label_permissions_explain,
              style: theme.textTheme.headlineMedium!
                  .copyWith(color: theme.primaryColor), // Larger text style
              textAlign: TextAlign.center,
            ),
          ),
          Spacer(), // Spacer to position the button in the desired area
          // Icon Button
          Container(
            width: screenWidth * 0.8, // 80% of screen width
            decoration: BoxDecoration(
              color: Colors.black, // Black background
              borderRadius: BorderRadius.circular(8), // 8 unit rounded borders
            ),
            padding: EdgeInsets.all(16),

            child: Column(
              children: [
                // Icon Button
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
                      Icons.verified, // Example icon
                      size: screenWidth / 4, // Icon size
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20), // Spacing between icon and text
                // Button Text
                Text(
                  l10n.button_permissions_request,
                  style: theme.textTheme.headlineSmall!
                      .copyWith(color: theme.primaryColor), // Larger text style, white color
                ),
              ],
            ),
          ),
          Spacer(), // Spacer for bottom padding
        ],
      ),
    );
  }
}
