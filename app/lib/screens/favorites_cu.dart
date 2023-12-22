import 'package:candle/services/database.dart';
import 'package:candle/services/location.dart';

import 'package:candle/models/location.dart' as model;
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:location/location.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class FavoriteCreateUpdateScreen extends StatefulWidget {
  final model.Location? initialLocation;

  const FavoriteCreateUpdateScreen({super.key, this.initialLocation});

  @override
  State<FavoriteCreateUpdateScreen> createState() => _ScreenState();
}

class _ScreenState extends State<FavoriteCreateUpdateScreen> {
  TextEditingController editingController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isUpdate = false;
  model.Location? stateLocation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    stateLocation = widget.initialLocation;
    if (stateLocation != null) {
      _isUpdate = true;
      editingController.text = stateLocation!.name;
    }
  }

  Future<void> _saveLocation(BuildContext context) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    String name = editingController.text;

    // UPDATE a new Location
    //
    if (_isUpdate) {
      model.Location updatedLocation = stateLocation!.copyWith(name: name);
      await DatabaseService.instance.update(updatedLocation);
      if (!mounted) return;
      showSnackbarAndNavigateBack(context, l10n.label_favorite_saved);
    }
    // CREATE an existing one
    //
    else {
      LocationData? location = await LocationService.instance.location;
      if (location != null) {
        await DatabaseService.instance
            .add(model.Location(lat: location.latitude!, lon: location.longitude!, name: name));
        if (!mounted) return;
        showSnackbarAndNavigateBack(context, l10n.label_favorite_saved);
      } else {
        if (!mounted) return;
        Navigator.pop(context);
      }
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            print(val.recognizedWords);
            setState(() {
              editingController.text = val.recognizedWords;
              if (val.finalResult) {
                // Check if the speech input is complete
                _saveLocation(context); // Call the save method
              }
            });
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(_isUpdate? l10n.location_update_dialog: l10n.location_add_dialog),
        talkback: _isUpdate? l10n.location_update_dialog_t: l10n.location_add_dialog_t,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3, // 2/3 of the screen for the compass
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Semantics(
                label: l10n.location_name_t,
                child: TextFormField(
                  controller: editingController,
                  decoration: InputDecoration(labelText: l10n.location_name),
                  autofocus: !isScreenReaderEnabled,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2, // 1/3 of the screen for the text and buttons
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              double buttonWidth = constraints.maxWidth / 4; // 1/3 of the parent width
              return Container(
                width: double.infinity, // Full width for TalkBack focus
                child: Semantics(
                  button: true, // Explicitly mark as a button
                  label: l10n.location_add_speak_t,
                  child: Align(
                    alignment: Alignment.center,
                    child: BoldIconButton(
                      talkback: "",
                      buttonWidth: buttonWidth,
                      icons: Icons.mic,
                      onTab: _listen,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Der ganze Aufwand mit dem Layout wird nur gemacht, dass der Buttin in der Mitte ist aber das Talkback
          // auch den äusseren Rahmen erfassen kann. Somit kann der User einfach
          // über den Screen rutschen und er findet somit auf Anhieb alle Elemente
          //
          Expanded(
            flex: 2, // 1/3 of the screen for the text and buttons
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              double buttonWidth = constraints.maxWidth / 3; // 1/3 of the parent width
              return Container(
                width: double.infinity, // Full width for TalkBack focus
                child: Semantics(
                  button: true, // Explicitly mark as a button
                  label: l10n!.button_close_t,
                  child: Align(
                    alignment: Alignment.center,
                    child: BoldIconButton(
                      talkback: "",
                      buttonWidth: buttonWidth,
                      icons: Icons.check,
                      onTab: () async {
                        await _saveLocation(context);
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
