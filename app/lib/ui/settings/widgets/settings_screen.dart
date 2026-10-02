import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/settings/view_models/settings_viewmodel.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Settings screen with its own view model, disposed together with the screen.
Widget buildSettingsScreen() => ChangeNotifierProvider(
      create: (context) => SettingsViewModel(settingsRepository: context.read()),
      builder: (context, _) => SettingsScreen(viewModel: context.read()),
    );

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SemanticAnnouncer {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceOnShow(AppLocalizations.of(context)!.screen_header_settings_t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.button_settings),
        talkback: l10n.button_settings_t,
      ),
      body: BackgroundWidget(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(l10n.settings_header_tiles, l10n.settings_header_tiles_t),
                    ...widget.viewModel.tiles.map(_toggle),
                    const SizedBox(height: 40),
                    _header(l10n.settings_header_common, l10n.settings_header_common_t),
                    ...widget.viewModel.common.map(_toggle),
                    const SizedBox(height: 40),
                    _header(l10n.settings_header_beta, l10n.settings_header_beta_t),
                    ...widget.viewModel.beta.map(_toggle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String text, String talkback) => Semantics(
        header: true,
        label: talkback,
        child: ExcludeSemantics(
          child: Text(text, style: Theme.of(context).textTheme.headlineLarge),
        ),
      );

  Widget _toggle(Setting setting) => SwitchListTile(
        title: Text(_title(setting), style: Theme.of(context).textTheme.labelLarge),
        value: widget.viewModel.isEnabled(setting),
        onChanged: (value) => widget.viewModel.setEnabled(setting, value),
      );

  String _title(Setting setting) {
    final l10n = AppLocalizations.of(context)!;
    return switch (setting) {
      Setting.dictationInput => l10n.featureflag_dictation,
      Setting.overviewRecorder => l10n.featureflag_recorder,
      Setting.overviewRadar => l10n.featureflag_radar,
      Setting.overviewCompass => l10n.featureflag_compass,
      Setting.overviewLocation => l10n.featureflag_location,
      Setting.overviewShare => l10n.featureflag_share,
      Setting.overviewWikipedia => l10n.featureflag_wikipedia,
      Setting.vibrateDuringNavigation => l10n.featureflag_vibraterouting,
      Setting.vibrateCompass => l10n.featureflag_vibratecompass,
      Setting.betaRecording => l10n.featureflag_beta_recording,
      Setting.shortTalkback => l10n.featureflag_short_talkback,
    };
  }
}
