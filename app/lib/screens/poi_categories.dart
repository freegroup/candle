import 'package:candle/screens/poi_category.dart';
import 'package:candle/screens/talkback.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:candle/widgets/tile_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PoiCategory {
  final IconData icon;
  final String title;
  final List<String> categories;

  PoiCategory({required this.icon, required this.title, required this.categories});
}

class PoiCategoriesScreen extends TalkbackScreen {
  const PoiCategoriesScreen({super.key});

  @override
  String getTalkback(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return l10n.explore_mainmenu_t;
  }

  @override
  State<PoiCategoriesScreen> createState() => _ScreenState();
}

class _ScreenState extends State<PoiCategoriesScreen> {
  List<PoiCategory> categories = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    // https://wiki.openstreetmap.org/wiki/DE:Key:amenity
    categories = [
      PoiCategory(
        icon: Icons.local_drink,
        title: l10n.poi_category_bars,
        categories: [
          'node["amenity"="bar"]',
          'node["amenity"="nightclub"]',
        ],
      ),
      PoiCategory(
        icon: Icons.local_atm,
        title: l10n.poi_category_atms,
        categories: [
          'node["amenity"="atm"]',
          'node["amenity"="payment"]',
          'node["amenity"="bank"]',
        ],
      ),
      PoiCategory(
        icon: Icons.restaurant,
        title: l10n.poi_category_restaurants,
        categories: ['node["amenity"="restaurant"]'],
      ),
      PoiCategory(
        icon: Icons.local_hospital,
        title: l10n.poi_category_hospitals,
        categories: ['node["amenity"="hospital"]'],
      ),
      PoiCategory(
        icon: Icons.local_cafe,
        title: l10n.poi_category_cafes,
        categories: ['node["amenity"="cafe"]'],
      ),
      PoiCategory(
        icon: Icons.directions_bus,
        title: l10n.poi_category_bus_stations,
        categories: [
          'node["amenity"="bus_station"]',
          'node["amenity"="station"]',
          'node["highway"="bus_stop"]'
        ],
      ),
      PoiCategory(
        icon: Icons.local_taxi,
        title: l10n.poi_category_taxis,
        categories: ['node["amenity"="taxi"]'],
      ),
      PoiCategory(
        icon: Icons.local_pharmacy,
        title: l10n.poi_category_pharmacies,
        categories: ['node["amenity"="pharmacy"]'],
      ),
      PoiCategory(
        icon: Icons.hearing,
        title: l10n.poi_category_audible_signals,
        categories: ['node["amenity"="traffic_sginals"]'],
      ),
      PoiCategory(
        icon: Icons.wc,
        title: l10n.poi_category_public_toilets,
        categories: ['node["amenity"="toilet"]'],
      ),
      // Add more categories if needed
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: CandleAppBar(
          title: Text(l10n.explore_mainmenu),
          talkback: widget.getTalkback(context),
        ),
        body: BackgroundWidget(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SemanticHeader(
                    title: l10n.explore_category_header,
                    talkback: l10n.explore_category_header_t(categories.length),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: categories.map((category) {
                        return TileButton(
                          title: category.title,
                          talkback: category.title,
                          icon: Icon(
                            category.icon,
                            size: 50,
                          ),
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) => PoiCategoryScreen(
                                      category: category,
                                    ),
                                  ),
                                )
                                .then((value) => setState(() {}));
                          },
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
