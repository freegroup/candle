import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _prefs;

class FeatureFlag {
  final String userStateKey;
  final bool systemState;
  final bool initialState;
  final ValueNotifier<bool> _isEnabledNotifier;

  FeatureFlag({
    required this.userStateKey,
    this.systemState = true,
    this.initialState = true,
  }) : _isEnabledNotifier = ValueNotifier(false) {
    _updateEnabledState();
  }

  Future<void> setEnabled(bool? value) async {
    if (value == null) {
      await _prefs.remove(userStateKey);
    } else {
      await _prefs.setBool(userStateKey, value);
    }
    _updateEnabledState();
  }

  void _updateEnabledState() {
    bool newValue = _calculateIsEnabled();
    if (_isEnabledNotifier.value != newValue) {
      _isEnabledNotifier.value = newValue;
    }
  }

  bool _calculateIsEnabled() {
    if (!systemState) {
      return false;
    }
    bool? userState = _prefs.getBool(userStateKey);
    return userState ?? initialState;
  }

  ValueListenable<bool> get isEnabledListenable => _isEnabledNotifier;

  bool get isEnabled => _isEnabledNotifier.value;

  bool get isConfigurable => systemState;
}

class AppFeatures {
  static final overviewCompass = FeatureFlag(userStateKey: 'overviewCompass');
  static final overviewLocation = FeatureFlag(userStateKey: 'overviewLocation');
  static final overviewRecorder = FeatureFlag(userStateKey: 'overviewRecorder');
  static final overviewShare = FeatureFlag(userStateKey: 'overviewShare');
  static final allwaysAccessGps =
      FeatureFlag(userStateKey: 'allwaysAccessGps', initialState: false);
  // It can be annoying for a person non visually impaired person to have
  //// all the time the vibration "on". Allow the ser to witch them off.
  static final vibrateDuringNavigation = FeatureFlag(userStateKey: 'vibrateDuringNavigation');
  static final vibrateCompass = FeatureFlag(userStateKey: 'vibrateCompass');

  static ValueNotifier<bool> featuresUpdateNotifier = ValueNotifier(false);

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    overviewCompass.isEnabledListenable.addListener(() {
      featuresUpdateNotifier.value = !featuresUpdateNotifier.value;
    });
    overviewLocation.isEnabledListenable.addListener(() {
      featuresUpdateNotifier.value = !featuresUpdateNotifier.value;
    });
    overviewRecorder.isEnabledListenable.addListener(() {
      featuresUpdateNotifier.value = !featuresUpdateNotifier.value;
    });
    overviewShare.isEnabledListenable.addListener(() {
      featuresUpdateNotifier.value = !featuresUpdateNotifier.value;
    });
    allwaysAccessGps.isEnabledListenable.addListener(() {
      featuresUpdateNotifier.value = !featuresUpdateNotifier.value;
    });
  }
}
