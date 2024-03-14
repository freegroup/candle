import 'dart:async';

import 'package:candle/models/article_ref.dart';
import 'package:candle/models/article_summary.dart';
import 'package:candle/screens/wikipedia_article.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/wikipedia.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:candle/widgets/marker_map_osm.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class WikipediaScreen extends StatefulWidget {
  const WikipediaScreen({super.key});

  @override
  State<WikipediaScreen> createState() => _ScreenState();
}

class _ScreenState extends State<WikipediaScreen> with SemanticAnnouncer {
  // the current location of the user given by the GPS signal
  LatLng? _currentLocation;
  bool _isLoading = true;
  List<ArticleRef> _articles = [];
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_wikipedia_t);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

  Future<void> _initListeners() async {
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
    _load();
  }

  void _load() async {
    try {
      // Sort locations by distance to _coord
      if (_currentLocation != null) {
        _articles = await WikipediaService.search(context: context, location: _currentLocation!);
        _articles.sort((a, b) {
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
          title: Text(l10n.screen_header_wikipedia),
          talkback: l10n.screen_header_wikipedia_t,
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
                : _articles.isEmpty
                    ? _buildNoContent(context)
                    : _buildContentList(context),
            _isLoading
                ? _buildLoading(context)
                : MarkerMapWidget(
                    currentLocation: _currentLocation!,
                    pins: _articles,
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
        title: Text(l10n.screen_header_wikipedia),
        talkback: l10n.screen_header_wikipedia_t,
        settingsEnabled: true,
      ),
      body: BackgroundWidget(
        child: Align(
            alignment: Alignment.topCenter,
            child: _isLoading
                ? _buildLoading(context)
                : _articles.isEmpty
                    ? _buildNoContent(context)
                    : _buildContentList(context)),
      ),
    );
  }

  Widget _buildContentList(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return SlidableAutoCloseBehavior(
      closeWhenOpened: true,
      child: ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          ArticleRef loc = _articles[index];

          return Semantics(
            customSemanticsActions: {
              CustomSemanticsAction(label: l10n.button_common_edit_t): () {},
            },
            child: Slidable(
              endActionPane: const ActionPane(
                motion: ScrollMotion(),
                children: [],
              ),
              child: CandleListTile(
                title: loc.title,
                maxLines: 2,
                trailing: "${calculateDistance(loc.latlng(), _currentLocation!).toInt()} m",
                onTap: () async {
                  ArticleSummary? summary =
                      await WikipediaService.getSummary(context: context, ref: loc);
                  if (context.mounted && summary != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ArticleSummaryScreen(summary: summary);
                        },
                      ),
                    );
                  }
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use min to wrap content by size
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(l10n.label_common_loading_t),
          ],
        ),
      ),
    );
  }
}
