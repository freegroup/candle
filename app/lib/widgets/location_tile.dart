import 'package:candle/services/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:candle/utils/shadow.dart';

class LocationAddressTile extends StatelessWidget implements PreferredSizeWidget {
  const LocationAddressTile({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var i10n = AppLocalizations.of(context)!;
    // Use context.watch() to listen to provider changes
    var geoService = context.watch<GeoServiceProvider>();

    // Check if currentAddress is null
    bool isLoading = geoService.currentAddress == null;

    return Semantics(
      label: isLoading
          ? i10n.label_common_loading_t
          : i10n.home_address_t(
              geoService.currentAddress!.street,
              geoService.currentAddress!.number,
              geoService.currentAddress!.city,
            ),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: createShadow(),
            border: Border.all(width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          constraints: const BoxConstraints(minHeight: 150.0),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Icon(Icons.person_pin_circle,
                        size: 90.0, color: theme.textTheme.bodyLarge?.color),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.home_street(
                              geoService.currentAddress!.street,
                              geoService.currentAddress!.number,
                            ),
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            geoService.currentAddress!.city,
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(150);
}
