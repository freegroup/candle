import 'dart:async';

import 'package:candle/models/location_address.dart';
import 'package:candle/models/voicepin.dart';
import 'package:candle/services/database.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/accessible_text_input.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VoicePinCreateUpdateScreen extends StatefulWidget {
  final VoicePin voicepin;

  const VoicePinCreateUpdateScreen({super.key, required this.voicepin});

  @override
  State<VoicePinCreateUpdateScreen> createState() => _ScreenState();
}

class _ScreenState extends State<VoicePinCreateUpdateScreen> {
  TextEditingController editingController = TextEditingController();
  final StreamController<LocationAddress> _addressController = StreamController<LocationAddress>();

  bool _isUpdate = false;
  bool canSubmit = false;

  @override
  void initState() {
    super.initState();

    _isUpdate = widget.voicepin.id != null;
    editingController.text = widget.voicepin.memo;

    editingController.addListener(() {
      if (mounted) {
        setState(() {
          canSubmit = editingController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.close();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    String memo = editingController.text;

    VoicePin voicepinToSave = widget.voicepin.copyWith(memo: memo);
    if (_isUpdate) {
      DatabaseService.instance.updateVoicePin(voicepinToSave);
    } else {
      DatabaseService.instance.addVoicePin(voicepinToSave);
    }
    if (!mounted) return;
    showSnackbarAndNavigateBack(context, l10n.label_favorite_saved);
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (7 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title:
            Text(_isUpdate ? l10n.screen_header_voicepin_update : l10n.screen_header_voicepin_add),
        talkback:
            _isUpdate ? l10n.screen_header_voicepin_update_t : l10n.screen_header_voicepin_add_t,
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

  Padding _buildTopPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: AccessibleTextInput(
          maxLines: 5,
          mandatory: true,
          hintText: l10n.voicepin_memo,
          talkbackInput: l10n.voicepin_memo_t,
          talkbackIcon: l10n.voicepin_add_speak_t,
          controller: editingController),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return BoldIconButton(
        talkback: l10n.button_save_t,
        buttonWidth: MediaQuery.of(context).size.width / 7,
        icons: Icons.check,
        onTab: canSubmit
            ? () {
                _save(context);
              }
            : () {
                showSnackbar(context, l10n.voicepin_memo_required_snackbar);
              } // Disable the button if name is empty
        );
  }
}
