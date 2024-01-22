import 'dart:async';

import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/poi_provider.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';

import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class PoiCategoryScreen extends StatefulWidget {
  final PoiCategory category;

  const PoiCategoryScreen({required this.category, super.key});

  @override
  State<PoiCategoryScreen> createState() => _ScreenState();
}

class _ScreenState extends State<PoiCategoryScreen> {
  List<PoiDetail>? pois;
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
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

  Future<void> _listenToLocationChanges() async {
    _currentLocation = await LocationService.instance.location;

    _locationSubscription = LocationService.instance.listen.handleError((dynamic err) {
      print(err);
    }).listen((newLocation) async {
      var latlng = LatLng(newLocation.latitude, newLocation.longitude);

      // Update the view for each new location position we get
      if (mounted) {
        // resort the locations based on the new location of the user
        //
        if (_currentLocation != null && pois != null) {
          pois!.sort((a, b) {
            var distA = calculateDistance(a.latlng, _currentLocation!);
            var distB = calculateDistance(b.latlng, _currentLocation!);
            return distA.compareTo(distB);
          });
        }
        setState(() {
          _currentLocation = latlng;
        });
      }

      // reload the POI if we fare from the last time we have loaded the poi
      //
      if (calculateDistance(_currentLocation!, _loadingLocation!) > 500) {
        setState(() => _isLoading = true);
        _load();
      }
    });
  }

  void _load() async {
    try {
      var poiProvider = Provider.of<PoiProvider>(context, listen: false);
      var fetchedPois =
          await poiProvider.fetchPois(widget.category.categories, 2000, _currentLocation!);
      _loadingLocation = _currentLocation;
      if (mounted) {
        setState(() {
          pois = fetchedPois;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CandleAppBar(
        title: Text(widget.category.title),
        talkback: widget.category.title,
      ),
      body: BackgroundWidget(
        child: Align(
          alignment: Alignment.topCenter,
          child: _isLoading
              ? _buildLoading(context)
              : pois == null || pois!.isEmpty
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
          talkback: l10n.explore_poi_header_t(pois!.length),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: pois!.length,
            itemBuilder: (context, index) {
              var loc = pois![index];

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
