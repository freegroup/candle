import 'dart:async';

import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/domain/models/route.dart' as model;
import 'package:candle/ui/core/icons/location_arrow.dart';
import 'package:candle/ui/core/icons/location_dot.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/data/services/screen/screen_wake_service.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/compass/view_models/compass_viewmodel.dart';
import 'package:candle/ui/navigation/widgets/navigation_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
import 'package:candle/ui/core/widgets/twoliner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

/// Compass to [target] with its own view model; [route] is followed when the
/// user starts the navigation from here.
Widget buildTargetCompassScreen({
  required LatLng target,
  required String targetName,
  model.Route? route,
}) =>
    ChangeNotifierProvider(
      create: (context) => TargetCompassViewModel(
        compassService: context.read(),
        locationService: context.read(),
        target: target,
        targetName: targetName,
      ),
      builder: (context, _) => TargetCompassScreen(
        viewModel: context.read(),
        route: route,
        vibrate: ({int duration = 100, int repeat = -1}) =>
            context.read<VibrationService>().compass(duration: duration, repeat: repeat),
      ),
    );

/// Points to a target and tells its distance. Pointing the phone at the target
/// vibrates every few seconds; every eighth of a turn the direction is announced.
class TargetCompassScreen extends StatefulWidget {
  const TargetCompassScreen({
    super.key,
    required this.viewModel,
    required this.vibrate,
    this.route,
  });

  final TargetCompassViewModel viewModel;
  final model.Route? route;
  final Future<void> Function({int duration, int repeat}) vibrate;

  @override
  State<TargetCompassScreen> createState() => _TargetCompassScreenState();
}

class _TargetCompassScreenState extends State<TargetCompassScreen> with SemanticAnnouncer {
  TargetCompassViewModel get _viewModel => widget.viewModel;

  int? _announcedDirection;
  bool _wasAligned = false;
  Timer? _alignedTimer;

  @override
  void initState() {
    super.initState();
    ScreenWakeService.keepOn(true);
    _viewModel.addListener(_onChanged);
    // A steady reminder while the phone points to the target.
    _alignedTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_viewModel.isAligned) unawaited(widget.vibrate());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceOnShow(
          AppLocalizations.of(context)!.screen_header_compass_poi_t(_viewModel.targetName));
    });
  }

  @override
  void dispose() {
    ScreenWakeService.keepOn(false);
    _viewModel.removeListener(_onChanged);
    _alignedTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    final aligned = _viewModel.isAligned;
    if (aligned != _wasAligned) {
      _wasAligned = aligned;
      unawaited(aligned ? widget.vibrate(repeat: 2) : widget.vibrate(duration: 500));
    }
    final snapped = _viewModel.snappedDirection;
    if (snapped != _announcedDirection) {
      _announcedDirection = snapped;
      if (snapped != null) unawaited(_announce());
    }
  }

  Future<void> _announce() async {
    await widget.vibrate();
    if (!mounted) return;
    await SemanticsService.sendAnnouncement(
      View.of(context),
      sayRotateToTarget(
          context, _viewModel.targetHeading, _viewModel.isAligned, _viewModel.distance),
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_compass_poi),
        talkback: l10n.screen_header_compass_poi_t(_viewModel.targetName),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => DividedWidget(
          fraction: screenHeight * (6 / 9),
          top: _buildArrow(context),
          bottom: _buildBottomPane(context),
        ),
      ),
    );
  }

  Widget _buildArrow(BuildContext context) {
    final heading = _viewModel.targetHeading;
    final aligned = _viewModel.isAligned;
    return Semantics(
      label: sayRotateToTarget(context, heading, aligned, _viewModel.distance),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * 0.7;
            return Stack(
              alignment: Alignment.center,
              children: [
                LocationArrowIcon(
                  shadow: true,
                  rotationDegrees: aligned ? 0 : 360 - heading,
                  height: width,
                  width: width,
                ),
                LocationDotIcon(shadow: false, height: width, width: width),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final distance = _viewModel.distance;

    return Stack(
      children: [
        Container(
          color: _viewModel.isAligned ? theme.positiveColor : null,
          height: double.infinity,
          width: double.infinity,
        ),
        Column(
          children: [
            TwolinerWidget(
              headline: _viewModel.targetName,
              headlineTalkback: l10n.location_distance_t(_viewModel.targetName, distance),
              subtitle: '$distance Meter',
              subtitleTalkback: '$distance Meter',
            ),
            DialogButton(
              label: l10n.button_navigate_poi,
              talkback: l10n.button_navigate_poi_t,
              onTab: _navigate,
            ),
          ],
        ),
      ],
    );
  }

  void _navigate() {
    final position = _viewModel.position;
    if (position == null) {
      showSnackbar(context, AppLocalizations.of(context)!.location_position_unavailable);
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) =>
          buildNavigationScreen(source: position, target: _viewModel.target, route: widget.route),
    ));
  }
}
