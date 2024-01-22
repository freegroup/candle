import 'package:candle/services/recorder.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/accessible_text_input.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/dialog_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class RecorderStartScreen extends StatefulWidget {
  const RecorderStartScreen({super.key});

  @override
  State<RecorderStartScreen> createState() => _ScreenState();
}

class _ScreenState extends State<RecorderStartScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (7 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_recorder_start),
        talkback: l10n.screen_header_recorder_start_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(context),
          bottom: _buildBottomPane(context),
        ),
      ),
    );
  }

  Widget _buildTopPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = screenWidth * (2 / 7);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AccessibleTextInput(
              controller: _nameController,
              hintText: l10n.route_name,
              mandatory: true,
              onSubmitted: (value) {},
              talkbackInput: l10n.route_name_t,
              talkbackIcon: l10n.route_add_speak_t,
            ),
            const SizedBox(height: 50),
            MarkdownBody(data: l10n.route_recording_intro),
            const SizedBox(height: 50),
            Container(
              width: imageWidth,
              child: Image.asset('assets/images/recording_splash.png', fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return DialogButton(
        label: l10n.button_recording,
        talkback: l10n.button_recording_t,
        onTab: _nameController.text.trim().isNotEmpty
            ? () {
                RecorderService.start(_nameController.text.trim());
              }
            : () {
                showSnackbar(context, l10n.route_name_required_snackbar);
              } // Disable the button if name is empty
        );
  }
}
