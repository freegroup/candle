import 'package:candle/services/database.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:candle/models/location_address.dart' as model;
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/accessible_text_input.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class FavoriteCreateUpdateScreen extends StatefulWidget {
  final model.LocationAddress? initialLocation;

  const FavoriteCreateUpdateScreen({super.key, this.initialLocation});

  @override
  State<FavoriteCreateUpdateScreen> createState() => _ScreenState();
}

class _ScreenState extends State<FavoriteCreateUpdateScreen> {
  TextEditingController editingController = TextEditingController();

  bool _isUpdate = false;
  model.LocationAddress? stateLocation;

  @override
  void initState() {
    super.initState();
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
      model.LocationAddress updatedLocation = stateLocation!.copyWith(name: name);
      await DatabaseService.instance.update(updatedLocation);
      if (!mounted) return;
      showSnackbarAndNavigateBack(context, l10n.label_favorite_saved);
    }

    // CREATE an existing one
    //
    else {
      LatLng? location = await LocationService.instance.location;
      if (location != null) {
        var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
        var address = await geo.getGeolocationAddress(location);
        if (address != null) {
          address = address!.copyWith(name: name);
          await DatabaseService.instance.add(address);
          if (!mounted) return;
          showSnackbarAndNavigateBack(context, l10n.label_favorite_saved);
        }
      } else {
        if (!mounted) return;
        Navigator.pop(context);
      }
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
        title: Text(_isUpdate ? l10n.location_update_dialog : l10n.location_add_dialog),
        talkback: _isUpdate ? l10n.location_update_dialog_t : l10n.location_add_dialog_t,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2, // 2/3 of the screen for the compass
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: AccessibleTextInput(
                maxLines: 1,
                talkbackInput: l10n.location_name_t,
                talkbackIcon: l10n.location_add_speak_t,
                controller: editingController,
                decoration: InputDecoration(labelText: l10n.location_name),
                autofocus: !isScreenReaderEnabled,
              ),
            ),
          ),

          InkWell(
            onTap: () => {},
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              child: Text(
                stateLocation != null ? stateLocation!.name : 'Tap to select address',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          const Spacer(),

          // Der ganze Aufwand mit dem Layout wird nur gemacht, dass der Buttin in der Mitte ist aber das Talkback
          // auch den äusseren Rahmen erfassen kann. Somit kann der User einfach
          // über den Screen rutschen und er findet somit auf Anhieb alle Elemente
          //
          Expanded(
            flex: 1, // 1/3 of the screen for the text and buttons
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              double buttonWidth = constraints.maxWidth / 4; // 1/3 of the parent width
              return Container(
                width: double.infinity, // Full width for TalkBack focus
                child: Semantics(
                  button: true, // Explicitly mark as a button
                  label: l10n.button_close_t,
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

          Expanded(
            flex: 1, // 1/3 of the screen for the text and buttons
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              double buttonWidth = constraints.maxWidth / 6; // 1/3 of the parent width
              return Container(
                width: double.infinity, // Full width for TalkBack focus
                child: Semantics(
                  button: true, // Explicitly mark as a button
                  label: l10n.button_close,
                  child: Align(
                    alignment: Alignment.center,
                    child: BoldIconButton(
                      talkback: "",
                      buttonWidth: buttonWidth,
                      icons: Icons.close,
                      onTab: () => {Navigator.pop(context)},
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
