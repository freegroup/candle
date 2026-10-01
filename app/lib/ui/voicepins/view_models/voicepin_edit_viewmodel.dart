import 'package:candle/data/repositories/voicepins/voicepin_repository.dart';
import 'package:candle/domain/models/voicepin.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Adds a new voice pin or edits a saved one.
class VoicePinEditViewModel extends ChangeNotifier {
  VoicePinEditViewModel({
    required VoicePinRepository voicePinRepository,
    required this._pin,
  }) : _pins = voicePinRepository {
    save = Command1(_save);
  }

  final VoicePinRepository _pins;

  /// Saves the pin with the given memo.
  late final Command1<int, String> save;

  VoicePin _pin;
  VoicePin get pin => _pin;

  bool get isUpdate => _pin.id != null;

  void movePin(LatLng position) =>
      _pin = _pin.copyWith(lat: position.latitude, lon: position.longitude);

  Future<Result<int>> _save(String memo) async {
    final result = await _pins.save(_pin.copyWith(memo: memo.trim()));
    // Saving again (e.g. after locking the position) updates instead of adding a second pin.
    if (result case Ok(:final value)) _pin = _pin.copyWith(id: () => value, memo: memo.trim());
    return result;
  }

  @override
  void dispose() {
    save.dispose();
    super.dispose();
  }
}
