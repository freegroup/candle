import 'package:candle/services/recorder.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/accessible_text_input.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecorderStoppedScreen extends StatefulWidget {
  const RecorderStoppedScreen({super.key});

  @override
  State<RecorderStoppedScreen> createState() => _ScreenState();
}

class _ScreenState extends State<RecorderStoppedScreen> {
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

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AccessibleTextInput(
            controller: _nameController,
            hintText: "Enter Name", // Replace with your hint text
            mandatory: true,
            onSubmitted: (value) {
              // Handle the submitted value
            },
            talkbackInput: "Enter Name", // Accessibility label for the input field
            talkbackIcon: "Start Voice Input", // Accessibility label for the voice input icon
          ),
          SizedBox(height: 50), // Spacing between text input and image
          Container(
            width: imageWidth,
            child: Image.asset(
              'assets/images/recording_splash.png', // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),
          // ... other widgets if needed ...
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
                  if (_nameController.text.trim().isNotEmpty) {
                    RecorderService.start(_nameController.text.trim());
                  } else {
                    showSnackbar(context, "Please enter a name of the route to start recording.");
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
