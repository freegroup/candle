import 'package:candle/domain/models/location_address.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/locations/view_models/locations_viewmodel.dart';
import 'package:candle/ui/locations/widgets/location_edit_screen.dart';
import 'package:candle/ui/core/utils/dialogs.dart';
import 'package:candle/utils/result.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/info_page.dart';
import 'package:candle/ui/core/widgets/list_tile.dart';
import 'package:candle/ui/core/widgets/marker_map_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

/// Places screen with its own view model, disposed together with the screen.
Widget buildLocationsScreen() => ChangeNotifierProvider(
      create: (context) => LocationsViewModel(
        locationRepository: context.read(),
        geocodingRepository: context.read(),
        locationService: context.read(),
        shareService: context.read(),
      ),
      builder: (context, _) => LocationsScreen(viewModel: context.read()),
    );

/// The saved places, nearest first. Sighted users can switch to a map; with a
/// screen reader the list is shown alone.
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key, required this.viewModel});

  final LocationsViewModel viewModel;

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> with SemanticAnnouncer {
  LocationsViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceOnShow(AppLocalizations.of(context)!.screen_header_locations_t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenReader = MediaQuery.of(context).accessibleNavigation;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final appBar = CandleAppBar(
          title: Text(l10n.screen_header_locations),
          talkback: l10n.screen_header_locations_t,
          settingsEnabled: true,
          bottom: screenReader ? null : _tabBar(context),
        );
        if (screenReader) {
          return Scaffold(
            appBar: appBar,
            floatingActionButton: _addButton(context),
            body: BackgroundWidget(
              child: Align(alignment: Alignment.topCenter, child: _list(context)),
            ),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: appBar,
            floatingActionButton: _addButton(context),
            body: TabBarView(children: [_list(context), _map(context)]),
          ),
        );
      },
    );
  }

  TabBar _tabBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return TabBar(
      tabs: [Tab(text: l10n.label_common_list), Tab(text: l10n.label_common_map)],
      dividerColor: theme.primaryColor,
      labelColor: theme.primaryColor,
      unselectedLabelColor: theme.primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _loading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(label: l10n.label_common_loading_t, child: Text(l10n.label_common_loading));
  }

  Widget _map(BuildContext context) {
    final position = _viewModel.position;
    if (position == null) return _loading(context);
    return MarkerMapWidget(
      currentLocation: position,
      pins: _viewModel.locations,
      pinImage: 'assets/images/location_marker.png',
    );
  }

  Widget _list(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_viewModel.loaded) return _loading(context);
    if (_viewModel.locations.isEmpty) {
      return GenericInfoPage(
        header: l10n.locations_placeholder_header,
        body: l10n.locations_placeholder_body,
      );
    }
    return SlidableAutoCloseBehavior(
      closeWhenOpened: true,
      child: ListView.builder(
        itemCount: _viewModel.locations.length,
        itemBuilder: (context, index) => _tile(context, _viewModel.locations[index]),
      ),
    );
  }

  Widget _tile(BuildContext context, LocationAddress location) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final distance = _viewModel.distanceTo(location);

    return Semantics(
      // Swiping is hard with a screen reader, so the actions are offered as custom actions too.
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.button_common_edit_t): () => _edit(location),
        CustomSemanticsAction(label: l10n.button_share_location_t): () =>
            _viewModel.share.execute(location),
        CustomSemanticsAction(label: l10n.button_common_delete_t): () => _delete(location),
      },
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            CustomSlidableAction(
              onPressed: (_) => _delete(location),
              padding: EdgeInsets.zero,
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.delete, size: 35),
            ),
            CustomSlidableAction(
              onPressed: (_) => _viewModel.share.execute(location),
              padding: EdgeInsets.zero,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.share, size: 35),
            ),
            CustomSlidableAction(
              onPressed: (_) => _edit(location),
              padding: EdgeInsets.zero,
              backgroundColor: theme.positiveColor,
              foregroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.edit, size: 35),
            ),
          ],
        ),
        child: CandleListTile(
          title: location.name,
          subtitle: location.formattedAddress,
          trailing: distance == null ? null : '$distance m',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => buildTargetCompassScreen(target: location.latlng(), targetName: location.name),
          )),
        ),
      ),
    );
  }

  void _edit(LocationAddress location) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => buildLocationEditScreen(location)));

  Future<void> _delete(LocationAddress location) async {
    final message = AppLocalizations.of(context)!.location_deleted_toast(location.name);
    await _viewModel.delete.execute(location);
    if (mounted && _viewModel.delete.completed) showSnackbar(context, message);
  }

  Widget _addButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton(
      tooltip: l10n.screen_header_location_add_t,
      onPressed: () async {
        showLoadingDialog(context);
        await _viewModel.addressHere.execute();
        if (!context.mounted) return;
        Navigator.of(context).pop(); // the loading dialog
        switch (_viewModel.addressHere.result) {
          case Ok(:final value):
            _edit(value);
          case _:
            showSnackbar(context, l10n.location_position_unavailable);
        }
      },
      child: const Icon(Icons.add, size: 50),
    );
  }
}
