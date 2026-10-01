import 'package:candle/utils/configuration.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:candle/ui/about/view_models/about_viewmodel.dart';
import 'package:provider/provider.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key, required this.viewModel});

  final AboutViewModel viewModel;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SemanticAnnouncer {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_about_t);
    });

  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_about),
        talkback: l10n.screen_header_about_t,
      ),
      body: BackgroundWidget(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.viewModel.version == null)
                const CircularProgressIndicator()
              else
                Padding(
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
                              style: TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Version: ${widget.viewModel.version}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(width: 80),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.about_app_description,
                    style: theme.textTheme.headlineMedium),
              ),
              Semantics(
                label: l10n.button_contact_me,
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
                          onTap: () => _sendEmail(context),
                          child: Container(
                            width: screenWidth / 3,
                            height: screenWidth / 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                            child: Icon(
                              Icons.email_outlined,
                              size: screenWidth / 4,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ExcludeSemantics(
                          child: Text(
                            l10n.button_contact_me,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Spacing between buttons
              // Promote App Button
              Semantics(
                label: l10n.button_suggest_to_friends,
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
                          onTap: () => _sendShareEmail(context),
                          child: Container(
                            width: screenWidth / 3,
                            height: screenWidth / 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor,
                            ),
                            child: Icon(
                              Icons.share_outlined,
                              size: screenWidth / 4,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ExcludeSemantics(
                          child: Text(
                            l10n.button_suggest_to_friends,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
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
      if (!launched && context.mounted) {
        showSnackbar(context, l10n.error_no_email_launch);
      }
    } on Exception {
      if (context.mounted) showSnackbar(context, l10n.error_no_email_launch);
    }
  }

  Future<void> _sendShareEmail(BuildContext context) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    final String subject = l10n.email_share_subject;
    final String body =
        '${l10n.email_share_body}\n\nApple: $kAppStoreLink\n\nAndroid: $kPlayStoreLink';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      final bool launched = await launchUrl(emailLaunchUri);
      if (!launched && context.mounted) {
        showSnackbar(context, l10n.error_no_email_launch);
      }
    } on Exception {
      if (context.mounted) showSnackbar(context, l10n.error_no_email_launch);
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

/// About screen with its own view model, disposed together with the screen.
Widget buildAboutScreen() => ChangeNotifierProvider(
      create: (_) => AboutViewModel(),
      builder: (context, _) => AboutScreen(viewModel: context.watch()),
    );
