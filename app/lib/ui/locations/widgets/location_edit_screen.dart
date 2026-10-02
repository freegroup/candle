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

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: AccessibleTextInput(
              maxLines: 1,
              mandatory: true,
              hintText: l10n.location_name,
              talkbackInput: l10n.location_name_t,
              talkbackIcon: l10n.location_add_speak_t,
              controller: _nameController,
            ),
          ),
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => Semantics(
              button: true,
              label: '${l10n.inputhint_address}: ${_viewModel.location.formattedAddress}',
              excludeSemantics: true,
              onTap: _searchAddress,
              child: InkWell(
                onTap: _searchAddress,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.inputhint_address, style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text(_viewModel.location.formattedAddress, style: theme.textTheme.bodyLarge),
                      const Divider(),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
