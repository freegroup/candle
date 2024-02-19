import 'package:candle/screens/navigator.dart';
import 'package:candle/utils/featureflag.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with SemanticAnnouncer {
  @override
  void initState() {
    super.initState();
    _checkPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_permissions_t);
    });
  }

  Future<void> _checkPermissions() async {
    if (await Permission.location.isGranted &&
        await Permission.speech.isGranted &&
        await Permission.microphone.isGranted &&
        (!AppFeatures.allwaysAccessGps.isEnabled || await Permission.locationAlways.isGranted)) {
      _navigateToMainApp();
    }
  }

  Future<void> _requestPermissions() async {
    final locationStatus = await Permission.location.request();
    final microphoneStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();
    if (locationStatus.isGranted && microphoneStatus.isGranted && speechStatus.isGranted) {
      // ask for the "allwaysGPS" access if the user has switched on this feature
      //in the App-Settings
      //
      if (AppFeatures.allwaysAccessGps.isEnabled) {
        final backgroundLocationStatus = await Permission.locationAlways.request();
        if (backgroundLocationStatus.isGranted) {
          _navigateToMainApp();
        } else {
          _showPermissionsDeniedDialog();
        }
      } else {
        _navigateToMainApp();
      }
    } else {
      _showPermissionsDeniedDialog();
    }
  }

  void _showPermissionsDeniedDialog() {
    ThemeData theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.permissions_denied_title),
          content: Text(l10n.permissions_denied_description, style: theme.textTheme.bodyLarge),
          backgroundColor: theme.cardColor,
          actions: <Widget>[
            TextButton(
              child: Text(l10n.button_common_close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _navigateToMainApp() {
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const NavigatorScreen(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;

    MarkdownStyleSheet markdownStyle = MarkdownStyleSheet(
      p: theme.textTheme.bodyLarge,
    );
    return Scaffold(
      appBar: CandleAppBar(
        talkback: l10n.screen_header_permissions_t,
        title: Text(l10n.screen_header_permissions),
      ),
      body: SizedBox.expand(
        child: BackgroundWidget(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MarkdownBody(
                    data: l10n.label_permissions_explain,
                    styleSheet: markdownStyle,
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
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('https://freegroup.github.io/candle/');
                      await launchUrl(url);
                    },
                    style: TextButton.styleFrom(
                        textStyle: theme.textTheme.bodyLarge, // Text color
                        backgroundColor: Colors.black, // Button background color
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    child: const Text('Our Privacy Policy'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
