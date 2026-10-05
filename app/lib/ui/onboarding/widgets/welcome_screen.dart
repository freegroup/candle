import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/widgets/focus_on_show.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shown once on first run and again after an update, before the permission
/// gate. Says what Candle is, who it is for and that the look can be changed.
/// Fits on one screen; the text area only scrolls at very large font sizes,
/// the buttons stay visible at the bottom.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue, required this.onSettings});

  final VoidCallback onContinue;
  final VoidCallback onSettings;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenReader = defaultTargetPlatform == TargetPlatform.iOS
        ? l10n.welcome_point_voiceover
        : l10n.welcome_point_talkback;

    return Scaffold(
      body: BackgroundWidget(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // the screen reader starts on the title and reads it out
                        FocusOnShow(
                          child: Semantics(
                            header: true,
                            child: Text(l10n.welcome_title, style: theme.textTheme.headlineMedium),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.welcome_intro, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 24),
                        _point(context, Icons.lock_open, l10n.welcome_point_free),
                        _point(context, Icons.accessibility_new, l10n.welcome_point_accessible),
                        _point(context, Icons.record_voice_over, screenReader),
                        _point(context, Icons.shield_outlined, l10n.welcome_point_privacy),
                        _point(context, Icons.palette_outlined, l10n.welcome_point_adjust),
                      ],
                    ),
                  ),
                ),
              ),
              DialogButton(
                label: l10n.welcome_continue,
                talkback: l10n.welcome_continue_t,
                onTab: widget.onContinue,
              ),
              DialogButton(
                label: l10n.welcome_settings,
                talkback: l10n.welcome_settings_t,
                onTab: widget.onSettings,
                outlined: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _point(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: Icon(icon, color: theme.primaryColor, size: 28),
            ),
          ),
          Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
        ],
      ),
    );
  }
}
