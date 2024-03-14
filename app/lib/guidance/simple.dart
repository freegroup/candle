import 'package:candle/guidance/guidance.dart';
import 'package:candle/models/latlng_provider.dart';
import 'package:candle/models/navigation_point.dart';
import 'package:candle/models/voicepin.dart';
import 'package:candle/services/database.dart';
import 'package:candle/services/screen_wake.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/utils/vibrate.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:candle/models/route.dart' as model;

class SimpleGuidance extends BaseGuidance {
  VoicePin? _lastAnnouncedVoicePin;
  late Future<List<VoicePin>> _voicePins;

  bool _wasAligned = false;

  @override
  void initialize(BuildContext context) {
    super.initialize(context);
    ScreenWakeService.keepOn(true);
    _voicePins = DatabaseService.instance.allVoicePins();
  }

  @override
  void cancel() {
    super.cancel();
    ScreenWakeService.keepOn(false);
  }

  @override
  void onLocationChange(BuildContext context, LatLng location) {
    _announceVoicePin(context, location);
  }

  @override
  void onCompassChange(BuildContext context, int deviceHeading, int waypointHeading) {
    bool currentlyAligned = isAligned(deviceHeading, waypointHeading);

    if (currentlyAligned != _wasAligned) {
      if (currentlyAligned) {
        CandleVibrate.vibrateDuringNavigation(duration: 100, repeat: 2);
      } else {
        CandleVibrate.vibrateDuringNavigation(duration: 500);
      }
      _wasAligned = currentlyAligned;
    }
  }

  @override
  void onWaypointChange(BuildContext context, NavigationPoint? waypoint) {
    CandleVibrate.vibrateDuringNavigation(duration: 100);
  }

  @override
  void onRouteChange(BuildContext context, Future<model.Route?> route) {
    //
  }

  @override
  Future<List<LatLngProvider>> getMarker() {
    return _voicePins;
  }

  void _announceVoicePin(BuildContext context, LatLng location) async {
    var pins = await _voicePins;
    if (pins.isNotEmpty) {
      pins.sort((a, b) {
        var distA = calculateDistance(a.latlng(), location);
        var distB = calculateDistance(b.latlng(), location);
        return distA.compareTo(distB);
      });
      var pin = pins.first;
      if (calculateDistance(pin.latlng(), location) < kMinDistanceForVoicePinAnnouncement) {
        if (context.mounted && pin != _lastAnnouncedVoicePin) {
          showSnackbar(context, pin.memo);
          _lastAnnouncedVoicePin = pin;
        }
      }
    }
  }
}
