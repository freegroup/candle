import 'package:candle/ui/core/icons/compass.dart';
import 'package:candle/ui/core/icons/poi_favorite.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/about/widgets/about_screen.dart';
import 'package:candle/ui/compass/widgets/compass_screen.dart';
import 'package:candle/ui/home/view_models/home_viewmodel.dart';
import 'package:candle/ui/home/widgets/address_tile.dart';
import 'package:candle/ui/locations/widgets/location_edit_screen.dart';
import 'package:candle/ui/radar/widgets/radar_screen.dart';
import 'package:candle/ui/recording/widgets/recording_screen.dart';
import 'package:candle/ui/wikipedia/widgets/wikipedia_screen.dart';
import 'package:candle/ui/core/utils/dialogs.dart';
import 'package:candle/utils/result.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/tile_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Home screen with its own view model, disposed together with the screen.
Widget buildHomeScreen() => ChangeNotifierProvider(
      create: (context) => HomeViewModel(
        geocodingRepository: context.read(),
        locationService: context.read(),
        settingsRepository: context.read(),
        shareService: context.read(),
      ),
      builder: (context, _) => HomeScreen(viewModel: context.read()),
    );

/// The current address and a tile for each main function.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_home),
        subtitle: Text(l10n.appbar_slogan, style: theme.textTheme.bodyMedium),
        talkback: l10n.screen_header_home_t,
        settingsEnabled: true,
      ),
      body: BackgroundWidget(
        child: SingleChildScrollView(
          child: Column(
            children: [
              AddressTile(viewModel: viewModel),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) => GridView.count(
                    // the page scrolls, not the grid
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [for (final tile in viewModel.tiles) _tile(context, tile)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, HomeTile tile) {
    final l10n = AppLocalizations.of(context)!;
    void open(Widget Function() screen) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen()));

    return switch (tile) {
      HomeTile.compass => TileButton(
          title: l10n.button_compass,
          talkback: l10n.button_compass_t,
          icon: const CompassIcon(rotationDegrees: 30),
          onPressed: () => open(buildCompassScreen),
        ),
      HomeTile.location => TileButton(
          title: l10n.button_location_create,
          talkback: l10n.button_location_create_t,
          icon: const PoiFavoriteIcon(),
          onPressed: () => _saveLocationHere(context),
        ),
      HomeTile.recorder => TileButton(
          title: l10n.button_recording,
          talkback: l10n.button_recording_t,
          icon: const Icon(Icons.route, size: 80),
          onPressed: () => open(buildRecordingScreen),
        ),
      HomeTile.radar => TileButton(
          title: l10n.button_radar,
          talkback: l10n.button_radar_t,
          icon: const Icon(Icons.radar_outlined, size: 80),
          onPressed: () => open(buildRadarScreen),
        ),
      HomeTile.share => TileButton(
          title: l10n.button_share_location,
          talkback: l10n.button_share_location_t,
          icon: const Icon(Icons.share, size: 80),
          onPressed: () => _sharePosition(context),
        ),
      HomeTile.wikipedia => TileButton(
          title: l10n.button_wikipedia,
          talkback: l10n.button_wikipedia_t,
          icon: const Icon(Icons.school, size: 80),
          onPressed: () => open(buildWikipediaScreen),
        ),
      HomeTile.about => TileButton(
          title: l10n.button_about,
          talkback: l10n.button_about_t,
          icon: const Icon(Icons.info, size: 80),
          onPressed: () => open(buildAboutScreen),
        ),
    };
  }

  Future<void> _saveLocationHere(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    showLoadingDialog(context);
    await viewModel.addressHere.execute();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // the loading dialog
    switch (viewModel.addressHere.result) {
      case Ok(:final value):
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => buildLocationEditScreen(value)));
      case _:
        showSnackbar(context, l10n.location_position_unavailable);
    }
  }

  Future<void> _sharePosition(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    showLoadingDialog(context);
    await viewModel.sharePosition.execute((address) =>
        '${l10n.location_share_message(address.lat, address.lon)}\n\n${address.formattedAddress}');
    if (!context.mounted) return;
    Navigator.of(context).pop(); // the loading dialog
    if (viewModel.sharePosition.error) showSnackbar(context, l10n.location_position_unavailable);
  }
}
