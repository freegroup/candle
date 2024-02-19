import 'package:candle/screens/permissions_screen_allwaysgps.dart';
import 'package:candle/utils/featureflag.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SemanticAnnouncer {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_settings_t);
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: AppFeatures.featuresUpdateNotifier,
      builder: (context, _, __) {
        List<Widget?> unfilteredChildren = [
          Semantics(
            label: l10n.settings_header_tiles_t,
            child: Text(l10n.settings_header_tiles, style: theme.textTheme.headlineLarge),
          ),
          _buildFeatureFlagToggle(AppFeatures.overviewCompass),
          _buildFeatureFlagToggle(AppFeatures.overviewLocation),
          _buildFeatureFlagToggle(AppFeatures.overviewRadar),
          AppFeatures.betaRecording.isEnabled
              ? _buildFeatureFlagToggle(AppFeatures.overviewRecorder)
              : null,
          _buildFeatureFlagToggle(AppFeatures.overviewShare),
          const SizedBox(height: 40),
          Semantics(
            label: l10n.settings_header_gps_t,
            child: Text(l10n.settings_header_gps, style: theme.textTheme.headlineLarge),
          ),
          _buildFeatureFlagToggle(AppFeatures.allwaysAccessGps),
          const SizedBox(height: 40),
          Semantics(
            label: l10n.settings_header_common_t,
            child: Text(l10n.settings_header_common, style: theme.textTheme.headlineLarge),
          ),
          AppFeatures.dictationInput.isConfigurable
              ? _buildFeatureFlagToggle(AppFeatures.dictationInput)
              : null,
          _buildFeatureFlagToggle(AppFeatures.vibrateCompass),
          _buildFeatureFlagToggle(AppFeatures.vibrateDuringNavigation),
          const SizedBox(height: 40),
          Semantics(
            label: l10n.settings_header_beta_t,
            child: Text(l10n.settings_header_beta, style: theme.textTheme.headlineLarge),
          ),
          _buildFeatureFlagToggle(AppFeatures.betaRecording),
        ];

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
                    children: unfilteredChildren
                        .where((widget) => widget != null)
                        .cast<Widget>()
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureFlagToggle(FeatureFlag featureFlag) {
    ThemeData theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: featureFlag.isEnabledListenable,
      builder: (context, isEnabled, _) {
        if (!featureFlag.isConfigurable) {
          return const SizedBox.shrink();
        }
        return SwitchListTile(
            title: Text(
              _getFeatureFlagTitle(context, featureFlag.userStateKey),
              style: theme.textTheme.labelLarge,
            ), // Customize the title as needed
            value: isEnabled,
            onChanged: (newValue) {
              _handleAllwaysGPSPermissions(newValue, featureFlag);
            });
      },
    );
  }

  String _getFeatureFlagTitle(BuildContext context, String userStateKey) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    // Implement logic to return a human-readable title for each feature flag
    // For example, you might use a switch statement or a map
    switch (userStateKey) {
      case 'dictationInput':
        return l10n.featureflag_dictation;
      case 'overviewRecorder':
        return l10n.featureflag_recorder;
      case 'overviewRadar':
        return l10n.featureflag_radar;
      case 'overviewCompass':
        return l10n.featureflag_compass;
      case 'overviewLocation':
        return l10n.featureflag_location;
      case 'overviewShare':
        return l10n.featureflag_share;
      case 'allwaysAccessGps':
        return l10n.featureflag_allwaysgps;
      case 'vibrateDuringNavigation':
        return l10n.featureflag_vibraterouting;
      case 'vibrateCompass':
        return l10n.featureflag_vibratecompass;
      case 'betaRecording':
        return l10n.featureflag_beta_recording;

      default:
        return 'Unknown Feature';
    }
  }

  Future<void> _handleAllwaysGPSPermissions(bool newValue, FeatureFlag featureFlag) async {
    if (featureFlag != AppFeatures.allwaysAccessGps) {
      featureFlag.setEnabled(newValue);
      return;
    }

    if (await Permission.locationAlways.isGranted) {
      featureFlag.setEnabled(newValue);
      return;
    }

    // Request permissions
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const PermissionsAllwaysGPSScreen(),
      ));
    }
  }
}
