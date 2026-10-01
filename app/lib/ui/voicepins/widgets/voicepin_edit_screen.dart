import 'package:candle/domain/models/voicepin.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/ui/voicepins/view_models/voicepin_edit_viewmodel.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/accessible_text_input.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
import 'package:candle/ui/core/widgets/latlng_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Edit screen for [pin] with its own view model; a pin without id is added.
Widget buildVoicePinEditScreen(VoicePin pin) => ChangeNotifierProvider(
      create: (context) => VoicePinEditViewModel(voicePinRepository: context.read(), pin: pin),
      builder: (context, _) => VoicePinEditScreen(viewModel: context.read()),
    );

/// The memo of a voice pin; sighted users can move the pin on a map.
class VoicePinEditScreen extends StatefulWidget {
  const VoicePinEditScreen({super.key, required this.viewModel});

  final VoicePinEditViewModel viewModel;

  @override
  State<VoicePinEditScreen> createState() => _VoicePinEditScreenState();
}

class _VoicePinEditScreenState extends State<VoicePinEditScreen> with SemanticAnnouncer {
  final _memoController = TextEditingController();

  VoicePinEditViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _memoController.text = _viewModel.pin.memo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;
      announceOnShow(_viewModel.isUpdate
          ? l10n.screen_header_voicepin_update_t
          : l10n.screen_header_voicepin_add_t);
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(_viewModel.isUpdate
            ? l10n.screen_header_voicepin_update
            : l10n.screen_header_voicepin_add),
        talkback: _viewModel.isUpdate
            ? l10n.screen_header_voicepin_update_t
            : l10n.screen_header_voicepin_add_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenHeight * ((keyboardVisible ? 1 : 5) / 9),
          top: ExcludeSemantics(
            child: LatLngPickerWidget(
              latlng: _viewModel.pin.latlng(),
              onLatLngChanged: _viewModel.movePin,
              onLock: () => _save(close: false),
            ),
          ),
          bottom: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(35.0, 25.0, 35.0, 10.0),
                child: AccessibleTextInput(
                  hideMicrophone: true,
                  maxLines: keyboardVisible ? 6 : 4,
                  mandatory: true,
                  hintText: l10n.voicepin_memo,
                  talkbackInput: l10n.voicepin_memo_t,
                  talkbackIcon: l10n.voicepin_add_speak_t,
                  controller: _memoController,
                ),
              ),
              if (!keyboardVisible)
                DialogButton(
                  label: l10n.button_common_save,
                  talkback: l10n.button_common_save_t,
                  onTab: () => _save(close: true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save({required bool close}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_memoController.text.trim().isEmpty) {
      showSnackbar(context, l10n.voicepin_memo_required_snackbar);
      return;
    }
    await _viewModel.save.execute(_memoController.text);
    if (!mounted || !_viewModel.save.completed) return;
    if (close) {
      showSnackbarAndNavigateBack(context, l10n.voicepin_saved_snackbar);
    } else {
      showSnackbar(context, l10n.voicepin_saved_snackbar);
    }
  }
}
