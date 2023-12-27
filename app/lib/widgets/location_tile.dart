import 'package:candle/services/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:candle/utils/shadow.dart';

class LocationAddressTile extends StatelessWidget {
  const LocationAddressTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access the provider
    var geoService = Provider.of<GeoServiceProvider>(context);

    return Semantics(
      label: AppLocalizations.of(context)!.home_address_t(
        geoService.currentAddress?.street ?? "",
        geoService.currentAddress?.number ?? "",
        geoService.currentAddress?.city ?? "",
      ),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: createShadow(),
            border: Border.all(width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          constraints: const BoxConstraints(minHeight: 150.0),
          child: Row(
            children: [
              Icon(Icons.location_pin,
                  size: 90.0, color: Theme.of(context).textTheme.bodyLarge?.color),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.home_street(
                        geoService.currentAddress?.street ?? "",
                        geoService.currentAddress?.number ?? "",
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      geoService.currentAddress?.city ?? "",
                      style: Theme.of(context).textTheme.titleLarge,
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
}
