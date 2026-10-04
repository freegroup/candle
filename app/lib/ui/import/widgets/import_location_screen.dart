import 'package:candle/ui/import/view_models/distance_viewmodel.dart';
import 'package:provider/provider.dart';

import 'package:candle/domain/models/location_address.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/locations/widgets/location_edit_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/twoliner.dart';
import 'package:flutter/material.dart';
import 'package:candle/l10n/gen/app_localizations.dart';

class ImportLocationScreen extends StatefulWidget {
  final LocationAddress address;

  const ImportLocationScreen({required this.address, required this.distanceViewModel, super.key});

  final DistanceViewModel distanceViewModel;

  @override
  State<ImportLocationScreen> createState() => _ScreenState();
}

class _ScreenState extends State<ImportLocationScreen> with SemanticAnnouncer {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceOnShow(AppLocalizations.of(context)!.screen_header_import_location_t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = widget.address;
    final complete = a.street.isNotEmpty && a.number.isNotEmpty && a.city.isNotEmpty;
    final address = complete ? '${l10n.home_street(a.street, a.number)}\n${a.city}' : a.formattedAddress;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_import_location),
        talkback: l10n.screen_header_import_location_t,
      ),
      body: BackgroundWidget(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.distanceViewModel,
            builder: (context, _) {
              final distance = widget.distanceViewModel.distance;
              final loading = distance == null;
              return Column(
                children: [
                  // same big headline + distance line as the compass pane
                  TwolinerWidget(
                    headline: address,
                    headlineTalkback: a.formattedAddress,
                    subtitle: loading ? l10n.label_common_loading : '$distance Meter',
                    subtitleTalkback:
                        loading ? l10n.label_common_loading_t : l10n.location_distance_t(a.name, distance),
                  ),
                  DialogButton(
                    label: l10n.button_import_location,
                    talkback: l10n.button_import_location_t,
                    onTab: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(builder: (_) => buildLocationEditScreen(a)),
                    ),
                  ),
                  DialogButton(
                    label: l10n.button_compass,
                    talkback: l10n.button_compass_t,
                    outlined: true,
                    onTab: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => buildTargetCompassScreen(targetName: a.name, target: a.latlng()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Import screen for a shared [address] with a view model for the distance to it.
Widget buildImportLocationScreen(LocationAddress address) => ChangeNotifierProvider(
      create: (context) => DistanceViewModel(locationService: context.read(), target: address.latlng()),
      builder: (context, _) => ImportLocationScreen(address: address, distanceViewModel: context.read()),
    );
