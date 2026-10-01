import 'package:candle/domain/models/location_address.dart';
import 'package:candle/ui/core/icons/routing.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/home/view_models/home_viewmodel.dart';
import 'package:candle/ui/locations/widgets/address_search_screen.dart';
import 'package:candle/ui/core/utils/shadow.dart';
import 'package:flutter/material.dart';

/// Where the user is, and a button to enter a destination.
class AddressTile extends StatelessWidget {
  const AddressTile({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.refreshAddress]),
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: createShadow(),
          border: Border.all(width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: viewModel.address == null
              ? (viewModel.refreshAddress.error
                  ? _buildError(context)
                  : const Center(child: CircularProgressIndicator()))
              : Row(
                  children: [
                    const RoutingIcon(height: 160),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAddress(context, viewModel.address!),
                          const SizedBox(height: 40),
                          _buildDestinationButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.label_address_load_fail,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: viewModel.refreshAddress.execute,
            icon: const Icon(Icons.refresh, size: 24),
            label: Text(l10n.button_address_reload),
          ),
        ],
      ),
    );
  }

  Widget _buildAddress(BuildContext context, LocationAddress address) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outdated = viewModel.addressOutdated;

    return Semantics(
      label: outdated
          ? l10n.last_known_address_t(address.street, address.number, address.city)
          : l10n.current_address_t(address.street, address.number, address.city),
      button: outdated,
      excludeSemantics: true,
      onTap: viewModel.refreshAddress.execute,
      child: GestureDetector(
        onTap: viewModel.refreshAddress.execute,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.home_street(address.street, address.number),
                      style: theme.textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                  Text(address.city,
                      style: theme.textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (outdated)
              Positioned(
                right: 0,
                child: Icon(Icons.refresh, color: theme.primaryColor, size: 35.0),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return TextButton(
      onPressed: () async {
        final navigator = Navigator.of(context);
        final destination = await navigator
            .push<LocationAddress>(MaterialPageRoute(builder: (_) => buildAddressSearchScreen()));
        if (destination == null) return;
        await navigator.push(MaterialPageRoute<void>(
          builder: (_) =>
              buildTargetCompassScreen(target: destination.latlng(), targetName: destination.name),
        ));
      },
      style: ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: theme.primaryColor, width: 1.0),
        )),
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 60)),
      ),
      child: Text(l10n.button_common_enter_target, style: theme.textTheme.titleLarge),
    );
  }
}
