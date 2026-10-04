import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:candle/data/services/sharing/shared_content_service.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:flutter/foundation.dart';

/// The selected tab, content other apps share with Candle, and the location
/// notes the user reaches anywhere in the app.
class AppShellViewModel extends ChangeNotifier {
  AppShellViewModel({
    required SharedContentService sharedContentService,
    required LocationNoteAnnouncer locationNoteAnnouncer,
  })  : sharedContent = sharedContentService.content(),
        reachedLocationNotes = locationNoteAnnouncer.reached;

  /// Places, voice pins and map links to import, one per share.
  final Stream<SharedContent> sharedContent;

  /// Location notes to show when the user reaches them.
  final Stream<LocationNote> reachedLocationNotes;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void select(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }
}
