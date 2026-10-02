import 'package:candle/domain/models/route.dart' as model;
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/recording/widgets/recording_screen.dart';
import 'package:candle/ui/routes/view_models/routes_viewmodel.dart';
import 'package:candle/ui/routes/widgets/route_edit_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

/// Routes screen with its own view model, disposed together with the screen.
Widget buildRoutesScreen() => ChangeNotifierProvider(
      create: (context) => RoutesViewModel(routeRepository: context.read()),
      builder: (context, _) => RoutesScreen(viewModel: context.read()),
    );

/// The recorded routes; tapping one guides the user along it.
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key, required this.viewModel});

  final RoutesViewModel viewModel;

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> with SemanticAnnouncer {
  RoutesViewModel get _viewModel => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_routes),
        talkback: l10n.screen_header_routes_t,
        settingsEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.button_recording_t,
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => buildRecordingScreen())),
        child: const Icon(Icons.add, size: 50),
      ),
      body: BackgroundWidget(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final routes = _viewModel.routes;
              if (routes == null) {
                return Semantics(
                  label: l10n.label_common_loading_t,
                  child: Text(l10n.label_common_loading),
                );
              }
              if (routes.isEmpty) {
                return GenericInfoPage(
                  header: l10n.routes_recording_placeholder_header,
                  body: l10n.routes_recording_placeholder_body,
                );
              }
              return SlidableAutoCloseBehavior(
                closeWhenOpened: true,
                child: ListView.separated(
                  itemCount: routes.length,
                  separatorBuilder: (context, _) =>
                      Divider(color: Theme.of(context).primaryColorDark),
                  itemBuilder: (context, index) => _tile(context, routes[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, model.Route route) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      // Swiping is hard with a screen reader, so the actions are offered as custom actions too.
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.button_common_edit_t): () => _edit(route),
        CustomSemanticsAction(label: l10n.button_common_delete_t): () => _delete(route),
      },
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _delete(route),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.primary,
              icon: Icons.delete,
              label: l10n.button_common_delete,
            ),
            SlidableAction(
              onPressed: (_) => _edit(route),
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
          onTap: route.points.isEmpty
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => buildTargetCompassScreen(
                      target: route.points.last.latlng(),
                      targetName: route.name,
                      route: route,
                    ),
                  )),
        ),
      ),
    );
  }

  void _edit(model.Route route) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => buildRouteEditScreen(route)));

  Future<void> _delete(model.Route route) async {
    final message = AppLocalizations.of(context)!.route_delete_toast(route.name);
    await _viewModel.delete.execute(route);
    if (mounted && _viewModel.delete.completed) showSnackbar(context, message);
  }
}
