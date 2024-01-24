import 'dart:async';
import 'dart:ui';

import 'package:candle/app.dart';
import 'package:candle/auth/secrets.dart';
import 'package:candle/models/navigation_point.dart';
import 'package:candle/models/route.dart' as model;
import 'package:candle/services/database.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/poi_provider.dart';
import 'package:candle/services/recorder.dart';
import 'package:candle/services/router.dart';
import 'package:candle/utils/featureflag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppFeatures.initialize();
  await RecorderService.initialize();
  await initialService();

  getSha1Key();
  /*
  try {
    const scopes = ['email', 'openid'];
    var googleSignIn = GoogleSignIn(
      // Optional clientId
      //serverClientId: GOOGLE_CLIENT_ID_ANDROID,
      clientId: GOOGLE_CLIENT_ID_ANDROID,
      scopes: scopes,
    );
    try {
      googleSignIn.signIn().then((result) {
        result!.authentication.then((googleKey) {
          print(googleKey.accessToken);
          print(googleKey.idToken);
          print(googleSignIn.currentUser!.displayName);
        }).catchError((err) {
          print('inner error');
        });
      }).catchError((err) {
        print(err);
        print('error occured');
      });
      print('signed in .....');
    } catch (error) {
      print(error);
    }
  } catch (error) {
    print('Error: $error');
    if (error is PlatformException) {
      print('Details: ${error.details}');
      print('Stack trace: ${error.stacktrace}');
    }
  }
  */

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GeoServiceProvider()),
        ChangeNotifierProvider(create: (_) => PoiProvider()),
        ChangeNotifierProvider(create: (_) => RoutingProvider()),
      ],
      child: const CandleApp(),
    ));
  });
}

const platform = MethodChannel('de.freegroup/native');
Future<void> getSha1Key() async {
  try {
    final String sha1Key = await platform.invokeMethod('getSha1Key');
    print('SHA-1 Key: $sha1Key');
  } on PlatformException catch (e) {
    print("Failed to get SHA-1 key: '${e.message}'.");
  }
}

Future<void> initialService() async {
  final service = FlutterBackgroundService();
  bool isForeground = AppFeatures.allwaysAccessGps.isEnabled;

  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: isForeground,
      autoStart: false,
    ),
  );
}

const String kDefaultRouteToIgnore = "___ignore___";
var _currentRouteName = kDefaultRouteToIgnore;
Timer? _periodicTimer;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // because the "onStart" function can run in a differnet scope, the "_pref" in the AppFeature
  // maybe not initilized. We must do the "inititialize" again/first time if
  // the service runs in ForegroundMode.
  //
  await AppFeatures.initialize();

  service.on('startedService').listen((event) async {
    try {
      if (service is AndroidServiceInstance) {
        bool isForeground = AppFeatures.allwaysAccessGps.isEnabled;
        if (isForeground) {
          print('Setting as Foreground due to allwaysOnGps flag => continue running on app close');
          service.setAsForegroundService();
        } else {
          print('Running as Background due to allwaysOnGps flag => terminate on app close');
          service.setAsBackgroundService();
        }
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('backgroundServicePaused', false);
      Vibration.vibrate(duration: 100);

      _currentRouteName = event?['routeName'] as String;

      var route = await DatabaseService.instance.getRouteByName(_currentRouteName);
      if (route == null) {
        route = model.Route(name: _currentRouteName, points: []);
        await DatabaseService.instance.addRoute(route);
      } else {
        route.points = [];
        await DatabaseService.instance.updateRoute(route);
      }
    } catch (e) {
      print(e);
    }
  });

  service.on('pauseService').listen((event) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundServicePaused', true);
  });

  service.on('resumeService').listen((event) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundServicePaused', false);
  });

  service.on('stopService').listen((event) async {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    service.stopSelf();
    _currentRouteName = kDefaultRouteToIgnore;
  });

  // Setup notification periodically
  updateRecording(service);
  _periodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
    updateRecording(service);
  });
}

// Extracted function
Future<void> updateRecording(ServiceInstance service) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool backgroundServicePaused = prefs.getBool('backgroundServicePaused') ?? false;
  if (backgroundServicePaused || _currentRouteName == kDefaultRouteToIgnore) {
    print("paused or ignored due to missing correct routeName");
    return;
  }

  LatLng? loc = await LocationService.instance.location;
  if (loc != null) {
    var route = await DatabaseService.instance.getRouteByName(_currentRouteName);
    if (route != null) {
      route.points.add(NavigationPoint(coordinate: loc, annotation: ""));
      await DatabaseService.instance.updateRoute(route);
    }
    service.invoke('route_updated', {"routeName": _currentRouteName});
  }
  Vibration.vibrate(duration: 100);
}
