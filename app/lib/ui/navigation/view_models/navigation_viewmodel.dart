import 'dart:async';

import 'package:candle/data/repositories/location/indoor_repository.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/repositories/navigation/navigation_controller.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// What the navigation screen shows of a [NavigationController]: redraws on
/// every guidance; the map shows the location notes.
class NavigationViewModel extends ChangeNotifier {
  NavigationViewModel({
    required NavigationController navigationController,
    required LocationNoteRepository locationNoteRepository,
    required IndoorRepository indoorRepository,
  }) : _navigation = navigationController {
    _subscription = _navigation.guidance.listen((guidance) {
      _currentGuidance = guidance;
      notifyListeners();
    });
    checkIndoors = Command0(() async => Result.ok(await indoorRepository.isProbablyIndoors()))
      ..execute();
    unawaited(locationNoteRepository.watchAll().first.then((pins) {
      if (_disposed) return;
      _locationNotes = pins;
      notifyListeners();
    }, onError: (Object e) => _log.w('Loading the location notes failed: $e')));
  }

  final NavigationController _navigation;
  late final StreamSubscription<NavigationGuidance> _subscription;

  // The notes can arrive after the user left the navigation.
  bool _disposed = false;

  /// Runs once when the navigation starts: whether the user is probably inside a
  /// building (or has poor GPS reception), so the first directions are unreliable.
  late final Command0<bool> checkIndoors;

  /// What happens during the navigation, for the announcements.
  Stream<NavigationGuidance> get guidance => _navigation.guidance;

  /// Begins the navigation; the screen calls it once it listens to [guidance].
  void start() => _navigation.start();

  NavigationGuidance _currentGuidance = const NavigationGuidance(event: NavigationEvent.update);

  /// The latest guidance: what the screen shows of the next step, the same the
  /// announcements say.
  NavigationGuidance get currentGuidance => _currentGuidance;

  List<LocationNote> _locationNotes = [];

  /// Voice pins to show on the map.
  List<LocationNote> get locationNotes => _locationNotes;

  /// The route followed, null while it is calculated.
  Route? get route => _navigation.route;

  /// True when no route could be calculated; a new attempt follows the next position.
  bool get routeFailed => _navigation.routeFailed;

  LatLng get position => _navigation.position;

  /// Clockwise degrees from north the phone points to.
  int get deviceHeading => _navigation.deviceHeading;

  /// The waypoint the user walks to right now.
  NavigationPoint? get headingWaypoint => _navigation.headingWaypoint;

  /// The waypoint after [headingWaypoint], for the turn instruction.
  NavigationPoint? get turnWaypoint => _navigation.turnWaypoint;

  NavigationPoint? get nextTurnWaypoint => _navigation.nextTurnWaypoint;

  bool get targetReached => _navigation.targetReached;

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    checkIndoors.dispose();
    super.dispose();
  }
}
