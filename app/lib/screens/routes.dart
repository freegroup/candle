import 'package:candle/models/route.dart' as model;
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/route_u.dart';
import 'package:candle/screens/talkback.dart';
import 'package:candle/services/database.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class RoutesScreen extends TalkbackScreen {
  const RoutesScreen({super.key});

  @override
  String getTalkback(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return l10n.routes_mainmenu_t;
  }

  @override
  State<RoutesScreen> createState() => _ScreenState();
}

class _ScreenState extends State<RoutesScreen> {
  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService.instance;
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: CandleAppBar(
          title: Text(l10n.routes_mainmenu),
          talkback: widget.getTalkback(context),
        ),
        body: BackgroundWidget(
          child: Align(
              alignment: Alignment.topCenter,
              child: FutureBuilder<List<model.Route>>(
                future: db.allRoutes(),
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
                      ? ScrollingInfoPage(
                          header: l10n.routes_recording_placeholder_header,
                          body: l10n.routes_recording_placeholder_body,
                        )
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
                              model.Route route = snapshot.data![index];

                              return Semantics(
                                customSemanticsActions: {
                                  CustomSemanticsAction(label: l10n.button_common_edit_t): () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                          builder: (context) => RouteUpdateScreen(
                                            route: route,
                                          ),
                                        ))
                                        .then((value) => {setState(() => {})});
                                  },
                                  CustomSemanticsAction(label: l10n.button_common_delete_t): () {
                                    setState(() {
                                      db.removeRoute(route);
                                      showSnackbar(context, l10n.route_delete_toast(route.name));
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
                                            db.removeRoute(route);
                                            showSnackbar(
                                                context, l10n.route_delete_toast(route.name));
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
                                                builder: (context) => RouteUpdateScreen(
                                                  route: route,
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
                                        route.name,
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: theme.textTheme.headlineSmall?.fontSize,
                                        ),
                                      ),
                                      subtitle: Text(
                                        route.points.length.toString(),
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: theme.textTheme.bodyLarge?.fontSize,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => LatLngCompassScreen(
                                            target: route.points.last.latlng(),
                                            targetName: route.name,
                                            route: route,
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
