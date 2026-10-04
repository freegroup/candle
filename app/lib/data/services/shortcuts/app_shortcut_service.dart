import 'package:quick_actions/quick_actions.dart';

/// Shortcuts the user opens with a long press on the app icon.
class AppShortcutService {
  static const _newLocationNote = 'new_location_note';

  final _quickActions = const QuickActions();

  /// Offers "new location note here" on the app icon with [title];
  /// [onNewLocationNote] runs when the user picks it, also when it started the app.
  Future<void> register({required String title, required void Function() onNewLocationNote}) async {
    await _quickActions.initialize((type) {
      if (type == _newLocationNote) onNewLocationNote();
    });
    await _quickActions.setShortcutItems([
      ShortcutItem(type: _newLocationNote, localizedTitle: title),
    ]);
  }
}
