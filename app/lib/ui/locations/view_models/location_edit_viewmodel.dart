import 'package:candle/data/repositories/locations/location_repository.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';

/// Adds a new place or edits a saved one.
class LocationEditViewModel extends ChangeNotifier {
  LocationEditViewModel({
    required LocationRepository locationRepository,
    required this._location,
  }) : _locations = locationRepository {
    save = Command1(_save);
  }

  final LocationRepository _locations;

  /// Saves the place under the given name.
  late final Command1<int, String> save;

  LocationAddress _location;
  LocationAddress get location => _location;

  bool get isUpdate => _location.id != null;

  /// Takes over position and address of [address], e.g. from the address search.
  void changeAddress(LocationAddress address) {
    _location = address.copyWith(id: () => _location.id, name: _location.name);
    notifyListeners();
  }

  Future<Result<int>> _save(String name) =>
      _locations.save(_location.copyWith(name: name.trim()));

  @override
  void dispose() {
    save.dispose();
    super.dispose();
  }
}
