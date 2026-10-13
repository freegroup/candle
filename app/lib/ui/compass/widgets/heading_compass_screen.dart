import 'dart:async';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/data/services/tts/tts.dart';
import 'package:candle/ui/core/icons/compass.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/compass/view_models/heading_compass_viewmodel.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
import 'package:candle/ui/core/widgets/twoliner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Compass screen with its own view model, disposed together with the screen.
Widget buildHeadingCompassScreen() => ChangeNotifierProvider(
      create: (context) => HeadingCompassViewModel(compassService: context.read()),
      builder: (context, _) => HeadingCompassScreen(
        viewModel: context.read(),
      ),
    );

/// Shows where north is. Entering one of the eight compass directions vibrates
/// and announces it.
class HeadingCompassScreen extends StatefulWidget {
  const HeadingCompassScreen({
    super.key,
    required this.viewModel,
  });

  final HeadingCompassViewModel viewModel;

  @override
  State<HeadingCompassScreen> createState() => _HeadingCompassScreenState();
}

class _HeadingCompassScreenState extends State<HeadingCompassScreen> with SemanticAnnouncer {
  HeadingCompassViewModel get _viewModel => widget.viewModel;

  int? _announcedDirection;
  bool _wasTilted = false;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!isOnTop) return;
    final snapped = _viewModel.snappedDirection;
    if (snapped != _announcedDirection) {
      _announcedDirection = snapped;
      if (snapped != null) unawaited(_announce(snapped));
    }
    if (_viewModel.isTilted && !_wasTilted) {
      showSnackbar(context, AppLocalizations.of(context)!.compass_hint_horizontal);
    }
    _wasTilted = _viewModel.isTilted;
  }

  // Vibrates, unless the user turned the vibration of the compass off in the settings.
  Future<void> _pulse({required int duration}) async {
    final settings = context.read<SettingsRepository>();
    if (settings.isEnabled(Setting.vibrateCompass)) {
      await VibrationService.pulse(duration: duration);
    }
  }

  Future<void> _announce(int direction) async {
    // so the announcement of an old direction is not read to the end
    await TTS.interrupt();
    if (!mounted) return;
    unawaited(_pulse(duration: 100));
    await TTS.say(getHorizon(context, direction));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_compass),
        talkback: l10n.screen_header_compass_t,
      ),
      body: BackgroundWidget(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => DividedWidget(
            fraction: screenHeight * (6 / 9),
            top: _buildCompass(context),
            bottom: _buildBottomPane(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCompass(BuildContext context) {
    final heading = _viewModel.heading;
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * 0.7;
          return Semantics(
            label: sayHorizon(context, heading),
            child: CompassIcon(
              shadow: true,
              rotationDegrees: 360 - heading,
              height: width,
              width: width,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final heading = _viewModel.heading;

    return Column(children: [
      TwolinerWidget(
        color: _viewModel.isTilted ? theme.negativeColor : theme.primaryColor,
        headline: '$heading°',
        headlineTalkback: '$heading°',
        subtitle: getHorizon(context, heading),
        subtitleTalkback: getHorizon(context, heading),
      ),
      DialogButton(
        label: l10n.button_common_close,
        talkback: l10n.button_common_close_t,
        onTab: () => Navigator.pop(context),
      ),
    ]);
  }
}
