import 'package:candle/services/recorder.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecorderStoppedScreen extends StatefulWidget {
  const RecorderStoppedScreen({super.key});

  @override
  State<RecorderStoppedScreen> createState() => _StoppedScreenState();
}

class _StoppedScreenState extends State<RecorderStoppedScreen> {
  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (7 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.recorder_dialog),
        talkback: l10n.recorder_dialog_t,
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
    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = screenWidth * (3 / 7);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: imageWidth, // Set the width to 4/7 of the screen width
            child: Image.asset(
              'assets/images/recording_splash.png', // Replace with your image path
              fit: BoxFit.cover, // This can be changed to fit your design needs
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPane() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Center(
      // Center the content vertically and horizontally
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take up as little space as necessary
        children: [
          Container(
            width: MediaQuery.of(context).size.width / 4, // Set the width of the button
            child: Semantics(
              button: true,
              label: l10n.button_close_t,
              child: BoldIconButton(
                talkback: "",
                buttonWidth: MediaQuery.of(context).size.width / 4,
                icons: Icons.arrow_right,
                onTab: () async {
                  RecorderService.start();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
