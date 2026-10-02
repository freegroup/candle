import 'package:candle/domain/models/location_address.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/locations/view_models/location_edit_viewmodel.dart';
import 'package:candle/ui/locations/widgets/address_search_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/accessible_text_input.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Edit screen for [location] with its own view model; a location without id is added.
Widget buildLocationEditScreen(LocationAddress location) => ChangeNotifierProvider(
      create: (context) =>
          LocationEditViewModel(locationRepository: context.read(), location: location),
      builder: (context, _) => LocationEditScreen(viewModel: context.read()),
    );

/// Names a place and lets the user change its address with the address search.
class LocationEditScreen extends StatefulWidget {
  const LocationEditScreen({super.key, required this.viewModel});

  final LocationEditViewModel viewModel;

  @override
  State<LocationEditScreen> createState() => _LocationEditScreenState();
}

class _LocationEditScreenState extends State<LocationEditScreen> with SemanticAnnouncer {
  final _nameController = TextEditingController();

  LocationEditViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _nameController.text = _viewModel.location.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context)!;
      announceOnShow(_viewModel.isUpdate
          ? l10n.screen_header_location_update_t
          : l10n.screen_header_location_add_t);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(_viewModel.isUpdate
            ? l10n.screen_header_location_update
            : l10n.screen_header_location_add),
        talkback: _viewModel.isUpdate
            ? l10n.screen_header_location_update_t
            : l10n.screen_header_location_add_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenHeight * (7 / 9),
          top: _buildForm(context),
          bottom: DialogButton(
            label: l10n.button_common_save,
            talkback: l10n.button_common_save_t,
            onTab: _save,
          ),
        ),
      ),
    );
  }

  // A place is a name and an address. Both sit in a rounded "blob", joined by a
  // connector line, like a start and a destination on a map. The address blob is a
  // button with a pencil, so it is visible that the address can be changed.
  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      // top aligned so the name field stays above the keyboard
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _nameBlob(context),
            _connector(context),
            _addressBlob(context),
          ],
        ),
      ),
    );
  }

  BoxDecoration _blobDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.primaryColor.withValues(alpha: 0.4), width: 1.5),
    );
  }

  Widget _nameBlob(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _blobDecoration(context),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.label_outline, color: theme.primaryColor, size: 28),
            ),
          ),
          Expanded(
            child: AccessibleTextInput(
              maxLines: 1,
              mandatory: true,
              hintText: l10n.location_name,
              talkbackInput: l10n.location_name_t,
              talkbackIcon: l10n.location_add_speak_t,
              controller: _nameController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressBlob(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Semantics(
        button: true,
        label: '${l10n.inputhint_address}: ${_viewModel.location.formattedAddress}. '
            '${l10n.location_address_change_hint_t}',
        excludeSemantics: true,
        onTap: _searchAddress,
        child: InkWell(
          onTap: _searchAddress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: _blobDecoration(context),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.place, color: theme.primaryColor, size: 28),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.inputhint_address, style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      Text(_viewModel.location.formattedAddress,
                          style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    // same size and right/middle position as the microphone in the name field
                    child: Icon(Icons.edit, color: theme.primaryColor, size: 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Decorative line that ties the name and address blobs together.
  Widget _connector(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    Widget dot() => Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot(),
          Container(width: 3, height: 56, color: color),
          dot(),
        ],
      ),
    );
  }

  Future<void> _searchAddress() async {
    final address = await Navigator.of(context).push<LocationAddress>(MaterialPageRoute(
      builder: (_) => buildAddressSearchScreen(query: _viewModel.location.formattedAddress),
    ));
    if (address != null) _viewModel.changeAddress(address);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      showSnackbar(context, l10n.location_name_required_snackbar);
      return;
    }
    await _viewModel.save.execute(_nameController.text);
    if (!mounted) return;
    if (_viewModel.save.completed) showSnackbarAndNavigateBack(context, l10n.location_saved_snackbar);
  }
}
