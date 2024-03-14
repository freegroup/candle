import 'dart:async';
import 'dart:convert';

import 'package:candle/models/voicepin.dart';
import 'package:candle/screens/textoverlay.dart';
import 'package:candle/screens/voicepin_cu.dart';
import 'package:candle/services/database.dart';
import 'package:candle/services/location.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/utils/files.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/info_page.dart';
import 'package:candle/widgets/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_extend/share_extend.dart';

import '../widgets/marker_map_osm.dart';

class VoicePinsScreen extends StatefulWidget {
  const VoicePinsScreen({super.key});

  @override
  State<VoicePinsScreen> createState() => _ScreenState();
}

class _ScreenState extends State<VoicePinsScreen> with SemanticAnnouncer {
  // the current location of the user given by the GPS signal
  LatLng? _currentLocation;
  bool _isLoading = true;

  List<VoicePin> _voicepins = [];
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _listenToLocationChanges().then((value) {
      if (mounted) _load();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.screen_header_voicepins_t);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _locationSubscription?.cancel();
  }

  Future<void> _listenToLocationChanges() async {
    _currentLocation = await LocationService.instance.location;

    _locationSubscription = LocationService.instance.listen.handleError((dynamic err) {
      print(err);
    }).listen((newLocation) async {
      var latlng = LatLng(newLocation.latitude, newLocation.longitude);
      // reload the Locations and sort and update them related to the current user location
      //
      if (_currentLocation != null && calculateDistance(latlng, _currentLocation!) > 20) {
        _currentLocation = latlng;
        _load();
      }
    });
  }

  void _load() async {
    try {
      _voicepins = await DatabaseService.instance.allVoicePins();

      // Sort locations by distance to _coord
      if (_currentLocation != null) {
        _voicepins.sort((a, b) {
          var distA = calculateDistance(a.latlng(), _currentLocation!);
          var distB = calculateDistance(b.latlng(), _currentLocation!);
          return distA.compareTo(distB);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQueryData = MediaQuery.of(context);
    bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;

    return isScreenReaderEnabled ? _buildContent(context) : _buildTabbedContent(context);
  }

  Widget _buildContent(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_voicepins),
        talkback: l10n.screen_header_voicepins_t,
        settingsEnabled: true,
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      body: _isLoading
          ? _buildLoading(context)
          : _voicepins.isEmpty
              ? _buildNoContent(context)
              : _buildContentList(context),
    );
  }

  Widget _buildTabbedContent(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CandleAppBar(
          title: Text(l10n.screen_header_voicepins),
          talkback: l10n.screen_header_voicepins_t,
          settingsEnabled: true,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.label_common_list),
              Tab(text: l10n.label_common_map),
            ],
            dividerColor: theme.primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(context),
        body: TabBarView(
          children: [
            _isLoading
                ? _buildLoading(context)
                : _voicepins.isEmpty
                    ? _buildNoContent(context)
                    : _buildContentList(context),
            _isLoading
                ? _buildLoading(context)
                : MarkerMapWidget(
                    currentLocation: _currentLocation!,
                    pins: _voicepins,
                    pinImage: 'assets/images/voicepin_marker.png',
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList(BuildContext context) {
    DatabaseService db = DatabaseService.instance;
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return SlidableAutoCloseBehavior(
      closeWhenOpened: true,
      child: ListView.builder(
        itemCount: _voicepins.length,
        itemBuilder: (context, index) {
          VoicePin voicepin = _voicepins[index];

          return Semantics(
              customSemanticsActions: {
                CustomSemanticsAction(label: l10n.button_common_edit_t): () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (context) => VoicePinCreateUpdateScreen(
                          voicepin: voicepin,
                        ),
                      ))
                      .then((value) => {setState(() => {})});
                },
                CustomSemanticsAction(label: l10n.button_share_voicepin_t): () async {
                  String message = "${voicepin.memo}\n\n";
                  var dataMap = {
                    "voicepins": [voicepin.copyWith(id: () => null).toMap()]
                  };
                  String prettyJson = const JsonEncoder.withIndent('  ').convert(dataMap);
                  final file = await createCandleFileWithData("voicepin", prettyJson);
                  ShareExtend.share(file.path, "file", subject: message);
                },
                CustomSemanticsAction(label: l10n.button_common_delete_t): () async {
                  db.removeVoicePin(voicepin).then((count) => _load());
                  if (mounted) {
                    showSnackbar(context, l10n.voicepin_deleted_toast);
                  }
                },
              },
              child: Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    CustomSlidableAction(
                      onPressed: (context) async {
                        db.removeVoicePin(voicepin).then((count) => _load());
                        if (mounted) {
                          showSnackbar(context, l10n.voicepin_deleted_toast);
                        }
                      },
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.delete, size: 35),
                    ),
                    CustomSlidableAction(
                      onPressed: (context) async {
                        String message = "${voicepin.memo}\n\n";
                        var dataMap = {
                          "voicepins": [voicepin.copyWith(id: () => null).toMap()]
                        };
                        String prettyJson = const JsonEncoder.withIndent('  ').convert(dataMap);
                        final file = await createCandleFileWithData("voicepin", prettyJson);
                        ShareExtend.share(file.path, "file", subject: message);
                      },
                      backgroundColor: theme.colorScheme.onPrimary,
                      foregroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.share, size: 35),
                    ),
                    CustomSlidableAction(
                      onPressed: (context) async {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                          builder: (context) => VoicePinCreateUpdateScreen(
                            voicepin: voicepin,
                          ),
                        ))
                            .then(
                          (value) async {
                            _load();
                          },
                        );
                      },
                      backgroundColor: theme.positiveColor,
                      foregroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.edit, size: 35),
                    ),
                  ],
                ),
                child: Semantics(
                  label: l10n.voicepin_readout(voicepin.distance(_currentLocation!), voicepin.memo),
                  child: ExcludeSemantics(
                    child: CandleListTile(
                        title: voicepin.name,
                        subtitle: voicepin.memo,
                        trailing: "${voicepin.distance(_currentLocation!)} m",
                        onTap: () {
                          MediaQueryData mediaQueryData = MediaQuery.of(context);
                          bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;
                          if (isScreenReaderEnabled) {
                            //SemanticsService.announce(voicepin.memo, TextDirection.ltr);
                            showSnackbar(
                                context,
                                l10n.voicepin_readout(
                                  voicepin.distance(_currentLocation!),
                                  voicepin.memo,
                                ));
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => TextOverlayScreen(text: voicepin.memo)),
                            );
                          }
                        }),
                  ),
                ),
              ));
        },
      ),
    );
  }

  Widget _buildNoContent(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return GenericInfoPage(
      header: l10n.voicepins_placeholder_header,
      body: l10n.voicepins_placeholder_body,
      decoration: Image.asset('assets/images/voicepin.png', fit: BoxFit.cover),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.label_common_loading_t,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use min to wrap content by size
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 8), // Spacing between indicator and text
            Text(l10n.label_common_loading_t), // Loading label text
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;

    return FloatingActionButton(
      onPressed: () async {
        if (mounted == true && _currentLocation != null) {
          var voicepin = VoicePin(
            name: "",
            memo: "",
            lat: _currentLocation!.latitude,
            lon: _currentLocation!.longitude,
          );
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => VoicePinCreateUpdateScreen(voicepin: voicepin),
                ),
              )
              .then((value) => _load());
        }
      },
      tooltip: l10n.voicepin_add_speak_t,
      mini: false,
      child: const Icon(Icons.add, size: 50),
    );
  }
}
