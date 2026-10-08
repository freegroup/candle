import 'package:candle/domain/models/tip.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:flutter/material.dart';

/// One tip in large type: its title as heading, then its paragraphs, each one
/// on its own for the screen reader.
class TipScreen extends StatelessWidget {
  const TipScreen({super.key, required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CandleAppBar(title: Text(l10n.screen_header_tip), talkback: tip.title),
      body: SizedBox.expand(
        // the background fills the screen also below a short tip
        child: BackgroundWidget(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // the app bar reads out the title already
                ExcludeSemantics(child: Text(tip.title, style: theme.textTheme.headlineMedium)),
                for (final paragraph in tip.paragraphs) ...[
                  const SizedBox(height: 20),
                  Text(paragraph, style: theme.textTheme.headlineSmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
