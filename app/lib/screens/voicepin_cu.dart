import 'dart:async';

import 'package:candle/models/location_address.dart';
import 'package:candle/models/voicepin.dart';
import 'package:candle/services/database.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/accessible_text_input.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/dialog_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/latlng_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

class VoicePinCreateUpdateScreen extends StatefulWidget {
  final VoicePin voicepin;

  const VoicePinCreateUpdateScreen({super.key, required this.voicepin});

  @override
  State<VoicePinCreateUpdateScreen> createState() => _ScreenState();
}

class _ScreenState extends State<VoicePinCreateUpdateScreen> with SemanticAnnouncer {
  TextEditingController editingController = TextEditingController();
  final StreamController<LocationAddress> _addressController = StreamController<LocationAddress>();

  bool _isUpdate = false;
  bool canSubmit = false;
  late VoicePin _voicepin;
  late LatLng _changedLatLng;

  @override
  void initState() {
    super.initState();

    _voicepin = widget.voicepin;
    _changedLatLng = _voicepin.latlng();
    _isUpdate = _voicepin.id != null;
    editingController.text = _voicepin.memo;

    canSubmit = editingController.text.isNotEmpty;
    editingController.addListener(() {
      if (mounted) {
        setState(() {
          canSubmit = editingController.text.isNotEmpty;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      var text =
          _isUpdate ? l10n.screen_header_voicepin_update_t : l10n.screen_header_voicepin_add_t;
      announceOnShow(text);
    });
  }

  @override
  void dispose() {
    _addressController.close();
    super.dispose();
  }

  Future<void> _save(BuildContext context, bool saveAndClose) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    String memo = editingController.text;

    VoicePin voicepinToSave = _voicepin.copyWith(
      memo: memo,
      lat: _changedLatLng.latitude,
      lon: _changedLatLng.longitude,
    );
    if (_isUpdate) {
      DatabaseService.instance.updateVoicePin(voicepinToSave);
    } else {
      DatabaseService.instance.addVoicePin(voicepinToSave);
    }
    if (!mounted) return;
    if (saveAndClose) {
      showSnackbarAndNavigateBack(context, l10n.voicepin_saved_snackbar);
    } else {
      showSnackbar(context, l10n.voicepin_saved_snackbar);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    final int factor = isKeyboardVisible ? 1 : 5;
    double screenDividerFraction = screenHeight * (factor / 9);
    // Determine if the keyboard is visible

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(
          _isUpdate ? l10n.screen_header_voicepin_update : l10n.screen_header_voicepin_add,
        ),
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

  Widget _buildTopPane(BuildContext context) {
    return ExcludeSemantics(
      child: LatLngPickerWidget(
        latlng: _voicepin.latlng(),
        onLatLngChanged: (newLatLng) {
          _changedLatLng = newLatLng;
        },
        onLock: () => _save(context, false),
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(35.0, 25.0, 35.0, 10.0),
          child: AccessibleTextInput(
            hideMicrophone: true,
            maxLines: isKeyboardVisible ? 6 : 4,
            mandatory: true,
            hintText: l10n.voicepin_memo,
            talkbackInput: l10n.voicepin_memo_t,
            talkbackIcon: l10n.voicepin_add_speak_t,
            controller: editingController,
          ),
        ),
        if (!isKeyboardVisible)
          DialogButton(
              label: l10n.button_common_save,
              talkback: l10n.button_common_save_t,
              onTab: canSubmit
                  ? () {
                      _save(context, true);
                    }
                  : () {
                      showSnackbar(context, l10n.voicepin_memo_required_snackbar);
                    } // Disable the button if name is empty
              ),
      ],
    );
  }
}
