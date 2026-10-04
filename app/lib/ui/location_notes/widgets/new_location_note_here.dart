import 'dart:async';

import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/location_notes/widgets/location_note_edit_screen.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Adds a location note where the user is right now: the position is taken at
/// once, then the note screen opens with the text field focused for typing or dictating.
Future<void> openNewLocationNoteHere(BuildContext context) async {
  final navigator = Navigator.of(context);
  final unavailable = AppLocalizations.of(context)!.location_position_unavailable;
  final position = await context.read<LocationService>().currentPosition();
  if (!context.mounted) return;
  switch (position) {
    case Ok(:final value):
      unawaited(navigator.push(MaterialPageRoute<void>(
        builder: (_) => buildLocationNoteEditScreen(
          LocationNote(name: '', memo: '', lat: value.latitude, lon: value.longitude),
          focusMemo: true,
        ),
      )));
    case Error():
      showSnackbar(context, unavailable);
  }
}
