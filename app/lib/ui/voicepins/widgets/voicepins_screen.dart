import 'package:candle/domain/models/voicepin.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/voicepins/widgets/text_overlay_screen.dart';
import 'package:candle/ui/core/themes/theme_data.dart';
import 'package:candle/ui/voicepins/view_models/voicepins_viewmodel.dart';
import 'package:candle/ui/voicepins/widgets/voicepin_edit_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/info_page.dart';
import 'package:candle/ui/core/widgets/list_tile.dart';
import 'package:candle/ui/core/widgets/marker_map_osm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

/// Voice pins screen with its own view model, disposed together with the screen.
Widget buildVoicePinsScreen() => ChangeNotifierProvider(
      create: (context) => VoicePinsViewModel(
        voicePinRepository: context.read(),
        locationService: context.read(),
        shareService: context.read(),
      ),
      builder: (context, _) => VoicePinsScreen(viewModel: context.read()),
    );

/// The voice pins, nearest first. Sighted users can switch to a map; with a
/// screen reader the list is shown alone.
class VoicePinsScreen extends StatefulWidget {
  const VoicePinsScreen({super.key, required this.viewModel});

  final VoicePinsViewModel viewModel;

  @override
  State<VoicePinsScreen> createState() => _VoicePinsScreenState();
}

class _VoicePinsScreenState extends State<VoicePinsScreen> with SemanticAnnouncer {
  VoicePinsViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceOnShow(AppLocalizations.of(context)!.screen_header_voicepins_t);
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
          title: Text(l10n.screen_header_voicepins),
          talkback: l10n.screen_header_voicepins_t,
          settingsEnabled: true,
          bottom: screenReader ? null : _tabBar(context),
        );
        if (screenReader) {
          return Scaffold(
            appBar: appBar,
            floatingActionButton: _addButton(context),
            body: _list(context),
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
    return Semantics(
      label: l10n.label_common_loading_t,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(l10n.label_common_loading_t),
          ],
        ),
      ),
    );
  }

  Widget _map(BuildContext context) {
    final position = _viewModel.position;
    if (position == null) return _loading(context);
    return MarkerMapWidget(
      currentLocation: position,
      pins: _viewModel.pins,
      pinImage: 'assets/images/voicepin_marker.png',
    );
  }

  Widget _list(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_viewModel.loaded) return _loading(context);
    if (_viewModel.pins.isEmpty) {
      return GenericInfoPage(
        header: l10n.voicepins_placeholder_header,
        body: l10n.voicepins_placeholder_body,
        decoration: Image.asset('assets/images/voicepin.png', fit: BoxFit.cover),
      );
    }
    return SlidableAutoCloseBehavior(
      closeWhenOpened: true,
      child: ListView.builder(
        itemCount: _viewModel.pins.length,
        itemBuilder: (context, index) => _tile(context, _viewModel.pins[index]),
      ),
    );
  }

  Widget _tile(BuildContext context, VoicePin pin) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final distance = _viewModel.distanceTo(pin);

    return Semantics(
      // Swiping is hard with a screen reader, so the actions are offered as custom actions too.
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.button_common_edit_t): () => _edit(pin),
        CustomSemanticsAction(label: l10n.button_share_voicepin_t): () =>
            _viewModel.share.execute(pin),
        CustomSemanticsAction(label: l10n.button_common_delete_t): () => _delete(pin),
      },
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            CustomSlidableAction(
              onPressed: (_) => _delete(pin),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.delete, size: 35),
            ),
            CustomSlidableAction(
              onPressed: (_) => _viewModel.share.execute(pin),
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.share, size: 35),
            ),
            CustomSlidableAction(
              onPressed: (_) => _edit(pin),
              backgroundColor: theme.positiveColor,
              foregroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.edit, size: 35),
            ),
          ],
        ),
        child: Semantics(
          label: l10n.voicepin_readout(distance ?? 0, pin.memo),
          child: ExcludeSemantics(
            child: CandleListTile(
              title: pin.name,
              subtitle: pin.memo,
              trailing: distance == null ? null : '$distance m',
              onTap: () {
                if (MediaQuery.of(context).accessibleNavigation) {
                  showSnackbar(context, l10n.voicepin_readout(distance ?? 0, pin.memo));
                } else {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => TextOverlayScreen(text: pin.memo),
                  ));
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _edit(VoicePin pin) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => buildVoicePinEditScreen(pin)));

  Future<void> _delete(VoicePin pin) async {
    final message = AppLocalizations.of(context)!.voicepin_deleted_toast;
    await _viewModel.delete.execute(pin);
    if (mounted && _viewModel.delete.completed) showSnackbar(context, message);
  }

  Widget _addButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton(
      tooltip: l10n.voicepin_add_speak_t,
      onPressed: () {
        final pin = _viewModel.newPinHere();
        if (pin == null) {
          showSnackbar(context, l10n.location_position_unavailable);
        } else {
          _edit(pin);
        }
      },
      child: const Icon(Icons.add, size: 50),
    );
  }
}
