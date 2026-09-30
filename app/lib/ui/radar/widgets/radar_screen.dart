import 'dart:async';

import 'package:candle/domain/models/poi.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/ui/explore/widgets/poi_texts.dart';
import 'package:candle/ui/radar/view_models/radar_viewmodel.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/utils/vibrate.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

/// Radar with its own view model, disposed together with the screen.
// TODO(step 5): create the view model in the go_router route instead.
Widget buildRadarScreen() => ChangeNotifierProvider(
      create: (context) => RadarViewModel(
        poiRepository: context.read(),
        locationService: context.read(),
        compassService: context.read(),
      ),
      builder: (context, _) => RadarScreen(viewModel: context.read()),
    );

/// Lists the places in the direction the phone points to. Entering one of the
/// eight compass directions vibrates and announces it with the number of places.
class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key, required this.viewModel, this.vibrate = _vibrate});

  final RadarViewModel viewModel;
  final Future<void> Function() vibrate;

  static Future<void> _vibrate() => CandleVibrate.vibrateCompass(duration: 100);

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SemanticAnnouncer {
  RadarViewModel get _viewModel => widget.viewModel;

  int? _announcedDirection;
  bool _wasTilted = false;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.load.addListener(_onLoadChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceOnShow(AppLocalizations.of(context)!.screen_header_radar_t);
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.load.removeListener(_onLoadChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    final snapped = _viewModel.snappedDirection;
    if (snapped != _announcedDirection) {
      _announcedDirection = snapped;
      if (snapped != null) unawaited(_announceDirection(snapped));
    }

    if (_viewModel.isTilted && !_wasTilted) {
      showSnackbar(context, AppLocalizations.of(context)!.compass_hint_horizontal);
    }
    _wasTilted = _viewModel.isTilted;
  }

  void _onLoadChanged() {
    final load = _viewModel.load;
    if (load.error) {
      unawaited(_announce(AppLocalizations.of(context)!.explore_load_error));
    } else if (load.completed) {
      // announce the places of the current direction again
      _announcedDirection = null;
      _onViewModelChanged();
    }
  }

  Future<void> _announceDirection(int direction) async {
    final l10n = AppLocalizations.of(context)!;
    final horizon = getHorizon(context, direction);
    await widget.vibrate();
    await _announce(_viewModel.load.completed
        ? l10n.locations_in_direction_toast(horizon, _viewModel.poisInDirection.length)
        : horizon);
  }

  Future<void> _announce(String message) async {
    if (!mounted) return;
    await SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_radar),
        talkback: l10n.screen_header_radar_t,
      ),
      body: BackgroundWidget(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListenableBuilder(
            listenable: Listenable.merge([_viewModel, _viewModel.load]),
            builder: (context, _) {
              final load = _viewModel.load;
              if (load.running) return _buildLoading(context);
              if (load.error) return _buildError(context);
              if (_viewModel.poisInDirection.isEmpty) return _buildNoContent(context);
              return _buildPoiList(context);
            },
          ),
        ),
      ),
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
    final pois = _viewModel.poisInDirection;

    return Column(
      children: [
        SemanticHeader(
          title: l10n.explore_poi_header,
          talkback: l10n.explore_poi_header_t(pois.length),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: pois.length,
            itemBuilder: (context, index) {
              final poi = pois[index];
              return CandleListTile(
                title: l10n.poiName(poi),
                subtitle: l10n.poiAddress(poi),
                trailing: '${_viewModel.distanceTo(poi)} m',
                onTap: () => _openCompass(poi),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openCompass(Poi poi) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => LatLngCompassScreen(target: poi.position, targetName: l10n.poiName(poi)),
    )));
  }
}
