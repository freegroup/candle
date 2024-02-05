import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:candle/models/location_address.dart';
import 'package:candle/models/voicepin.dart';
import 'package:candle/screens/home.dart';
import 'package:candle/screens/import_location.dart';
import 'package:candle/screens/import_voicepin.dart';
import 'package:candle/screens/locations.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/screens/poi_radar.dart';
import 'package:candle/screens/recorder_controller.dart';
import 'package:candle/screens/routes.dart';
import 'package:candle/screens/voicepins.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/recorder.dart';
import 'package:candle/utils/featureflag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ButtonBarEntry {
  final Icon icon;
  final String label;
  final String talkback;
  final bool isVisible;
  ButtonBarEntry({
    required this.icon,
    required this.label,
    required this.talkback,
    this.isVisible = true,
  });
}

class NavigatorScreen extends StatefulWidget {
  const NavigatorScreen({super.key});

  @override
  State<NavigatorScreen> createState() => _ScreenState();
}

class _ScreenState extends State<NavigatorScreen> {
  int currentIndex = 0;
  String? _mapsUrlToResolve;
  late Future<LatLng?> _locationFuture;
  late StreamSubscription _intentSub;

  @override
  void initState() {
    super.initState();
    _initLocationFuture();
    _initSharingIntent();
  }

  @override
  void dispose() {
    super.dispose();
    _intentSub.cancel();
  }

  void _initSharingIntent() {
    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.getMediaStream().listen((value) {
      _handleSharedFile(value);
      setState(() {});
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.getInitialMedia().then((value) {
      setState(() {
        _handleSharedFile(value);
        // Tell the library that we are done processing the intent.
        ReceiveSharingIntent.reset();
      });
    });
  }

  void _initLocationFuture() {
    _locationFuture = LocationService.instance.location;
  }

  void _retryFetchingLocation() {
    setState(() => _initLocationFuture());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng?>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (_mapsUrlToResolve != null) {
          return _buildResolveMapsUrl(context);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(context);
        } else if (snapshot.hasData && snapshot.data != null) {
          return _buildContent(context);
        } else {
          return _buildError(context);
        }
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildResolveMapsUrl(BuildContext context) {
    // #docregion platform_features
    final PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();
    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            LocationAddress? address = LocationAddress.fromIntentUrl(url);
            if (mounted && address != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ImportLocationScreen(
                    address: address!,
                  ),
                ),
              );
              setState(() => _mapsUrlToResolve = null);
            }
          },
          onWebResourceError: (WebResourceError error) {
            print(error);
            setState(() => _mapsUrlToResolve = null);
          },
        ),
      )
      ..loadRequest(Uri.parse(_mapsUrlToResolve!));

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    return Scaffold(
      appBar: AppBar(title: Text("Resolve Maps URL")),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error obtaining GPS signal'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryFetchingLocation,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Open the Route Recording Screen again if the recording is still running. This
    // is the default if we allow "locationAllways" and terminate the app. In this
    // case the recording continues even if the app is closed.
    //
    if (RecorderService.isRecordingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const RecorderControllerScreen()));
      });
    }

    return Scaffold(
      body: _buildSingleScreen(currentIndex),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSingleScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const LocationsScreen();
      case 2:
        return const RoutesScreen();
      case 3:
        return const VoicePinsScreen();
      case 4:
        return const PoiCategoriesScreen();
      case 5:
        return PoiRadarScreen();
      default:
        return Container(); // Placeholder for undefined index
    }
  }

  Container _buildBottomNavigationBar() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 1), // Top border
        ),
      ),
      child: BottomAppBar(
        color: theme.primaryColor,
        padding: EdgeInsets.zero,
        child: ValueListenableBuilder(
          valueListenable: AppFeatures.featuresUpdateNotifier,
          builder: (context, _, __) {
            List<ButtonBarEntry> navBarItems = [
              ButtonBarEntry(
                label: l10n.buttonbar_home,
                talkback: l10n.buttonbar_home_t,
                icon: const Icon(Icons.view_module),
              ),
              ButtonBarEntry(
                label: l10n.buttonbar_locations,
                talkback: l10n.buttonbar_locations_t,
                icon: const Icon(Icons.location_on),
              ),
              ButtonBarEntry(
                label: l10n.buttonbar_routes,
                talkback: l10n.buttonbar_routes_t,
                icon: const Icon(Icons.route),
                isVisible: AppFeatures.betaRecording.isEnabled,
              ),
              ButtonBarEntry(
                label: l10n.buttonbar_voicepins,
                talkback: l10n.buttonbar_voicepins_t,
                icon: const Icon(Icons.mic),
              ),
              ButtonBarEntry(
                label: l10n.buttonbar_explore,
                talkback: l10n.buttonbar_explore_t,
                icon: const Icon(Icons.travel_explore),
              ),
              ButtonBarEntry(
                label: l10n.buttonbar_radar,
                talkback: l10n.buttonbar_radar_t,
                icon: const Icon(Icons.radar_outlined),
              ),
            ];

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navBarItems.length, (index) {
                bool isSelected = currentIndex == index;
                var item = navBarItems[index];
                return Visibility(
                  visible: item.isVisible,
                  child: Expanded(
                    child: InkWell(
                      onTap: () => setState(() => currentIndex = index),
                      child: Semantics(
                        label: item.talkback,
                        child: Container(
                          color: isSelected ? theme.cardColor : Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon.icon,
                                color: isSelected ? theme.primaryColor : theme.cardColor,
                                size: 40,
                              ),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected ? theme.primaryColor : theme.cardColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  void _handleSharedFile(List<SharedMediaFile> sharedFiles) async {
    if (sharedFiles.isNotEmpty) {
      final sharedFile = sharedFiles.first;
      if (sharedFile.type == SharedMediaType.file) {
        try {
          final file = File(sharedFile.path);
          final content = await file.readAsString();
          final jsonData = jsonDecode(content);

          if (jsonData.containsKey('locations') && jsonData['locations'] is List) {
            final locationData = jsonData['locations'] as List;
            // import a single address in an interactive way.
            if (locationData.length == 1) {
              LocationAddress address = LocationAddress.fromMap(locationData[0]);
              if (mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ImportLocationScreen(
                      address: address,
                    ),
                  ),
                );
              }
            } else {
              // import a complete list of elements.....TODO
              print("Import of a list of locations not implemented right now");
            }
          } else if (jsonData.containsKey('voicepins') && jsonData['voicepins'] is List) {
            final voicepinsData = jsonData['voicepins'] as List;
            // import a single address in an interactive way.
            if (voicepinsData.length == 1) {
              VoicePin voicepin = VoicePin.fromMap(voicepinsData[0]);
              if (mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ImportVoicepinScreen(
                      voicepin: voicepin,
                    ),
                  ),
                );
              }
            } else {
              // import a complete list of elements.....TODO
            }
          }
        } catch (e) {
          print("Error processing shared file: $e");
        }
      } else if (sharedFile.type == SharedMediaType.text) {
        String text = sharedFile.path;
        print(text);
        if (text.startsWith("https://maps.app.goo.gl/")) {
          setState(() {
            _mapsUrlToResolve = text;
          });
        }
      }
    }
  }
}
