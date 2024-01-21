import 'dart:async';

import 'package:candle/models/voicepin.dart';
import 'package:candle/screens/fab.dart';
import 'package:candle/services/database.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class VoicePinsScreen extends StatefulWidget {
  const VoicePinsScreen({super.key});

  @override
  State<VoicePinsScreen> createState() => _ScreenState();
}

class _ScreenState extends State<VoicePinsScreen> implements FloatingActionButtonProvider {
  // the current location of the user given by the GPS signal
  LatLng? _currentLocation;
  bool _isLoading = true;

  List<VoicePin> _voicepins = [];
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLocationChanges().then((value) {
      _load();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

  @override
  Widget floatingActionButton(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return FloatingActionButton(
      onPressed: () async {
        /*
        showLoadingDialog(context);
        try {
          if (mounted == true && _currentLocation != null) {
            var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
            LocationAddress? address = await geo.getGeolocationAddress(_currentLocation!);
            if (!mounted) return;
            Navigator.pop(context); // Close the loading dialog
            if (mounted) {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => LocationCreateUpdateScreen(initialLocation: address),
                ),
              )
                  .then((value) async {
                _load();
              });
            }
          } else {
            if (!mounted) return;
            Navigator.pop(context);
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context);
        }
        */
      },
      tooltip: l10n.screen_header_location_add_t,
      mini: false,
      child: const Icon(Icons.add, size: 50),
    );
  }

  Future<void> _listenToLocationChanges() async {
    _currentLocation = await LocationService.instance.location;

    _locationSubscription = LocationService.instance.listen.handleError((dynamic err) {
      print(err);
    }).listen((newLocation) async {
      var latlng = LatLng(newLocation.latitude, newLocation.longitude);
      // reload the Locations and sort and update them related to the current user location
      //
      if (_currentLocation != null && calculateDistance(latlng, _currentLocation!) > 20) {
        _currentLocation = latlng;
        _load();
      }
    });
  }

  void _load() async {
    try {
      _voicepins = await DatabaseService.instance.allVoicePins();

      // Sort locations by distance to _coord
      if (_currentLocation != null) {
        _voicepins.sort((a, b) {
          var distA = calculateDistance(a.latlng(), _currentLocation!);
          var distB = calculateDistance(b.latlng(), _currentLocation!);
          return distA.compareTo(distB);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_voicepins),
        talkback: l10n.screen_header_voicepins_t,
      ),
      body: BackgroundWidget(
        child: Align(
            alignment: Alignment.topCenter,
            child: _isLoading
                ? _buildLoading(context)
                : _voicepins.isEmpty
                    ? _buildNoLocations(context)
                    : _buildLocations(context)),
      ),
    );
  }

  Widget _buildLocations(BuildContext context) {
    DatabaseService db = DatabaseService.instance;
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return SlidableAutoCloseBehavior(
      closeWhenOpened: true,
      child: ListView.builder(
        itemCount: _voicepins.length,
        itemBuilder: (context, index) {
          VoicePin voicepin = _voicepins[index];

          return Semantics(
              customSemanticsActions: {
                CustomSemanticsAction(label: l10n.button_common_edit_t): () {
                  /*
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (context) => LocationCreateUpdateScreen(
                          initialLocation: loc,
                        ),
                      ))
                      .then((value) => {setState(() => {})});
                  */
                },
                CustomSemanticsAction(label: l10n.button_common_delete_t): () {
                  /*
                  setState(() {
                    db.removeLocation(loc);
                    showSnackbar(context, l10n.location_delete_toast(loc.name));
                  });
                  */
                },
              },
              child: Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
                        db.removeVoicePin(voicepin);
                        _load();
                        if (mounted) {
                          showSnackbar(context, l10n.location_delete_toast(voicepin.name));
                        }
                      },
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.primary,
                      icon: Icons.delete,
                      label: l10n.button_common_delete,
                    ),
                    SlidableAction(
                      onPressed: (context) {
                        /*
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (context) => LocationCreateUpdateScreen(
                            initialLocation: loc,
                          ),
                        ))
                            .then((value) async {
                          _load();
                        });
                        */
                      },
                      backgroundColor: theme.colorScheme.onPrimary,
                      foregroundColor: theme.colorScheme.primary,
                      icon: Icons.edit,
                      label: l10n.button_common_edit,
                    ),
                  ],
                ),
                child: CandleListTile(
                    title: voicepin.name,
                    subtitle: voicepin.memo,
                    onTap: () {
                      /*
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => LatLngCompassScreen(
                          target: loc.latlng(),
                          targetName: loc.name,
                        ),
                      ));
                      */
                    }),
              ));
        },
      ),
    );
  }

  Widget _buildNoLocations(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return ScrollingInfoPage(
      header: l10n.voicepins_placeholder_header,
      body: l10n.voicepins_placeholder_body,
      decoration: Image.asset('assets/images/voicepin.png', fit: BoxFit.cover),
    );
  }

  Widget _buildLoading(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: Text(l10n.label_common_loading),
    );
  }
}