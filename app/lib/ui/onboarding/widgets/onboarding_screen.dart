import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/onboarding/view_models/onboarding_viewmodel.dart';
import 'package:candle/ui/onboarding/widgets/welcome_screen.dart';
import 'package:candle/ui/settings/widgets/settings_screen.dart';
import 'package:candle/ui/shell/widgets/app_shell.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Start of the app: the tabs once all permissions are granted, the request for them before.
Widget buildOnboarding() => ChangeNotifierProvider(
      create: (context) => OnboardingViewModel(permissionService: context.read(), settingsRepository: context.read()),
      builder: (context, _) => Consumer<OnboardingViewModel>(
        builder: (context, viewModel, _) {
          const loading = Scaffold(body: Center(child: CircularProgressIndicator()));
          if (viewModel.welcomeDone == null) return loading;
          if (viewModel.welcomeDone == false) {
            return WelcomeScreen(
              onContinue: viewModel.completeWelcome,
              onSettings: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => buildSettingsScreen())),
            );
          }
          return switch (viewModel.granted) {
            null => loading,
            true => buildAppShell(),
            false => PermissionsScreen(viewModel: viewModel),
          };
        },
      ),
    );

/// Explains why Candle needs its permissions and asks for them.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Future<void> _request() async {
    await widget.viewModel.request.execute();
    if (mounted && widget.viewModel.request.error) _showDeniedDialog();
  }

  void _showDeniedDialog() {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.permissions_denied_title),
          content: Text(l10n.permissions_denied_description, style: theme.textTheme.bodyLarge),
          backgroundColor: theme.cardColor,
          actions: [
            TextButton(
              onPressed: widget.viewModel.openSettings,
              child: Text(l10n.button_common_app_settings),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.button_common_close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

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
                    styleSheet: MarkdownStyleSheet(p: theme.textTheme.bodyLarge),
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  button: true,
                  label: l10n.button_permissions_request,
                  excludeSemantics: true,
                  onTap: _request,
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
                            onTap: _request,
                            child: Container(
                              width: screenWidth / 3,
                              height: screenWidth / 3,
                              decoration:
                                  BoxDecoration(shape: BoxShape.circle, color: theme.primaryColor),
                              child: Icon(Icons.verified, size: screenWidth / 4, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(l10n.button_permissions_request,
                              style: theme.textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => launchUrl(Uri.parse('https://freegroup.github.io/candle/')),
                    style: TextButton.styleFrom(
                      textStyle: theme.textTheme.bodyLarge,
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(l10n.button_privacy_policy),
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
