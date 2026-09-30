import 'dart:async';
import 'dart:convert';

import 'package:candle/domain/models/poi.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/models/latlng_provider.dart';
import 'package:candle/models/location_address.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/location_cu.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/ui/explore/view_models/poi_category_viewmodel.dart';
import 'package:candle/ui/explore/widgets/poi_texts.dart';
import 'package:candle/utils/files.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:candle/widgets/marker_map_osm.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:latlong2/latlong.dart';

/// Places of one category around the user, as list and map.
///
/// With a screen reader active the map tab is left out: it carries no
/// information that the list does not already announce.
class PoiCategoryScreen extends StatefulWidget {
  const PoiCategoryScreen({super.key, required this.viewModel});

  final PoiCategoryViewModel viewModel;

  @override
  State<PoiCategoryScreen> createState() => _PoiCategoryScreenState();
}

class _PoiCategoryScreenState extends State<PoiCategoryScreen> with SemanticAnnouncer {
  // The screen title is announced ~3 s after opening (see SemanticAnnouncer);
  // result announcements wait for it so they do not cut it off.
  static const _titleAnnouncementDelay = Duration(milliseconds: 3500);
  final _openedAt = DateTime.now();

  PoiCategoryViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.load.addListener(_onLoadChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.poiCategoryTitle(_viewModel.category));
    });
  }

  @override
  void dispose() {
    _viewModel.load.removeListener(_onLoadChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onLoadChanged() {
    final load = _viewModel.load;
    if (load.running) return;
    final l10n = AppLocalizations.of(context)!;
    if (load.error) {
      unawaited(_announce(l10n.explore_load_error));
    } else if (load.completed) {
      final count = _viewModel.pois.length;
      unawaited(_announce(
          count == 0 ? l10n.no_location_for_category : l10n.explore_poi_header_t(count)));
    }
  }

  Future<void> _announce(String message) async {
    final wait = _titleAnnouncementDelay - DateTime.now().difference(_openedAt);
    if (!wait.isNegative) await Future<void>.delayed(wait);
    if (!mounted) return;
    await SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = l10n.poiCategoryTitle(_viewModel.category);
    final screenReader = MediaQuery.of(context).accessibleNavigation;

    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _viewModel.load]),
      builder: (context, _) {
        if (screenReader) {
          return Scaffold(
            appBar: CandleAppBar(title: Text(title), talkback: title),
            body: BackgroundWidget(
              child: Align(alignment: Alignment.topCenter, child: _buildList(context)),
            ),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: CandleAppBar(
              title: Text(title),
              talkback: title,
              settingsEnabled: true,
              bottom: _buildTabBar(context),
            ),
            body: TabBarView(children: [_buildList(context), _buildMap(context)]),
          ),
        );
      },
    );
  }

  TabBar _buildTabBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return TabBar(
      tabs: [Tab(text: l10n.label_common_list), Tab(text: l10n.label_common_map)],
      dividerColor: theme.primaryColor,
      labelColor: theme.primaryColor,
      unselectedLabelColor: theme.primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final load = _viewModel.load;
    if (load.running) return _buildLoading(context);
    if (load.error) return _buildError(context);
    if (_viewModel.pois.isEmpty) return _buildNoContent(context);
    return _buildPoiList(context);
  }

  Widget _buildMap(BuildContext context) {
    final location = _viewModel.location;
    if (_viewModel.load.running || location == null) return _buildLoading(context);
    return MarkerMapWidget(
      currentLocation: location,
      pins: [for (final poi in _viewModel.pois) _PoiPin(poi)],
      pinImage: 'assets/images/location_marker.png',
    );
  }

  Widget _buildLoading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.label_common_loading_t,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNoContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GenericInfoPage(
      header: l10n.no_location_for_category,
      body: '',
      decoration: Icon(Icons.not_listed_location, color: Theme.of(context).primaryColor, size: 160),
    );
  }

  Widget _buildError(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: GenericInfoPage(
            header: l10n.explore_load_error,
            body: '',
            decoration: Icon(Icons.cloud_off, color: theme.primaryColor, size: 160),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Semantics(
            button: true,
            label: l10n.button_common_retry_t,
            excludeSemantics: true,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              onPressed: _viewModel.load.execute,
              icon: const Icon(Icons.refresh, size: 32),
              label: Text(l10n.button_common_retry, style: theme.textTheme.headlineSmall),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoiList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pois = _viewModel.pois;

    return Column(
      children: [
        SemanticHeader(
          title: l10n.explore_poi_header,
          talkback: l10n.explore_poi_header_t(pois.length),
        ),
        Expanded(
          child: SlidableAutoCloseBehavior(
            child: ListView.builder(
              itemCount: pois.length,
              itemBuilder: (context, index) {
                final poi = pois[index];
                return Semantics(
                  customSemanticsActions: {
                    CustomSemanticsAction(label: l10n.button_common_edit_t): () =>
                        _addToLocations(poi),
                    CustomSemanticsAction(label: l10n.button_share_location_t): () =>
                        _share(poi),
                  },
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        CustomSlidableAction(
                          onPressed: (_) => _share(poi),
                          padding: EdgeInsets.zero,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          child: const Icon(Icons.share, size: 35),
                        ),
                        CustomSlidableAction(
                          onPressed: (_) => _addToLocations(poi),
                          padding: EdgeInsets.zero,
                          backgroundColor: theme.positiveColor,
                          foregroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.add, size: 35),
                        ),
                      ],
                    ),
                    child: CandleListTile(
                      title: l10n.poiName(poi),
                      subtitle: l10n.poiAddress(poi),
                      trailing: '${_viewModel.distanceTo(poi)} m',
                      onTap: () => _openCompass(poi),
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

  Future<LocationAddress> _toLocationAddress(Poi poi) {
    final l10n = AppLocalizations.of(context)!;
    return _viewModel.toLocationAddress(
      poi,
      name: l10n.poiName(poi),
      formattedAddress: l10n.poiAddress(poi),
    );
  }

  void _openCompass(Poi poi) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => LatLngCompassScreen(target: poi.position, targetName: l10n.poiName(poi)),
    ));
  }

  Future<void> _addToLocations(Poi poi) async {
    final address = await _toLocationAddress(poi);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => LocationCreateUpdateScreen(initialLocation: address),
    ));
  }

  Future<void> _share(Poi poi) async {
    final address = await _toLocationAddress(poi);
    final json = const JsonEncoder.withIndent('  ').convert({
      'locations': [address.toMap()],
    });
    final file = await createCandleFileWithData('location', json);
    await shareFile(file, subject: '${address.name}\n\n${address.formattedAddress}');
  }
}

/// Adapter for the (legacy) map widget.
class _PoiPin implements LatLngProvider {
  _PoiPin(this.poi);

  final Poi poi;

  @override
  LatLng latlng() => poi.position;
}
