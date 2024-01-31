import 'dart:async';

import 'package:candle/models/voicepin.dart';
import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/voicepin_cu.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/dialog_button.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ImportVoicepinScreen extends StatefulWidget {
  final VoicePin voicepin;

  const ImportVoicepinScreen({required this.voicepin, super.key});

  @override
  State<ImportVoicepinScreen> createState() => _ScreenState();
}

class _ScreenState extends State<ImportVoicepinScreen> {
  LatLng? _currentLocation;
  double? _distance;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLocationChanges();
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

  Future<void> _listenToLocationChanges() async {
    _currentLocation = await LocationService.instance.location;
    if (_currentLocation != null && mounted) {
      setState(() {
        _distance = calculateDistance(widget.voicepin.latlng(), _currentLocation!);
      });
    }
    _locationSubscription = LocationService.instance.listen.handleError((dynamic err) {
      print(err);
    }).listen((newLocation) async {
      var latlng = LatLng(newLocation.latitude, newLocation.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = latlng;
          _distance = calculateDistance(widget.voicepin.latlng(), _currentLocation!);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (6 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_import_voicepin),
        talkback: l10n.screen_header_import_voicepin_t,
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(context),
          bottom: _buildBottomPane(context),
        ),
      ),
    );
  }

  Widget _buildTopPane(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.voicepin.memo,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 30),
            _distance != null
                ? Text(
                    l10n.voicepin_distance_t(_distance!.toInt()),
                    style: theme.textTheme.labelLarge,
                  )
                : _buildLoading(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPane(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        DialogButton(
            label: l10n.button_import_voicepin,
            talkback: l10n.button_import_voicepin_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VoicePinCreateUpdateScreen(
                    voicepin: widget.voicepin,
                  ),
                ),
              );
            }),
        DialogButton(
            label: l10n.button_compass,
            talkback: l10n.button_compass_t,
            onTab: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LatLngCompassScreen(
                    targetName: widget.voicepin.name,
                    target: widget.voicepin.latlng(),
                  ),
                ),
              );
            }),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: Text(l10n.label_common_loading),
    );
  }
}
