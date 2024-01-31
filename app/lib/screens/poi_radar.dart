import 'dart:async';

import 'package:candle/l10n/helper.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/services/compass.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/poi_provider.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/utils/vibrate.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';

import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class PoiRadarScreen extends StatefulWidget {
  final PoiCategory category = PoiCategory(
    icon: Icons.local_drink,
    title: "",
    categories: [
      'node["amenity"="bar"]',
      'node["amenity"="nightclub"]',
      'node["amenity"="atm"]',
      'node["amenity"="payment"]',
      'node["amenity"="bank"]',
      'node["amenity"="restaurant"]',
      'node["amenity"="hospital"]',
      'node["amenity"="cafe"]',
      'node["amenity"="bus_station"]',
      'node["amenity"="station"]',
      'node["highway"="bus_stop"]',
      'node["amenity"="taxi"]',
      'node["amenity"="pharmacy"]',
      'node["amenity"="traffic_signals"]',
      'node["amenity"="toilet"]'
    ],
  );
  PoiRadarScreen({super.key});

  @override
  State<PoiRadarScreen> createState() => _ScreenState();
}

class _ScreenState extends State<PoiRadarScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  int _currentHeadingDegrees = 0;
  bool _isCompassHorizontal = true;
  Timer? _horizontalCheckTimer;

  // managmenet vars to check if the phone is tilled and can not show correct
  // the compass information
  //
  static const int _kConsecutiveDuration = 3; // seconds
  int _consecutiveHorizontalFalseCount = 0;
  int _consecutiveHorizontalTrueCount = 0;
  bool _canShowSnackbar = true;

  // vibration and announcement handling
  //
  int? _lastVibratedSnapPoint;

  // Poi Data
  //
  List<PoiDetail>? _allPois;
  List<PoiDetail>? _poisInHeadingDirection;
  bool _isLoading = true;
  LatLng? _currentLocation;
  LatLng? _loadingLocation;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLocationChanges().then((value) {
      _load();
    });
    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        print(err);
      }).listen((compassEvent) {
        int heading = ((360 - (compassEvent.heading ?? 0)) % 360).toInt();
        if (mounted) setState(() => _currentHeadingDegrees = heading);
        _filterPoisAtSnapPoints();
      });

      _horizontalCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        bool newIsHorizontal = CompassService.instance.isHorizontal;
        if (mounted) {
          if (_isCompassHorizontal != newIsHorizontal) {
            setState(() {
              _isCompassHorizontal = newIsHorizontal;
            });
          }

          _checkCompassOrientation(newIsHorizontal);
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    _horizontalCheckTimer?.cancel();
  }

  void _filterPoisAtSnapPoints() {
    const snapPoints = [0, 45, 90, 135, 180, 225, 270, 315];
    const snapRange = 10; // ±10° range for snap points

    for (var snapPointAngle in snapPoints) {
      if ((_currentHeadingDegrees >= snapPointAngle - snapRange) &&
          (_currentHeadingDegrees <= snapPointAngle + snapRange)) {
        if (_lastVibratedSnapPoint != snapPointAngle) {
          CandleVibrate.vibrateCompass(duration: 100);
          _lastVibratedSnapPoint = snapPointAngle;

          if (_allPois != null) {
            const int angleRange = 25; // ±25° range
            List<PoiDetail> filteredPois = [];
            for (var poi in _allPois!) {
              int bearing = 360 - calculateNorthBearing(_currentLocation!, poi.latlng);
              if ((bearing >= snapPointAngle - angleRange) &&
                  (bearing <= snapPointAngle + angleRange)) {
                filteredPois.add(poi);
              }
            }

            // Sort by distance
            filteredPois.sort((a, b) {
              var distA = calculateDistance(a.latlng, _currentLocation!);
              var distB = calculateDistance(b.latlng, _currentLocation!);
              return distA.compareTo(distB);
            });

            // Update the POIs in heading direction
            if (mounted) {
              AppLocalizations l10n = AppLocalizations.of(context)!;
              setState(() => _poisInHeadingDirection = filteredPois);
              SemanticsService.announce(
                  l10n.locations_in_direction_toast(
                      getHorizon(context, _currentHeadingDegrees), filteredPois.length),
                  TextDirection.ltr);
            }
          } else {
            SemanticsService.announce(
                getHorizon(context, _currentHeadingDegrees), TextDirection.ltr);
          }

          break; // Vibrate once and exit loop
        }
      } else if (_lastVibratedSnapPoint == snapPointAngle) {
        // Clear the last vibrated point if we move out of the snap range
        _lastVibratedSnapPoint = null;
      }
    }
  }

  void _checkCompassOrientation(bool isHorizontal) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    if (isHorizontal) {
      _consecutiveHorizontalTrueCount++;
      _consecutiveHorizontalFalseCount = 0;

      if (_consecutiveHorizontalTrueCount >= _kConsecutiveDuration) {
        // Erlaubt die Snackbar-Anzeige, nachdem fünf aufeinanderfolgende "true" erreicht wurden
        _canShowSnackbar = true;
        _consecutiveHorizontalTrueCount = 0;
      }
    } else {
      _consecutiveHorizontalFalseCount++;
      _consecutiveHorizontalTrueCount = 0;

      if (_consecutiveHorizontalFalseCount >= _kConsecutiveDuration && _canShowSnackbar) {
        showSnackbar(context, l10n.compass_hint_horizontal);
        _consecutiveHorizontalFalseCount = 0;
        // Verhindert weitere Snackbar-Anzeigen, bis wieder fünf "true" erreicht wurden
        _canShowSnackbar = false;
      }
    }
  }

  Future<void> _listenToLocationChanges() async {
    _currentLocation = await LocationService.instance.location;

    _locationSubscription = LocationService.instance.listen.handleError((dynamic err) {
      print(err);
    }).listen((newLocation) async {
      var latlng = LatLng(newLocation.latitude, newLocation.longitude);
      if (mounted) setState(() => _currentLocation = latlng);

      // Update the view for each new location position we get
      if (mounted && _currentLocation != null && _loadingLocation != null) {
        // reload the POI if we fare from the last time we have loaded the poi
        //
        if (calculateDistance(_currentLocation!, _loadingLocation!) > 500) {
          setState(() => _isLoading = true);
          _load();
        }
      }
    });
  }

  void _load() async {
    try {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      var poiProvider = Provider.of<PoiProvider>(context, listen: false);
      _allPois = await poiProvider.fetchPois(
          l10n, widget.category.categories, kPoiRadiusInMeter, _currentLocation!);
      _loadingLocation = _currentLocation;
      if (mounted) {
        _lastVibratedSnapPoint = null;
        _filterPoisAtSnapPoints();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Handle error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_radar),
        talkback: l10n.screen_header_radar_t,
      ),
      body: BackgroundWidget(
        child: Align(
          alignment: Alignment.topCenter,
          child: _isLoading
              ? _buildLoading(context)
              : _poisInHeadingDirection == null || _poisInHeadingDirection!.isEmpty
                  ? _buildNoContent(context)
                  : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNoContent(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return GenericInfoPage(
      header: l10n.no_location_for_category,
      body: "",
      decoration: Icon(
        Icons.not_listed_location,
        color: theme.primaryColor,
        size: 160,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SemanticHeader(
          title: l10n.explore_poi_header,
          talkback: l10n.explore_poi_header_t(_poisInHeadingDirection!.length),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _poisInHeadingDirection!.length,
            itemBuilder: (context, index) {
              var loc = _poisInHeadingDirection![index];

              return CandleListTile(
                title: loc.name,
                subtitle: loc.formattedAddress(context),
                trailing: "${calculateDistance(loc.latlng, _currentLocation!).toInt()} m",
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => LatLngCompassScreen(
                      target: loc.latlng,
                      targetName: loc.name,
                    ),
                  ));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
