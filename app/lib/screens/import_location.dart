import 'package:candle/models/location_address.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/dialog_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImportLocationScreen extends StatefulWidget {
  final LocationAddress address;

  const ImportLocationScreen({required this.address, super.key});

  @override
  State<ImportLocationScreen> createState() => _ScreenState();
}

class _ScreenState extends State<ImportLocationScreen> {
  @override
  void dispose() {
    super.dispose();
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
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(context),
          bottom: _buildBottomPane(context),
        ),
      ),
    );
  }

  Widget _buildTopPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = screenWidth * (2 / 7);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: imageWidth,
              child: Image.asset('assets/images/recording_splash.png', fit: BoxFit.cover),
            ),
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
              showSnackbar(context, l10n.route_name_required_snackbar);
            }),
        DialogButton(
            label: l10n.button_compass,
            talkback: l10n.button_compass_t,
            onTab: () {
              showSnackbar(context, l10n.route_name_required_snackbar);
            }),
      ],
    );
  }
}
