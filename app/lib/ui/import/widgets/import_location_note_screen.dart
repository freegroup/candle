import 'package:candle/ui/import/view_models/distance_viewmodel.dart';
import 'package:provider/provider.dart';

import 'package:candle/domain/models/location_note.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/location_notes/widgets/location_note_edit_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:candle/l10n/gen/app_localizations.dart';

class ImportLocationNoteScreen extends StatefulWidget {
  final LocationNote locationNote;

  const ImportLocationNoteScreen({required this.locationNote, required this.distanceViewModel, super.key});

  final DistanceViewModel distanceViewModel;

  @override
  State<ImportLocationNoteScreen> createState() => _ScreenState();
}

class _ScreenState extends State<ImportLocationNoteScreen> with SemanticAnnouncer {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_import_location_note_t);
    });
  }



  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (6 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_import_location_note),
        talkback: l10n.screen_header_import_location_note_t,
      ),
      body: BackgroundWidget(
        child: ListenableBuilder(
          listenable: widget.distanceViewModel,
          builder: (context, _) => DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(context),
          bottom: _buildBottomPane(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPane(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.locationNote.memo,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 30),
            widget.distanceViewModel.distance != null
                ? Text(
                    l10n.location_note_distance_t(widget.distanceViewModel.distance!),
                    style: theme.textTheme.labelLarge,
                  )
                : _buildLoading(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        DialogButton(
            label: l10n.button_import_location_note,
            talkback: l10n.button_import_location_note_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => buildLocationNoteEditScreen(widget.locationNote),
                ),
              );
            }),
        DialogButton(
            label: l10n.button_compass,
            talkback: l10n.button_compass_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => buildTargetCompassScreen(
                    targetName: widget.locationNote.name,
                    target: widget.locationNote.latlng(),
                  ),
                ),
              );
            }),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: Text(l10n.label_common_loading),
    );
  }
}

/// Import screen for a shared [locationNote] with a view model for the distance to it.
Widget buildImportLocationNoteScreen(LocationNote locationNote) => ChangeNotifierProvider(
      create: (context) => DistanceViewModel(locationService: context.read(), target: locationNote.latlng()),
      builder: (context, _) => ImportLocationNoteScreen(locationNote: locationNote, distanceViewModel: context.read()),
    );
