import 'package:candle/screens/latlng_compass.dart';
import 'package:candle/screens/poi_categories.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/poi_provider.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/category_placeholder.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class PoiCategoryScreen extends StatefulWidget {
  final PoiCategory category;

  const PoiCategoryScreen({required this.category, super.key});

  @override
  State<PoiCategoryScreen> createState() => _ScreenState();
}

class _ScreenState extends State<PoiCategoryScreen> {
  List<PoiDetail>? pois;
  bool isLoading = true;
  LatLng? coord;

  @override
  void initState() {
    super.initState();
    fetchLocationAndPois();
  }

  void fetchLocationAndPois() async {
    try {
      coord = await LocationService.instance.location; // Fetch location
      var poiProvider = Provider.of<PoiProvider>(context, listen: false);
      var fetchedPois = await poiProvider.fetchPois(widget.category.categories, 2000, coord!);
      if (mounted) {
        setState(() {
          pois = fetchedPois;
          isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(widget.category.title),
        talkback: widget.category.title,
      ),
      body: BackgroundWidget(
        child: isLoading
            ? Semantics(
                label: l10n.label_common_loading_t,
                child: const Center(child: CircularProgressIndicator()),
              )
            : pois == null || pois!.isEmpty
                ? const CategoryPlaceholder()
                : Column(
                    children: [
                      SemanticHeader(
                        title: l10n.explore_poi_header,
                        talkback: l10n.explore_poi_header_t(pois!.length),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: pois!.length,
                          separatorBuilder: (context, index) => Divider(color: theme.dividerColor),
                          itemBuilder: (context, index) {
                            var location = pois![index];
                            return ListTile(
                              title: Text(
                                location.name,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: theme.textTheme.headlineSmall?.fontSize,
                                ),
                              ),
                              subtitle: Text(
                                "${calculateDistance(location.latlng, coord!).toInt()} m",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: theme.textTheme.bodyLarge?.fontSize,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => LatLngCompassScreen(
                                    target: location.latlng,
                                    targetName: location.name,
                                  ),
                                ));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
