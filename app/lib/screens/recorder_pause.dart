import 'package:candle/services/recorder.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecorderPauseScreen extends StatefulWidget {
  const RecorderPauseScreen({super.key});

  @override
  State<RecorderPauseScreen> createState() => _PauseScreenState();
}

class _PauseScreenState extends State<RecorderPauseScreen> {

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (7 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_recorder_recording),
        talkback: l10n.screen_header_recorder_recording_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPanel(),
          bottom: _buildBottomPane(),
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Paused....'),
        ],
      ),
    );
  }

  Widget _buildBottomPane() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Column(children: [
      Container(
        width: double.infinity, // Full width for TalkBack focus
        child: Semantics(
          button: true, // Explicitly mark as a button
          label: l10n.button_close_t,
          child: BoldIconButton(
            talkback: "",
            buttonWidth: MediaQuery.of(context).size.width / 5,
            icons: Icons.arrow_right,
            onTab: () {
              RecorderService.resume();
            },
          ),
        ),
      )
    ]);
  }
}
