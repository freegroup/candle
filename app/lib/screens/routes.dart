import 'package:candle/models/route.dart' as model;
import 'package:candle/screens/fab.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/recorder_controller.dart';
import 'package:candle/screens/route_u.dart';
import 'package:candle/services/database.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _ScreenState();
}

class _ScreenState extends State<RoutesScreen> implements FloatingActionButtonProvider {
  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService.instance;
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: CandleAppBar(
          title: Text(l10n.screen_header_routes),
          talkback: l10n.screen_header_routes_t,
        ),
        body: BackgroundWidget(
          child: Align(
              alignment: Alignment.topCenter,
              child: FutureBuilder<List<model.Route>>(
                future: db.allRoutes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildLoading();
                  }
                  return snapshot.data!.isEmpty ? _buildNoRoutes() : _buildRoutes(snapshot.data!);
                },
              )),
        ));
  }

  Widget _buildRoutes(List<model.Route> routes) {
    DatabaseService db = DatabaseService.instance;
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return SlidableAutoCloseBehavior(
      closeWhenOpened: true,
      child: ListView.separated(
        itemCount: routes.length,
        separatorBuilder: (context, index) {
          return Divider(
            color: theme.primaryColorDark,
          );
        },
        itemBuilder: (context, index) {
          model.Route route = routes[index];

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
                        showSnackbar(context, l10n.route_delete_toast(route.name));
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
  }

  Widget _buildLoading() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    return Semantics(
      label: l10n.label_common_loading_t,
      child: Text(l10n.label_common_loading),
    );
  }

  Widget _buildNoRoutes() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return GenericInfoPage(
      header: l10n.routes_recording_placeholder_header,
      body: l10n.routes_recording_placeholder_body,
    );
  }

  @override
  Widget floatingActionButton(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return FloatingActionButton(
      onPressed: () async {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const RecorderControllerScreen()));
      },
      tooltip: l10n.screen_header_voicepins,
      mini: false,
      child: const Icon(Icons.add, size: 50),
    );
  }
}
