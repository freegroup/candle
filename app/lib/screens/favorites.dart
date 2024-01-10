import 'package:candle/models/location_address.dart';
import 'package:candle/screens/favorites_cu.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/services/database.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/dialogs.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/favorites_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:candle/models/location_address.dart' as model;
import 'package:provider/provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int? selectedItemIndex;

  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService.instance;
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: CandleAppBar(
          title: Text(AppLocalizations.of(context)!.favorite_mainmenu),
          talkback: AppLocalizations.of(context)!.favorite_mainmenu_t,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            showLoadingDialog(context);
            try {
              var coord = await LocationService.instance.location;
              if (coord != null) {
                var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
                LocationAddress? address = await geo.getGeolocationAddress(coord);
                if (!mounted) return;
                Navigator.pop(context); // Close the loading dialog
                if (mounted) {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => FavoriteCreateUpdateScreen(
                            initialLocation: address,
                          ),
                        ),
                      )
                      .then((value) => setState(() {}));
                }
              } else {
                if (!mounted) return;
                Navigator.pop(context);
              }
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context);
            }
          },
          tooltip: l10n.location_add_dialog,
          mini: false,
          child: const Icon(Icons.add, size: 50),
        ),
        body: BackgroundWidget(
          child: Align(
              alignment: Alignment.topCenter,
              child: FutureBuilder<List<model.LocationAddress>>(
                future: db.allLocations(),
                builder: (context, snapshot) {
                  AppLocalizations l10n = AppLocalizations.of(context)!;
                  ThemeData theme = Theme.of(context);

                  if (!snapshot.hasData) {
                    return Semantics(
                      label: l10n.label_common_loading_t,
                      child: Text(l10n.label_common_loading),
                    );
                  }
                  return snapshot.data!.isEmpty
                      ? const FavoritesPlaceholder()
                      : SlidableAutoCloseBehavior(
                          closeWhenOpened: true,
                          child: ListView.separated(
                            itemCount: snapshot.data!.length,
                            separatorBuilder: (context, index) {
                              return Divider(
                                color: theme.primaryColorDark,
                              );
                            },
                            itemBuilder: (context, index) {
                              model.LocationAddress location = snapshot.data![index];
                              bool isSelected = selectedItemIndex == index;
                              return Semantics(
                                customSemanticsActions: {
                                  CustomSemanticsAction(label: l10n.button_common_edit_t): () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                          builder: (context) => FavoriteCreateUpdateScreen(
                                            initialLocation: location,
                                          ),
                                        ))
                                        .then((value) => {setState(() => {})});
                                  },
                                  CustomSemanticsAction(label: l10n.button_common_delete_t): () {
                                    setState(() {
                                      db.removeLocation(location);
                                      showSnackbar(
                                          context, l10n.location_delete_toast(location.name));
                                    });
                                  },
                                },
                                child: Slidable(
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) {
                                          setState(() {
                                            db.removeLocation(location);
                                            showSnackbar(
                                                context, l10n.location_delete_toast(location.name));
                                          });
                                        },
                                        backgroundColor: theme.colorScheme.error,
                                        foregroundColor: theme.colorScheme.primary,
                                        icon: Icons.delete,
                                        label: l10n.button_common_delete,
                                      ),
                                      SlidableAction(
                                        onPressed: (context) {
                                          Navigator.of(context)
                                              .push(MaterialPageRoute(
                                                builder: (context) => FavoriteCreateUpdateScreen(
                                                  initialLocation: location,
                                                ),
                                              ))
                                              .then((value) => {setState(() => {})});
                                        },
                                        backgroundColor: theme.colorScheme.onPrimary,
                                        foregroundColor: theme.colorScheme.primary,
                                        icon: Icons.edit,
                                        label: l10n.button_common_edit,
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                      title: Text(
                                        location.name,
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: theme.textTheme.headlineSmall?.fontSize,
                                        ),
                                      ),
                                      subtitle: Text(
                                        location.formattedAddress,
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: theme.textTheme.bodyLarge?.fontSize,
                                        ),
                                      ),
                                      tileColor:
                                          isSelected ? theme.primaryColor.withOpacity(0.1) : null,
                                      onTap: () {
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => LatLngCompassScreen(
                                            target: location.latlng(),
                                            targetName: location.name,
                                          ),
                                        ));
                                      }),
                                ),
                              );
                            },
                          ),
                        );
                },
              )),
        ));
  }
}
