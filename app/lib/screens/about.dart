import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<String> _readPubspecVersion() async {
    String pubspecContent = await rootBundle.loadString('pubspec.yaml');
    final RegExp versionPattern = RegExp(r'version: ([\d\.]+)');
    final match = versionPattern.firstMatch(pubspecContent);
    return match != null ? match.group(1)! : 'Unknown';
  }

  void _sendEmail(context) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'a.herz@freegroup.de',
      query: _encodeQueryParameters(<String, String>{
        'subject': l10n.email_contact_subject,
      }),
    );

    try {
      final bool launched = await launchUrl(emailLaunchUri);
      if (!launched) {
        showSnackbar(context, l10n.error_no_email_launch);
      }
    } catch (e) {
      showSnackbar(context, l10n.error_no_email_launch);
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(AppLocalizations.of(context)!.about_mainmenu),
        talkback: AppLocalizations.of(context)!.about_mainmenu_t,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<String>(
              future: _readPubspecVersion(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Icon
                        Expanded(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/icon_appstore.png',
                                fit: BoxFit.fitHeight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // App Name and Version
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'Candle',
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Version: ${snapshot.data}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 80),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l10n.about_app_description,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _sendEmail(context);
              },
              child: Text(l10n.button_contact_me, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(width: 200),
            Text(""),
          ],
        ),
      ),
    );
  }
}
