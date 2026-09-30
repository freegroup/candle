import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/ui/explore/view_models/poi_category_viewmodel.dart';
import 'package:candle/ui/explore/widgets/poi_category_screen.dart';
import 'package:candle/ui/explore/widgets/poi_texts.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/semantic_header.dart';
import 'package:candle/widgets/tile_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Grid of POI categories ("Explore" tab).
class PoiCategoriesScreen extends StatefulWidget {
  const PoiCategoriesScreen({super.key});

  @override
  State<PoiCategoriesScreen> createState() => _PoiCategoriesScreenState();
}

class _PoiCategoriesScreenState extends State<PoiCategoriesScreen> with SemanticAnnouncer {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const categories = PoiCategory.values;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_explore),
        talkback: l10n.screen_header_explore_t,
        settingsEnabled: true,
      ),
      body: BackgroundWidget(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
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
                  children: [
                    for (final category in categories)
                      TileButton(
                        title: l10n.poiCategoryTitle(category),
                        talkback: l10n.poiCategoryTitle(category),
                        icon: Icon(poiCategoryIcon(category), size: 50),
                        onPressed: () => _open(category),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(PoiCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PoiCategoryScreen(
          viewModel: PoiCategoryViewModel(
            category: category,
            poiRepository: context.read<PoiRepository>(),
            locationService: context.read<LocationService>(),
            geocodingService: context.read<GeoServiceProvider>().service,
          ),
        ),
      ),
    );
  }
}
