import 'dart:async';
import 'dart:convert';

import 'package:candle/models/location_address.dart' as model;
import 'package:candle/models/location_address.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/location_cu.dart';
import 'package:candle/services/database.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/utils/dialogs.dart';
import 'package:candle/utils/files.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:candle/widgets/marker_map_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LocationsScreen> with SemanticAnnouncer {
  // the current location of the user given by the GPS signal
  LatLng? _currentLocation;
  bool _isLoading = true;

  List<LocationAddress> _locations = [];
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLocationChanges().then((value) {
      _load();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_locations_t);
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
      _locations = await DatabaseService.instance.allLocations();

      // Sort locations by distance to _coord
      if (_currentLocation != null) {
        _locations.sort((a, b) {
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
    var mediaQueryData = MediaQuery.of(context);
    bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;

    return isScreenReaderEnabled ? _buildContent(context) : _buildTabbedContent(context);
  }

  Widget _buildTabbedContent(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CandleAppBar(
          title: Text(l10n.screen_header_voicepins),
          talkback: l10n.screen_header_voicepins_t,
          settingsEnabled: true,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.label_common_list),
              Tab(text: l10n.label_common_map),
            ],
            dividerColor: theme.primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(context),
        body: TabBarView(
          children: [
            _isLoading
                ? _buildLoading(context)
                : _locations.isEmpty
                    ? _buildNoContent(context)
                    : _buildContentList(context),
            _isLoading
                ? _buildLoading(context)
                : MarkerMapWidget(
                    currentLocation: _currentLocation!,
                    pins: _locations,
                    pinImage: 'assets/images/location_marker.png',
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_locations),
        talkback: l10n.screen_header_locations_t,
        settingsEnabled: true,
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      body: BackgroundWidget(
        child: Align(
            alignment: Alignment.topCenter,
            child: _isLoading
                ? _buildLoading(context)
                : _locations.isEmpty
                    ? _buildNoContent(context)
                    : _buildContentList(context)),
      ),
    );
  }

  Widget _buildContentList(BuildContext context) {
    DatabaseService db = DatabaseService.instance;
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return SlidableAutoCloseBehavior(
      closeWhenOpened: true,
      child: ListView.builder(
        itemCount: _locations.length,
        itemBuilder: (context, index) {
          model.LocationAddress loc = _locations[index];

          return Semantics(
            customSemanticsActions: {
              CustomSemanticsAction(label: l10n.button_common_edit_t): () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (context) => LocationCreateUpdateScreen(
                        initialLocation: loc,
                      ),
                    ))
                    .then((value) => {setState(() => {})});
              },
              CustomSemanticsAction(label: l10n.button_share_location_t): () async {
                String message = "${loc.name}\n\n${loc.formattedAddress}";
                var dataMap = {
                  "locations": [loc.copyWith(id: () => null).toMap()]
                };
                String prettyJson = const JsonEncoder.withIndent('  ').convert(dataMap);
                final file = await createCandleFileWithData("location", prettyJson);
                ShareExtend.share(file.path, "file", subject: message);
              },
              CustomSemanticsAction(label: l10n.button_common_delete_t): () {
                setState(() {
                  db.removeLocation(loc);
                  showSnackbar(context, l10n.location_deleted_toast(loc.name));
                });
              },
            },
            child: Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  CustomSlidableAction(
                    onPressed: (context) async {
                      db.removeLocation(loc);
                      _load();
                      if (mounted) showSnackbar(context, l10n.location_deleted_toast(loc.name));
                    },
                    padding: EdgeInsets.zero,
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.delete, size: 35),
                  ),
                  CustomSlidableAction(
                    onPressed: (context) async {
                      String message = "${loc.name}\n\n${loc.formattedAddress}";
                      var dataMap = {
                        "locations": [loc.copyWith(id: () => null).toMap()]
                      };
                      String prettyJson = const JsonEncoder.withIndent('  ').convert(dataMap);
                      final file = await createCandleFileWithData("location", prettyJson);
                      ShareExtend.share(file.path, "file", subject: message);
                    },
                    padding: EdgeInsets.zero,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: const Icon(Icons.share, size: 35),
                  ),
                  CustomSlidableAction(
                    onPressed: (context) {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (context) => LocationCreateUpdateScreen(
                          initialLocation: loc,
                        ),
                      ))
                          .then((value) async {
                        _load();
                      });
                    },
                    padding: EdgeInsets.zero,
                    backgroundColor: theme.positiveColor,
                    foregroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.edit, size: 35),
                  ),
                ],
              ),
              child: CandleListTile(
                title: loc.name,
                subtitle: loc.formattedAddress,
                trailing: "${calculateDistance(loc.latlng(), _currentLocation!).toInt()} m",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LatLngCompassScreen(
                        target: loc.latlng(),
                        targetName: loc.name,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoContent(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return GenericInfoPage(
      header: l10n.locations_placeholder_header,
      body: l10n.locations_placeholder_body,
    );
  }

  Widget _buildLoading(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: Text(l10n.label_common_loading),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return FloatingActionButton(
      onPressed: () async {
        showLoadingDialog(context);
        try {
          if (mounted == true && _currentLocation != null) {
            var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
            LocationAddress? address = await geo.getGeolocationAddress(_currentLocation!);
            if (!mounted || address == null) return;

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
      },
      tooltip: l10n.screen_header_location_add_t,
      mini: false,
      child: const Icon(Icons.add, size: 50),
    );
  }
}
