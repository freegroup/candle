import 'package:candle/ui/import/view_models/distance_viewmodel.dart';
import 'package:provider/provider.dart';

import 'package:candle/domain/models/voicepin.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/voicepins/widgets/voicepin_edit_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:candle/l10n/gen/app_localizations.dart';

class ImportVoicepinScreen extends StatefulWidget {
  final VoicePin voicepin;

  const ImportVoicepinScreen({required this.voicepin, required this.distanceViewModel, super.key});

  final DistanceViewModel distanceViewModel;

  @override
  State<ImportVoicepinScreen> createState() => _ScreenState();
}

class _ScreenState extends State<ImportVoicepinScreen> with SemanticAnnouncer {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_import_voicepin_t);
    });
  }



  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (6 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_import_voicepin),
        talkback: l10n.screen_header_import_voicepin_t,
      ),
      body: BackgroundWidget(
        child: ListenableBuilder(
          listenable: widget.distanceViewModel,
          builder: (context, _) => DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(context),
          bottom: _buildBottomPane(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPane(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.voicepin.memo,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 30),
            widget.distanceViewModel.distance != null
                ? Text(
                    l10n.voicepin_distance_t(widget.distanceViewModel.distance!),
                    style: theme.textTheme.labelLarge,
                  )
                : _buildLoading(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        DialogButton(
            label: l10n.button_import_voicepin,
            talkback: l10n.button_import_voicepin_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => buildVoicePinEditScreen(widget.voicepin),
                ),
              );
            }),
        DialogButton(
            label: l10n.button_compass,
            talkback: l10n.button_compass_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => buildTargetCompassScreen(
                    targetName: widget.voicepin.name,
                    target: widget.voicepin.latlng(),
                  ),
                ),
              );
            }),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: Text(l10n.label_common_loading),
    );
  }
}

/// Import screen for a shared [voicepin] with a view model for the distance to it.
Widget buildImportVoicepinScreen(VoicePin voicepin) => ChangeNotifierProvider(
      create: (context) => DistanceViewModel(locationService: context.read(), target: voicepin.latlng()),
      builder: (context, _) => ImportVoicepinScreen(voicepin: voicepin, distanceViewModel: context.read()),
    );
