import 'dart:async';
import 'dart:math';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/sharing/shared_content_service.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/explore/widgets/poi_categories_screen.dart';
import 'package:candle/ui/home/widgets/home_screen.dart';
import 'package:candle/ui/import/widgets/import_location_screen.dart';
import 'package:candle/ui/import/widgets/import_location_note_screen.dart';
import 'package:candle/ui/import/widgets/maps_link_screen.dart';
import 'package:candle/ui/locations/widgets/locations_screen.dart';
import 'package:candle/ui/radar/widgets/radar_screen.dart';
import 'package:candle/ui/routes/widgets/routes_screen.dart';
import 'package:candle/ui/shell/view_models/app_shell_viewmodel.dart';
import 'package:candle/ui/location_notes/widgets/location_notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The app with its tab bar, with its own view model.
Widget buildAppShell() => ChangeNotifierProvider(
      create: (context) => AppShellViewModel(sharedContentService: context.read()),
      builder: (context, _) => AppShell(viewModel: context.read()),
    );

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

/// The tabs of the app; content shared by other apps opens the matching import screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.viewModel});

  final AppShellViewModel viewModel;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final StreamSubscription<SharedContent> _shared;

  @override
  void initState() {
    super.initState();
    _shared = widget.viewModel.sharedContent.listen(_import);
  }

  @override
  void dispose() {
    unawaited(_shared.cancel());
    super.dispose();
  }

  void _import(SharedContent content) {
    final screen = switch (content) {
      SharedLocation(:final location) => buildImportLocationScreen(location),
      SharedLocationNote(:final pin) => buildImportLocationNoteScreen(pin),
      SharedMapsLink(:final url) => MapsLinkScreen(url: url),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.viewModel, context.read<SettingsRepository>()]),
      builder: (context, _) => Scaffold(
        body: _buildTab(widget.viewModel.currentIndex),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildTab(int index) => switch (index) {
        1 => buildLocationsScreen(),
        2 => buildRoutesScreen(),
        3 => buildLocationNotesScreen(),
        4 => const PoiCategoriesScreen(),
        5 => buildRadarScreen(),
        _ => buildHomeScreen(),
      };

  Container _buildBottomNavigationBar() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    final MaterialLocalizations m10n = MaterialLocalizations.of(context);

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
        isVisible: context.read<SettingsRepository>().isEnabled(Setting.betaRecording),
      ),
      ButtonBarEntry(
        label: l10n.buttonbar_location_notes,
        talkback: l10n.buttonbar_location_notes_t,
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
    // All labels get the same number of lines: two for every tab as soon as one label
    // (at the current system font size) does not fit on a single line.
    // Same style as the Text below gets from the Material default, so the measurement matches.
    final labelStyle = theme.textTheme.bodyMedium!.merge(const TextStyle(fontSize: 12));
    final tabWidth = MediaQuery.sizeOf(context).width /
        navBarItems.where((item) => item.isVisible).length;
    var labelLines = 1;
    var lineHeight = 0.0;
    for (final item in navBarItems.where((item) => item.isVisible)) {
      final painter = TextPainter(
        text: TextSpan(text: item.label, style: labelStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 2,
      )..layout(maxWidth: tabWidth - 2);
      labelLines = max(labelLines, painter.computeLineMetrics().length);
      lineHeight = painter.preferredLineHeight;
      painter.dispose();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.scaffoldBackgroundColor, width: 1), // Top border
        ),
      ),
      child: BottomAppBar(
        color: theme.primaryColor,
        padding: EdgeInsets.zero,
        height: 8 + 40 + labelLines * lineHeight + 8,
        child: Builder(
          builder: (context) {
            var visibleLength = navBarItems.where((item) => item.isVisible).length;
            var visibleIndex = 0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navBarItems.length, (index) {
                bool isSelected = widget.viewModel.currentIndex == index;
                var item = navBarItems[index];
                visibleIndex += item.isVisible ? 1 : 0;
                var label =
                    "${item.talkback}, ${m10n.tabLabel(tabIndex: visibleIndex, tabCount: visibleLength)}";
                label = isSelected ? "$label, ${l10n.label_common_selected} " : label;
                return Visibility(
                  visible: item.isVisible,
                  child: Expanded(
                    child: InkWell(
                      onTap: () => widget.viewModel.select(index),
                      child: Semantics(
                        label: label,
                        child: Container(
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: theme.cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(alpha: 
                                          0.5), // Adjust the color and opacity to achieve the desired glow effect
                                      spreadRadius:
                                          2, // Adjust the spread radius to control the extent of the glow
                                      blurRadius:
                                          8, // Adjust the blur radius to make the glow softer or sharper
                                      offset: const Offset(0, 0), // changes position of shadow
                                    ),
                                  ],
                                )
                              : const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                item.icon.icon,
                                color: isSelected ? theme.primaryColor : theme.cardColor,
                                size: 40,
                              ),
                              ExcludeSemantics(
                                child: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: labelStyle.copyWith(
                                    color: isSelected ? theme.primaryColor : theme.cardColor,
                                  ),
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
}
