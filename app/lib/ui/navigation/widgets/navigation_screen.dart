import 'dart:async';

import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart' as model;
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/data/services/screen/screen_wake_service.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/navigation/view_models/navigation_viewmodel.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
import 'package:candle/ui/core/widgets/route_map_osm.dart';
import 'package:candle/ui/core/widgets/target_reached.dart';
import 'package:candle/ui/core/widgets/turn_by_turn.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Navigation from [source] to [target] with its own view model; follows
/// [route] if given, otherwise a calculated walking route.
Widget buildNavigationScreen({required LatLng source, required LatLng target, model.Route? route}) =>
    ChangeNotifierProvider(
      create: (context) => NavigationViewModel(
        routingRepository: context.read(),
        locationNoteRepository: context.read(),
        locationNoteAnnouncer: context.read(),
        locationService: context.read(),
        compassService: context.read(),
        source: source,
        target: target,
        route: route,
      ),
      builder: (context, _) => NavigationScreen(
        viewModel: context.read(),
        vibrate: ({int duration = 100, int repeat = -1}) =>
            context.read<VibrationService>().navigation(duration: duration, repeat: repeat),
      ),
    );

/// Turn-by-turn guidance: vibrates when the phone points to the next waypoint
/// and when a waypoint is passed. Location notes on the way are shown by the app shell.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key, required this.viewModel, required this.vibrate});

  final NavigationViewModel viewModel;
  final Future<void> Function({int duration, int repeat}) vibrate;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with SemanticAnnouncer {
  NavigationViewModel get _viewModel => widget.viewModel;

  bool _wasAligned = false;
  NavigationPoint? _lastWaypoint;

  @override
  void initState() {
    super.initState();
    ScreenWakeService.keepOn(true);
    _viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    ScreenWakeService.keepOn(false);
    _viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!isOnTop) return;
    final aligned = _viewModel.isAligned;
    if (aligned != _wasAligned) {
      _wasAligned = aligned;
      unawaited(aligned ? widget.vibrate(repeat: 2) : widget.vibrate(duration: 500));
    }
    final waypoint = _viewModel.headingWaypoint;
    if (waypoint != _lastWaypoint) {
      _lastWaypoint = waypoint;
      unawaited(widget.vibrate());
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_navigation_poi),
        talkback: l10n.screen_header_navigation_poi_t,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => MergeSemantics(
          // read by the screen reader after the instruction, a moment later
          child: Semantics(
            hint: l10n.navigation_announcement_hint,
            child: DividedWidget(
              fraction: screenHeight * (6 / 9),
              top: _buildMap(context),
              bottom: _buildInstruction(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    final route = _viewModel.route;
    if (route == null) {
      return _viewModel.routeFailed
          ? Center(child: Text(AppLocalizations.of(context)!.navigation_route_failed))
          : const Center(child: CircularProgressIndicator());
    }
    return ExcludeSemantics(
      child: RouteMapWidget(
        route: route,
        mapRotation: -_viewModel.deviceHeading.toDouble(),
        currentLocation: _viewModel.position,
        currentWaypoint: _viewModel.headingWaypoint?.latlng(),
        marker1: _viewModel.turnWaypoint?.latlng(),
        marker2: _viewModel.nextTurnWaypoint?.latlng(),
        marker: _viewModel.locationNotes,
      ),
    );
  }

  Widget _buildInstruction(BuildContext context) {
    final aligned = _viewModel.isAligned;
    // The background is a layer of its own: changing the color of the text
    // widgets would make the screen reader read them out again.
    return Stack(
      children: [
        Container(
          color: aligned ? Theme.of(context).positiveColor : null,
          height: double.infinity,
          width: double.infinity,
        ),
        _viewModel.targetReached
            ? const TargetReachedWidget()
            : TurnByTurnInstructionWidget(
                currentCoord: _viewModel.position,
                waypoint1: _viewModel.headingWaypoint,
                waypoint2: _viewModel.turnWaypoint,
                isAligned: aligned,
                bearing: _viewModel.needleHeading,
              ),
      ],
    );
  }
}
