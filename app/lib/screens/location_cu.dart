import 'dart:async';

import 'package:candle/models/location_address.dart' as model;
import 'package:candle/models/location_address.dart';
import 'package:candle/screens/address_search.dart';
import 'package:candle/services/database.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/accessible_text_input.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/dialog_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocationCreateUpdateScreen extends StatefulWidget {
  final model.LocationAddress initialLocation;

  const LocationCreateUpdateScreen({super.key, required this.initialLocation});

  @override
  State<LocationCreateUpdateScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LocationCreateUpdateScreen> with SemanticAnnouncer {
  final TextEditingController _editingController = TextEditingController();
  final StreamController<LocationAddress> _addressController = StreamController<LocationAddress>();

  bool _isUpdate = false;
  bool _canSubmit = false;
  late model.LocationAddress stateLocation;

  @override
  void initState() {
    stateLocation = widget.initialLocation;
    super.initState();

    _editingController.text = stateLocation.name;
    _canSubmit = _editingController.text.isNotEmpty;
    _isUpdate = stateLocation.id != null;

    _addressController.stream.listen((address) {
      if (mounted) {
        setState(() {
          address.id = stateLocation.id;
          stateLocation = address;
        });
      }
    });

    _editingController.addListener(() {
      if (mounted) {
        setState(() => _canSubmit = _editingController.text.isNotEmpty);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      var text =
          _isUpdate ? l10n.screen_header_location_update_t : l10n.screen_header_location_add_t;
      announceOnShow(text);
    });
  }

  @override
  void dispose() {
    _addressController.close();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    String name = _editingController.text;

    model.LocationAddress locationToSave = stateLocation.copyWith(name: name);
    if (_isUpdate) {
      DatabaseService.instance.updateLocation(locationToSave);
    } else {
      DatabaseService.instance.addLocation(locationToSave);
    }
    if (!mounted) return;
    showSnackbarAndNavigateBack(context, l10n.location_saved_snackbar);
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (7 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title:
            Text(_isUpdate ? l10n.screen_header_location_update : l10n.screen_header_location_add),
        talkback:
            _isUpdate ? l10n.screen_header_location_update_t : l10n.screen_header_location_add_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(context),
          bottom: _buildBottomPane(context),
        ),
      ),
    );
  }

  Widget _buildTopPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

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
                controller: _editingController),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddressSearchScreen(
                  sink: _addressController.sink,
                  addressFragment: stateLocation.formattedAddress,
                ),
              ));
            },
            child: AbsorbPointer(
              // Prevents the TextField from gaining focus
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        l10n.inputhint_address,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    TextField(
                      controller: TextEditingController(text: stateLocation.formattedAddress),
                      maxLines: null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // _buildBottomPane(context),
        ],
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return DialogButton(
        label: l10n.button_common_save,
        talkback: l10n.button_common_save_t,
        onTab: _canSubmit
            ? () {
                _save(context);
              }
            : () {
                showSnackbar(context, l10n.location_name_required_snackbar);
              } // Disable the button if name is empty
        );
  }
}
