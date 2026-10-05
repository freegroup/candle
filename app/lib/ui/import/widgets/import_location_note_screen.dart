import 'package:candle/ui/import/view_models/distance_viewmodel.dart';
import 'package:provider/provider.dart';

import 'package:candle/domain/models/location_note.dart';
import 'package:candle/ui/compass/widgets/target_compass_screen.dart';
import 'package:candle/ui/location_notes/widgets/location_note_edit_screen.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/dialog_button.dart';
import 'package:candle/ui/core/widgets/twoliner.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final note = widget.locationNote;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_import_location_note),
        talkback: l10n.screen_header_import_location_note_t,
      ),
      body: BackgroundWidget(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.distanceViewModel,
            builder: (context, _) {
              final distance = widget.distanceViewModel.distance;
              final loading = distance == null;
              return Column(
                children: [
                  TwolinerWidget(
                    headline: note.memo,
                    headlineTalkback: note.memo,
                    subtitle: loading ? l10n.label_common_loading : '$distance Meter',
                    subtitleTalkback:
                        loading ? l10n.label_common_loading_t : l10n.location_note_distance_t(distance),
                  ),
                  DialogButton(
                    label: l10n.button_import_location_note,
                    talkback: l10n.button_import_location_note_t,
                    onTab: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(builder: (_) => buildLocationNoteEditScreen(note)),
                    ),
                  ),
                  DialogButton(
                    label: l10n.button_compass,
                    talkback: l10n.button_compass_t,
                    outlined: true,
                    onTab: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => buildTargetCompassScreen(targetName: note.name, target: note.latlng()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Import screen for a shared [locationNote] with a view model for the distance to it.
Widget buildImportLocationNoteScreen(LocationNote locationNote) => ChangeNotifierProvider(
      create: (context) => DistanceViewModel(locationService: context.read(), target: locationNote.latlng()),
      builder: (context, _) =>
          ImportLocationNoteScreen(locationNote: locationNote, distanceViewModel: context.read()),
    );
