import 'package:flutter_screen_wake/flutter_screen_wake.dart';

/* Required because some screen calls in the dispose a "false" and the new Screen in the init
   "true". Sometimes these calls not always in the right order and then the old screen sets in the "dispose"
   the flag back. This is the reason why we need a counter.
*/
class ScreenWakeService {
  static int _wakeLockCount = 0;

  static void keepOn(bool value) {
    if (value) {
      if (_wakeLockCount == 0) {
        FlutterScreenWake.keepOn(true);
      }
      _wakeLockCount++;
    } else {
      _wakeLockCount--;
      if (_wakeLockCount <= 0) {
        FlutterScreenWake.keepOn(false);
        _wakeLockCount = 0;
      }
    }
  }
}
