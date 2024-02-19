import 'dart:async';

import 'package:candle/models/location_address.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/location_cu.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/dialog_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ImportLocationScreen extends StatefulWidget {
  final LocationAddress address;

  const ImportLocationScreen({required this.address, super.key});

  @override
  State<ImportLocationScreen> createState() => _ScreenState();
}

class _ScreenState extends State<ImportLocationScreen> with SemanticAnnouncer {
  LatLng? _currentLocation;
  double? _distance;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLocationChanges();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_import_location_t);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (6 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_import_location),
        talkback: l10n.screen_header_import_location_t,
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
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin_circle, size: 90.0, color: theme.textTheme.bodyLarge?.color),
                _buildAddressPane(context),
              ],
            ),
            const SizedBox(height: 30),
            _distance != null
                ? Text(
                    l10n.location_distance_t(widget.address.name, _distance!.toInt()),
                    style: theme.textTheme.labelLarge,
                  )
                : _buildLoading(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        DialogButton(
            label: l10n.button_import_location,
            talkback: l10n.button_import_location_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LocationCreateUpdateScreen(
                    initialLocation: widget.address,
                  ),
                ),
              );
            }),
        DialogButton(
            label: l10n.button_compass,
            talkback: l10n.button_compass_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LatLngCompassScreen(
                    targetName: widget.address.name,
                    target: widget.address.latlng(),
                  ),
                ),
              );
            }),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: Text(l10n.label_common_loading),
    );
  }

  Widget _buildAddressPane(BuildContext context) {
    var theme = Theme.of(context);
    AppLocalizations l10n = AppLocalizations.of(context)!;

    // Check if all parts of the address are provided
    bool isCompleteAddressProvided = widget.address.street.isNotEmpty &&
        widget.address.number.isNotEmpty &&
        widget.address.city.isNotEmpty;

    if (isCompleteAddressProvided) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.home_street(widget.address.street, widget.address.number),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              widget.address.city,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            widget.address.formattedAddress,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.left,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  Future<void> _listenToLocationChanges() async {
    _currentLocation = await LocationService.instance.location;
    if (_currentLocation != null && mounted) {
      setState(() {
        _distance = calculateDistance(widget.address.latlng(), _currentLocation!);
      });
    }
    _locationSubscription = LocationService.instance.listen.handleError((dynamic err) {
      print(err);
    }).listen((newLocation) async {
      var latlng = LatLng(newLocation.latitude, newLocation.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = latlng;
          _distance = calculateDistance(widget.address.latlng(), _currentLocation!);
        });
      }
    });
  }
}
