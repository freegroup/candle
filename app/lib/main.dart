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

  await RecorderService.initialize();
  await AppFeatures.initialize();
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
  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
    ),
  );
}

const String kDefaultRouteToIgnore = "___ignore___";
var _currentRouteName = kDefaultRouteToIgnore;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      print('setAsForeground');
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) async {
      print('setAsBackground');
      service.setAsBackgroundService();
    });
  }

  service.on('startedService').listen((event) async {
    print('startedService');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundServicePaused', false);
    Vibration.vibrate(duration: 100);

    _currentRouteName = event?['routeName'] as String;
    print(_currentRouteName);
    var route = await DatabaseService.instance.getRouteByName(_currentRouteName);
    if (route == null) {
      route = model.Route(name: _currentRouteName, points: []);
      await DatabaseService.instance.addRoute(route);
    } else {
      route.points = [];
      await DatabaseService.instance.updateRoute(route);
    }
  });

  service.on('pauseService').listen((event) async {
    print('pauseService');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundServicePaused', true);
  });

  service.on('resumeService').listen((event) async {
    print('resumeService');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backgroundServicePaused', false);
  });

  service.on('stopService').listen((event) async {
    print('stopService');
    service.stopSelf();
    _currentRouteName = kDefaultRouteToIgnore;
  });

  // Setup notification periodically
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool backgroundServicePaused = prefs.getBool('backgroundServicePaused') ?? false;
    if (backgroundServicePaused || _currentRouteName == kDefaultRouteToIgnore) {
      print("paused or ignored due to missing correct routeName");
      return;
    }

    if (service is AndroidServiceInstance && await service.isForegroundService()) {
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
  });
}
