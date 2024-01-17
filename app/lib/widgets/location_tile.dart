import 'dart:async';

import 'package:candle/models/location_address.dart' as model;
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/utils/shadow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class LocationAddressTile extends StatefulWidget implements PreferredSizeWidget {
  const LocationAddressTile({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(150);

  @override
  State<LocationAddressTile> createState() => _WidgetState();
}

class _WidgetState extends State<LocationAddressTile> {
  model.LocationAddress? _lastReadAddress;
  LatLng _currentLocation = const LatLng(0, 0);
  bool _currentAddressOutdated = true;
  StreamSubscription<Position>? _locationStream;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _locationStream?.cancel();

    super.dispose();
  }

  void _initialize() async {
    LatLng? initialCoord = await LocationService.instance.location;
    if (initialCoord != const LatLng(0, 0)) {
      _currentLocation = initialCoord!;
      _updateLocationAddress();
    }

    LocationService.instance.listen.handleError((dynamic err) {
      log.e(err);
    }).listen((newLocation) async {
      _currentLocation = LatLng(newLocation.latitude, newLocation.longitude);

      // The address is only outdated if we have already read one and if the differnece
      // of the position is at least 10 meters.
      //
      if (_lastReadAddress != null) {
        _currentAddressOutdated =
            calculateDistance(_lastReadAddress!.latlng(), _currentLocation) > 10;
      }

      if (mounted) setState(() {});
    });
  }

  Future<void> _updateLocationAddress() async {
    // do nothing if we do not have any new location
    if (_currentAddressOutdated == false) {
      return;
    }

    // force loading indicator
    _lastReadAddress = null;
    if (mounted) setState(() {});

    // fetch the address
    var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
    log.d("UPDATE ADDRESS........$geo");
    final newAddress = await geo.getGeolocationAddress(_currentLocation);
    if (newAddress != null) {
      _lastReadAddress = newAddress;
      _currentAddressOutdated = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var i10n = AppLocalizations.of(context)!;

    // Check if currentAddress is null
    bool isLoading = _lastReadAddress == null;

    var talkback = i10n.label_common_loading_t;
    if (_lastReadAddress != null) {
      if (_currentAddressOutdated) {
        talkback = i10n.last_known_address_t(
          _lastReadAddress!.street,
          _lastReadAddress!.number,
          _lastReadAddress!.city,
        );
      } else {
        talkback = i10n.current_address_t(
          _lastReadAddress!.street,
          _lastReadAddress!.number,
          _lastReadAddress!.city,
        );
      }
    }

    return Semantics(
      label: talkback,
      button: _currentAddressOutdated,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: _updateLocationAddress,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: createShadow(),
                  border: Border.all(width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                constraints: const BoxConstraints(minHeight: 150.0),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          Icon(Icons.person_pin_circle,
                              size: 90.0, color: theme.textTheme.bodyLarge?.color),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.home_street(
                                    _lastReadAddress!.street,
                                    _lastReadAddress!.number,
                                  ),
                                  style: theme.textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  _lastReadAddress!.city,
                                  style: theme.textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              // Pull to Refresh Icon
              if (_currentAddressOutdated)
                Positioned(
                  right: 16.0,
                  bottom: 16.0,
                  child: Icon(
                    Icons.refresh, // Pull to Refresh Icon
                    color: theme.primaryColor,
                    size: 24.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
