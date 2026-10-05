import 'package:candle/domain/models/location_note.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/location_notes/view_models/location_note_edit_viewmodel.dart';
import 'package:candle/ui/location_notes/widgets/pause_location_notes.dart';
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
/// With [focusMemo] the text field is focused at once. No location notes are
/// reported while it is open.
Widget buildLocationNoteEditScreen(LocationNote pin, {bool focusMemo = false}) =>
    PauseLocationNotes(
      child: ChangeNotifierProvider(
        create: (context) => LocationNoteEditViewModel(locationNoteRepository: context.read(), pin: pin),
        builder: (context, _) => LocationNoteEditScreen(viewModel: context.read(), focusMemo: focusMemo),
      ),
    );

/// The memo of a voice pin; sighted users can move the pin on a map.
class LocationNoteEditScreen extends StatefulWidget {
  const LocationNoteEditScreen({super.key, required this.viewModel, this.focusMemo = false});

  final LocationNoteEditViewModel viewModel;
  final bool focusMemo;

  @override
  State<LocationNoteEditScreen> createState() => _LocationNoteEditScreenState();
}

class _LocationNoteEditScreenState extends State<LocationNoteEditScreen> with SemanticAnnouncer {
  final _memoController = TextEditingController();

  LocationNoteEditViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _memoController.text = _viewModel.pin.memo;
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
            ? l10n.screen_header_location_note_update
            : l10n.screen_header_location_note_add),
        talkback: _viewModel.isUpdate
            ? l10n.screen_header_location_note_update_t
            : l10n.screen_header_location_note_add_t,
        offerNewLocationNote: false,
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
          // scrolls when large system fonts need more room than the pane has
          bottom: SingleChildScrollView(
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(35.0, 25.0, 35.0, 10.0),
                child: AccessibleTextInput(
                  autofocus: widget.focusMemo,
                  maxLines: keyboardVisible ? 6 : 4,
                  mandatory: true,
                  hintText: l10n.location_note_memo,
                  talkbackInput: l10n.location_note_memo_t,
                  talkbackIcon: l10n.location_note_add_speak_t,
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
      ),
    );
  }

  Future<void> _save({required bool close}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_memoController.text.trim().isEmpty) {
      showSnackbar(context, l10n.location_note_memo_required_snackbar);
      return;
    }
    await _viewModel.save.execute(_memoController.text);
    if (!mounted || !_viewModel.save.completed) return;
    if (close) {
      showSnackbarAndNavigateBack(context, l10n.location_note_saved_snackbar);
    } else {
      showSnackbar(context, l10n.location_note_saved_snackbar);
    }
  }
}
