import 'package:candle/data/repositories/tips/tips_repository.dart';
import 'package:candle/domain/models/tip.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';

/// The tips, unread ones first; opening a tip marks it as read.
class TipsViewModel extends ChangeNotifier {
  TipsViewModel({required TipsRepository tipsRepository}) : _repository = tipsRepository {
    load = Command0(_load)..execute();
    _repository.addListener(_reload);
  }

  final TipsRepository _repository;

  late final Command0<void> load;

  List<Tip> _tips = [];
  List<Tip> get tips => _tips;

  Future<Result<void>> _load() async {
    final result = await _repository.tips();
    switch (result) {
      case Ok(:final value):
        // unread first, otherwise in the order of the file
        _tips = [
          ...value.where((tip) => !tip.read),
          ...value.where((tip) => tip.read),
        ];
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  // A tip was read or the language changed.
  void _reload() => load.execute();

  /// Marks [tip] as read; the screen shows it.
  Future<void> open(Tip tip) => _repository.markRead(tip.id);

  @override
  void dispose() {
    _repository.removeListener(_reload);
    load.dispose();
    super.dispose();
  }
}
