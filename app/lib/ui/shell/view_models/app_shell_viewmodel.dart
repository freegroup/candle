import 'package:candle/data/services/sharing/shared_content_service.dart';
import 'package:flutter/foundation.dart';

/// The selected tab, and content other apps share with Candle.
class AppShellViewModel extends ChangeNotifier {
  AppShellViewModel({required SharedContentService sharedContentService})
      : sharedContent = sharedContentService.content();

  /// Places, voice pins and map links to import, one per share.
  final Stream<SharedContent> sharedContent;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void select(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }
}
