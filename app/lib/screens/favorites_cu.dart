import 'dart:async';

import 'package:candle/models/location_address.dart';
import 'package:candle/screens/address_search.dart';
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
import 'package:provider/provider.dart';

class FavoriteCreateUpdateScreen extends StatefulWidget {
  final model.LocationAddress? initialLocation;

  const FavoriteCreateUpdateScreen({super.key, this.initialLocation});

  @override
  State<FavoriteCreateUpdateScreen> createState() => _ScreenState();
}

class _ScreenState extends State<FavoriteCreateUpdateScreen> {
  TextEditingController editingController = TextEditingController();
  final StreamController<LocationAddress> _addressController = StreamController<LocationAddress>();

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
    _addressController.stream.listen((address) {
      // Update the state with the selected address
      setState(() {
        address.id = stateLocation?.id;
        stateLocation = address;
      });
    });
  }

  @override
  void dispose() {
    _addressController.close();
    super.dispose();
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
          address = address.copyWith(name: name);
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

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(_isUpdate ? l10n.location_update_dialog : l10n.location_add_dialog),
        talkback: _isUpdate ? l10n.location_update_dialog_t : l10n.location_add_dialog_t,
      ),
      body: Column(
        children: [
          Padding(
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddressSearchScreen(
                  sink: _addressController.sink,
                  addressFragment: stateLocation?.formattedAddress,
                ),
              ));
            },
            child: AbsorbPointer(
              // Prevents the TextField from gaining focus
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: TextField(
                  controller: TextEditingController(text: stateLocation?.formattedAddress),
                  decoration: InputDecoration(
                    labelText: 'Address',
                    // Add other decoration properties if needed
                  ),
                  maxLines: null, // Allows for multiline input
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(), // This acts as a filler
          ),
          BoldIconButton(
            talkback: l10n.button_close_t,
            buttonWidth: MediaQuery.of(context).size.width / 4,
            icons: Icons.check,
            onTab: () async {
              await _saveLocation(context);
            },
          ),
          BoldIconButton(
            talkback: l10n.button_close,
            buttonWidth: MediaQuery.of(context).size.width / 6,
            icons: Icons.close,
            onTab: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
