import 'package:candle/ui/import/view_models/distance_viewmodel.dart';
import 'package:provider/provider.dart';

import 'package:candle/domain/models/location_address.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/locations/widgets/location_edit_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
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
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_import_location_t);
    });
  }


  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (6 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_import_location),
        talkback: l10n.screen_header_import_location_t,
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
            Row(
              children: [
                Icon(Icons.person_pin_circle, size: 90.0, color: theme.textTheme.bodyLarge?.color),
                _buildAddressPane(context),
              ],
            ),
            const SizedBox(height: 30),
            widget.distanceViewModel.distance != null
                ? Text(
                    l10n.location_distance_t(widget.address.name, widget.distanceViewModel.distance!),
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
            label: l10n.button_import_location,
            talkback: l10n.button_import_location_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => buildLocationEditScreen(widget.address),
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
                    targetName: widget.address.name,
                    target: widget.address.latlng(),
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

  Widget _buildAddressPane(BuildContext context) {
    var theme = Theme.of(context);
    AppLocalizations l10n = AppLocalizations.of(context)!;

    // Check if all parts of the address are provided
    bool isCompleteAddressProvided = widget.address.street.isNotEmpty &&
        widget.address.number.isNotEmpty &&
        widget.address.city.isNotEmpty;

    if (isCompleteAddressProvided) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.home_street(widget.address.street, widget.address.number),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              widget.address.city,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            widget.address.formattedAddress,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.left,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

}

/// Import screen for a shared [address] with a view model for the distance to it.
Widget buildImportLocationScreen(LocationAddress address) => ChangeNotifierProvider(
      create: (context) => DistanceViewModel(locationService: context.read(), target: address.latlng()),
      builder: (context, _) => ImportLocationScreen(address: address, distanceViewModel: context.read()),
    );
