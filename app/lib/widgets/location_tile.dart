import 'dart:async';

import 'package:candle/icons/routing.dart';
import 'package:candle/models/location_address.dart' as model;
import 'package:candle/models/location_address.dart';
import 'package:candle/screens/address_search.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/utils/shadow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class LocationAddressTile extends StatefulWidget implements PreferredSizeWidget {
  const LocationAddressTile({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(280);

  @override
  State<LocationAddressTile> createState() => _WidgetState();
}

class _WidgetState extends State<LocationAddressTile> {
  model.LocationAddress? _lastReadAddress;
  LatLng _currentLocation = const LatLng(0, 0);
  bool _currentAddressOutdated = true;
  bool _lastGeoCodingFailed = false;
  StreamSubscription<Position>? _locationStream;
  final StreamController<LocationAddress> _addressController = StreamController<LocationAddress>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    _addressController.close();
    super.dispose();
  }

  Future<void> _initialize() async {
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

    _addressController.stream.listen((address) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LatLngCompassScreen(
            target: address.latlng(),
            targetName: address.name,
          ),
        ),
      );
    });
  }

  Future<void> _updateLocationAddress() async {
    if (mounted) {
      setState(() => _lastGeoCodingFailed = false);
    }

    // do nothing if we do not have any new location
    if (_currentAddressOutdated == false) {
      return;
    }

    // force loading indicator
    _lastReadAddress = null;
    if (mounted) setState(() {});

    // fetch the address
    var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
    final newAddress = await geo.getGeolocationAddress(_currentLocation);

    if (mounted) {
      if (newAddress != null) {
        _lastReadAddress = newAddress;
        _currentAddressOutdated = false;
        _lastGeoCodingFailed = false;
      } else {
        _lastGeoCodingFailed = true;
        _lastReadAddress = null;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    bool isLoading = _lastReadAddress == null;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: createShadow(),
        border: Border.all(width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: _lastGeoCodingFailed
            ? _buildErrorContent(context)
            : isLoading
                ? _buildLoadingContent(context)
                : _buildContent(context),
      ),
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorContent(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make the column fit its content size
        children: [
          Text(
            l10n.label_address_load_fail,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _updateLocationAddress(),
            icon: const Icon(Icons.refresh, size: 24), // Reload icon
            label: Text(l10n.button_address_reload),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      children: [
        const RoutingIcon(height: 160),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStartContent(context),
              const SizedBox(height: 40),
              _buildDestinationContent(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartContent(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    var theme = Theme.of(context);

    var talkback = l10n.label_common_loading_t;
    if (_lastReadAddress != null) {
      if (_currentAddressOutdated) {
        talkback = l10n.last_known_address_t(
          _lastReadAddress!.street,
          _lastReadAddress!.number,
          _lastReadAddress!.city,
        );
      } else {
        talkback = l10n.current_address_t(
          _lastReadAddress!.street,
          _lastReadAddress!.number,
          _lastReadAddress!.city,
        );
      }
    }

    return Semantics(
      label: talkback,
      button: _currentAddressOutdated,
      child: GestureDetector(
        onTap: _updateLocationAddress,
        child: ExcludeSemantics(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              // Using Container to make the text take up full width
              Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.home_street(
                        _lastReadAddress!.street,
                        _lastReadAddress!.number,
                      ),
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _lastReadAddress!.city,
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_currentAddressOutdated)
                Positioned(
                  right: 0,
                  child: Icon(
                    Icons.refresh,
                    color: theme.primaryColor,
                    size: 35.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationContent(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    var theme = Theme.of(context);

    return TextButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AddressSearchScreen(
            sink: _addressController.sink,
            addressFragment: "",
          ),
        ));
      },
      style: ButtonStyle(
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(
              color: theme.primaryColor,
              width: 1.0,
            ),
          ),
        ),
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 60)),
      ),
      child: Text(
        l10n.button_common_enter_target,
        style: theme.textTheme.titleLarge,
      ),
    );
  }
}
