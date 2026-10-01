import 'dart:async';

import 'package:candle/data/repositories/recording/recording_repository.dart';
import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';

/// Texts of the Android notification shown while recording.
typedef RecordingNotification = ({String title, String text});

/// Starts and ends a route recording and shows the route recorded so far.
class RecordingViewModel extends ChangeNotifier {
  RecordingViewModel({
    required RecordingRepository recordingRepository,
    required RouteRepository routeRepository,
    required CompassService compassService,
  })  : _recording = recordingRepository,
        _routes = routeRepository {
    start = Command1(_start);
    stop = Command1(_stop);
    _recording.addListener(_onRecordingChanged);
    _onRecordingChanged();
    _headings = compassService.headings().listen((heading) {
      _heading = heading;
      if (isRecording) notifyListeners();
    });
  }

  final RecordingRepository _recording;
  final RouteRepository _routes;

  late final Command1<int, (String, RecordingNotification)> start;

  /// Ends the recording; the argument says whether the route is kept.
  late final Command1<void, bool> stop;

  bool get isRecording => _recording.isRecording;

  Route? _route;

  /// The route recorded so far, null until the first update arrives.
  Route? get route => _route;

  double _heading = 0;

  /// Heading of the phone in degrees, to turn the map with the user.
  double get heading => _heading;

  StreamSubscription<double>? _headings;
  StreamSubscription<Route?>? _routeUpdates;

  Future<Result<int>> _start((String, RecordingNotification) args) {
    final (name, notification) = args;
    return _recording.start(
      name.trim(),
      notificationTitle: notification.title,
      notificationText: notification.text,
    );
  }

  Future<Result<void>> _stop(bool save) => _recording.stop(save: save);

  void _onRecordingChanged() {
    unawaited(_routeUpdates?.cancel());
    _routeUpdates = null;
    _route = null;
    final routeId = _recording.routeId;
    if (routeId != null) {
      _routeUpdates = _routes.watch(routeId).listen((route) {
        _route = route;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _recording.removeListener(_onRecordingChanged);
    unawaited(_headings?.cancel());
    unawaited(_routeUpdates?.cancel());
    start.dispose();
    stop.dispose();
    super.dispose();
  }
}
