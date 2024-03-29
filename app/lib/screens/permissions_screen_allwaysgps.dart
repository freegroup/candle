import 'package:candle/utils/featureflag.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PermissionsAllwaysGPSScreen extends StatefulWidget {
  const PermissionsAllwaysGPSScreen({super.key});

  @override
  State<PermissionsAllwaysGPSScreen> createState() => _ScreenState();
}

class _ScreenState extends State<PermissionsAllwaysGPSScreen> with SemanticAnnouncer {
  @override
  void initState() {
    super.initState();
    _checkPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_permissions_t);
    });
  }

  Future<void> _checkPermission() async {
    if (await Permission.locationAlways.isGranted) {
      _granted();
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.locationAlways.isPermanentlyDenied) {
      _openLocationAlwaysAppSettings();
    } else {
      final backgroundLocationStatus = await Permission.locationAlways.request();
      if (backgroundLocationStatus.isGranted) {
        _granted();
      } else {
        _denied();
      }
    }
  }

  void _denied() {
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

  void _granted() {
    // User has granted the permission. Now we can activate the featureflag per default
    // Later the user can switch off again....but the permissions stays.
    //
    AppFeatures.allwaysAccessGps.setEnabled(true);
    if (mounted) Navigator.of(context).pop();
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MarkdownBody(
                      data: l10n.label_permissions_allwaysgps_explain,
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
      ),
    );
  }

  void _openLocationAlwaysAppSettings() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogBackgroundColor: theme.cardColor,
            // Customize other dialog properties as needed
          ),
          child: AlertDialog(
            title: Text(l10n.screen_header_location_always),
            content: Text(l10n.location_permission_explanation),
            actions: <Widget>[
              TextButton(
                child: Text(l10n.button_common_app_settings_t),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
              TextButton(
                child: Text(l10n.button_common_close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
