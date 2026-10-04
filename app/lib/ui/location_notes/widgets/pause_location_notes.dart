import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// No location notes are reported while [child] is shown, e.g. while the user types.
class PauseLocationNotes extends StatefulWidget {
  const PauseLocationNotes({super.key, required this.child});

  final Widget child;

  @override
  State<PauseLocationNotes> createState() => _PauseLocationNotesState();
}

class _PauseLocationNotesState extends State<PauseLocationNotes> {
  late final LocationNoteAnnouncer _announcer;

  @override
  void initState() {
    super.initState();
    _announcer = context.read<LocationNoteAnnouncer>()..pause();
  }

  @override
  void dispose() {
    _announcer.resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
