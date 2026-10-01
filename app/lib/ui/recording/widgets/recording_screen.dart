import 'dart:async';
import 'dart:io';

import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/data/services/screen/screen_wake_service.dart';
import 'package:candle/ui/recording/view_models/recording_viewmodel.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/accessible_text_input.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/bold_icon_button.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
import 'package:candle/ui/core/widgets/pulse_icon.dart';
import 'package:candle/ui/core/widgets/route_map_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

/// Recording screen with its own view model, disposed together with the screen.
Widget buildRecordingScreen() => ChangeNotifierProvider(
      create: (context) => RecordingViewModel(
        recordingRepository: context.read(),
        routeRepository: context.read(),
        compassService: context.read(),
        permissionService: context.read(),
      ),
      builder: (context, _) => RecordingScreen(viewModel: context.read()),
    );

/// Names and starts a route recording; while recording it shows the route on
/// a map and lets the user save or discard it.
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key, required this.viewModel});

  final RecordingViewModel viewModel;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with SemanticAnnouncer {
  final _nameController = TextEditingController();
  bool _keepsScreenOn = false;

  RecordingViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_updateScreenWake);
    _viewModel.start.addListener(_onStartChanged);
    _updateScreenWake();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_updateScreenWake);
    _viewModel.start.removeListener(_onStartChanged);
    if (_keepsScreenOn) ScreenWakeService.keepOn(false);
    _nameController.dispose();
    super.dispose();
  }

  /// iOS stops location updates when the screen locks, so it stays on while recording.
  void _updateScreenWake() {
    final keepOn = Platform.isIOS && _viewModel.isRecording;
    if (keepOn != _keepsScreenOn) {
      _keepsScreenOn = keepOn;
      ScreenWakeService.keepOn(keepOn);
    }
  }

  void _onStartChanged() {
    final l10n = AppLocalizations.of(context)!;
    if (_viewModel.start.error) {
      _viewModel.start.clearResult();
      showSnackbar(context, l10n.recording_start_failed);
    } else if (_viewModel.start.completed) {
      _viewModel.start.clearResult();
      unawaited(SemanticsService.sendAnnouncement(
          View.of(context), l10n.recording_started_t, Directionality.of(context)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final recording = _viewModel.isRecording;
        return Scaffold(
          appBar: CandleAppBar(
            title: Text(recording
                ? l10n.screen_header_recorder_recording
                : l10n.screen_header_recorder_start),
            talkback: recording
                ? l10n.screen_header_recorder_recording_t
                : l10n.screen_header_recorder_start_t,
          ),
          body: BackgroundWidget(
            child: DividedWidget(
              fraction: screenHeight * (7 / 9),
              top: recording ? _buildMap(context) : _buildNameInput(context),
              bottom: recording ? _buildStopButtons(context) : _buildStartButton(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameInput(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageWidth = MediaQuery.of(context).size.width * (2 / 7);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AccessibleTextInput(
              controller: _nameController,
              hintText: l10n.route_name,
              mandatory: true,
              // The name is all this screen asks for. Without a screen reader the
              // keyboard opens at once; with one, the focus would cut off the
              // announcement of the screen. "Done" on the keyboard starts the
              // recording, so the keyboard never has to be closed by hand.
              autofocus: !MediaQuery.of(context).accessibleNavigation,
              onSubmitted: (_) => _start(),
              talkbackInput: l10n.route_name_t,
              talkbackIcon: l10n.route_add_speak_t,
            ),
            const SizedBox(height: 50),
            MarkdownBody(data: l10n.route_recording_intro),
            const SizedBox(height: 50),
            SizedBox(
              width: imageWidth,
              child: Image.asset('assets/images/recording_splash.png', fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DialogButton(
      label: l10n.button_recording,
      talkback: l10n.button_recording_t,
      onTab: _start,
    );
  }

  void _start() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnackbar(context, l10n.route_name_required_snackbar);
      return;
    }
    _viewModel.start.execute((
      name,
      (title: l10n.recording_notification_title, text: l10n.recording_notification_text),
    ));
  }

  Widget _buildMap(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final route = _viewModel.route;

    if (route == null || route.points.isEmpty) {
      return Semantics(
        label: l10n.label_common_loading_t,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Stack(
      children: [
        RouteMapWidget(
          route: route,
          mapRotation: -_viewModel.heading,
          currentLocation: route.points.last.latlng(),
        ),
        const Positioned(top: 10, right: 10, child: PulsingRecordIcon()),
      ],
    );
  }

  Widget _buildStopButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: BoldIconButton(
            talkback: l10n.button_discard_recording_t,
            buttonWidth: 50,
            icons: Icons.close_outlined,
            onTab: () => _viewModel.stop.execute(false),
          ),
        ),
        Expanded(
          child: BoldIconButton(
            talkback: l10n.button_save_recording_t,
            buttonWidth: 120,
            icons: Icons.label_important_outline,
            circle: false,
            onTab: () async {
              await _viewModel.stop.execute(true);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
