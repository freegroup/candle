import 'dart:async';
import 'dart:convert';

import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/location_cu.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/poi_provider.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/files.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:candle/widgets/marker_map_osm.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';

class PoiCategoryScreen extends StatefulWidget {
  final PoiCategory category;

  const PoiCategoryScreen({required this.category, super.key});

  @override
  State<PoiCategoryScreen> createState() => _ScreenState();
}

class _ScreenState extends State<PoiCategoryScreen> with SemanticAnnouncer {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceOnShow(widget.category.title);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var mediaQueryData = MediaQuery.of(context);
    bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;

    return isScreenReaderEnabled ? _buildContent(context) : _buildTabbedContent(context);
  }

  Scaffold _buildContent(BuildContext context) {
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
                  : _buildContentList(context),
        ),
      ),
    );
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
        body: TabBarView(
          children: [
            _isLoading
                ? _buildLoading(context)
                : pois!.isEmpty
                    ? _buildNoContent(context)
                    : _buildContentList(context),
            _isLoading
                ? _buildLoading(context)
                : MarkerMapWidget(
                    currentLocation: _currentLocation!,
                    pins: pois!,
                    pinImage: 'assets/images/location_marker.png',
                  ),
          ],
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

  Widget _buildContentList(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        SemanticHeader(
          title: l10n.explore_poi_header,
          talkback: l10n.explore_poi_header_t(pois!.length),
        ),
        Expanded(
          child: SlidableAutoCloseBehavior(
            closeWhenOpened: true,
            child: ListView.builder(
              itemCount: pois!.length,
              itemBuilder: (context, index) {
                var loc = pois![index];

                return Semantics(
                  customSemanticsActions: {
                    CustomSemanticsAction(label: l10n.button_common_edit_t): () async {
                      var locAddress = await loc.toLocationAddress(context);
                      if (context.mounted) {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                              builder: (context) => LocationCreateUpdateScreen(
                                initialLocation: locAddress,
                              ),
                            ))
                            .then((value) => {setState(() => {})});
                      }
                    },
                    CustomSemanticsAction(label: l10n.button_share_location_t): () async {
                      var locAddress = await loc.toLocationAddress(context);
                      String message = "${loc.name}\n\n${loc.formattedAddress}";
                      var dataMap = {
                        "locations": [locAddress.toMap()]
                      };
                      String prettyJson = const JsonEncoder.withIndent('  ').convert(dataMap);
                      final file = await createCandleFileWithData("location", prettyJson);
                      ShareExtend.share(file.path, "file", subject: message);
                    },
                  },
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        CustomSlidableAction(
                          onPressed: (context) async {
                            var locAddress = await loc.toLocationAddress(context);
                            String message = "${locAddress.name}\n\n${locAddress.formattedAddress}";
                            var dataMap = {
                              "locations": [locAddress.toMap()]
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
                          onPressed: (context) async {
                            var locAddress = await loc.toLocationAddress(context);
                            if (context.mounted) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) {
                                  return LocationCreateUpdateScreen(
                                    initialLocation: locAddress,
                                  );
                                },
                              )).then((value) async => _load());
                            }
                          },
                          padding: EdgeInsets.zero,
                          backgroundColor: theme.positiveColor,
                          foregroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.add, size: 35),
                        ),
                      ],
                    ),
                    child: CandleListTile(
                      title: loc.name,
                      subtitle: loc.formattedAddress(l10n),
                      trailing: "${calculateDistance(loc.latlng(), _currentLocation!).toInt()} m",
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => LatLngCompassScreen(
                            target: loc.latlng(),
                            targetName: loc.name,
                          ),
                        ));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
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
            var distA = calculateDistance(a.latlng(), _currentLocation!);
            var distB = calculateDistance(b.latlng(), _currentLocation!);
            return distA.compareTo(distB);
          });
        }
        setState(() {
          _currentLocation = latlng;
        });
      }

      // reload the POI if we fare from the last time we have loaded the poi
      //
      if (_currentLocation != null &&
          _loadingLocation != null &&
          calculateDistance(_currentLocation!, _loadingLocation!) > 500) {
        setState(() => _isLoading = true);
        _load();
      }
    });
  }

  void _load() async {
    try {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      var poiProvider = Provider.of<PoiProvider>(context, listen: false);
      var fetchedPois = await poiProvider.fetchPois(
          l10n, widget.category.categories, kPoiRadiusInMeter, _currentLocation!);
      _loadingLocation = _currentLocation;
      if (mounted) {
        setState(() {
          pois = fetchedPois;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      // Handle error
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
