import 'dart:async';

import 'package:candle/data/repositories/geocoding/geocoding_repository.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:flutter/foundation.dart';
import 'package:candle/utils/result.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Searches addresses while the user types; waits for a pause in typing so
/// that not every letter becomes a request.
class AddressSearchViewModel extends ChangeNotifier {
  AddressSearchViewModel({
    required GeocodingRepository geocodingRepository,
    this.debounce = const Duration(seconds: 1),
  }) : _geocoding = geocodingRepository;

  final GeocodingRepository _geocoding;
  final Duration debounce;

  Timer? _timer;
  int _generation = 0;

  List<LocationAddress> _results = [];
  List<LocationAddress> get results => _results;

  void search(String query) {
    _timer?.cancel();
    final generation = ++_generation;
    if (query.trim().length < 2) {
      _results = [];
      notifyListeners();
      return;
    }
    _timer = Timer(debounce, () async {
      final result = await _geocoding.search(query.trim());
      // A newer query may have started while this one was running.
      if (generation != _generation) return;
      switch (result) {
        case Ok(:final value):
          _results = value;
        case Error(:final error):
          _log.w('Address search failed: $error');
          _results = [];
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _generation++;
    super.dispose();
  }
}
