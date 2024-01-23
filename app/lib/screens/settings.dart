import 'package:candle/utils/featureflag.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.buttonbar_home, style: theme.textTheme.headlineLarge),
                  _buildFeatureFlagToggle(AppFeatures.overviewCompass),
                  _buildFeatureFlagToggle(AppFeatures.overviewLocation),
                  _buildFeatureFlagToggle(AppFeatures.overviewRecorder),
                  _buildFeatureFlagToggle(AppFeatures.overviewShare),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureFlagToggle(FeatureFlag featureFlag) {
    ThemeData theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: featureFlag.isEnabledListenable,
      builder: (context, isEnabled, _) {
        return Visibility(
          visible: featureFlag.isConfigurable,
          child: SwitchListTile(
            title: Text(
              _getFeatureFlagTitle(context, featureFlag.userStateKey),
              style: theme.textTheme.labelLarge,
            ), // Customize the title as needed
            value: isEnabled,
            onChanged:
                featureFlag.isConfigurable ? (newValue) => featureFlag.setEnabled(newValue) : null,
          ),
        );
      },
    );
  }

  String _getFeatureFlagTitle(BuildContext context, String userStateKey) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    // Implement logic to return a human-readable title for each feature flag
    // For example, you might use a switch statement or a map
    switch (userStateKey) {
      case 'overview_recorder':
        return l10n.featureflag_recorder;
      case 'overview_compass':
        return l10n.featureflag_compass;
      case 'overview_location':
        return l10n.featureflag_location;
      case 'overview_share':
        return l10n.featureflag_share;

      default:
        return 'Unknown Feature';
    }
  }
}
