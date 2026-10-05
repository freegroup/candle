import 'package:candle/domain/models/article_ref.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/wikipedia/view_models/wikipedia_viewmodel.dart';
import 'package:candle/ui/wikipedia/widgets/article_screen.dart';
import 'package:candle/utils/result.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/info_page.dart';
import 'package:candle/ui/core/widgets/list_tile.dart';
import 'package:candle/ui/core/widgets/marker_map_osm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wikipedia screen with its own view model, disposed together with the screen.
Widget buildWikipediaScreen() => ChangeNotifierProvider(
      create: (context) => WikipediaViewModel(
        wikipediaRepository: context.read(),
        locationService: context.read(),
      ),
      builder: (context, _) => WikipediaScreen(viewModel: context.read()),
    );

/// Wikipedia articles about places around the user, nearest first.
class WikipediaScreen extends StatefulWidget {
  const WikipediaScreen({super.key, required this.viewModel});

  final WikipediaViewModel viewModel;

  @override
  State<WikipediaScreen> createState() => _WikipediaScreenState();
}

class _WikipediaScreenState extends State<WikipediaScreen> with SemanticAnnouncer {
  WikipediaViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenReader = MediaQuery.of(context).accessibleNavigation;

    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _viewModel.load]),
      builder: (context, _) {
        final appBar = CandleAppBar(
          title: Text(l10n.screen_header_wikipedia),
          talkback: l10n.screen_header_wikipedia_t,
          settingsEnabled: true,
          bottom: screenReader ? null : _tabBar(context),
        );
        if (screenReader) {
          return Scaffold(
            appBar: appBar,
            body: BackgroundWidget(
              child: Align(alignment: Alignment.topCenter, child: _content(context)),
            ),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: appBar,
            body: TabBarView(children: [_content(context), _map(context)]),
          ),
        );
      },
    );
  }

  TabBar _tabBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return TabBar(
      tabs: [Tab(text: l10n.label_common_list), Tab(text: l10n.label_common_map)],
      dividerColor: theme.primaryColor,
      labelColor: theme.primaryColor,
      unselectedLabelColor: theme.primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _loading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.label_common_loading_t,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(l10n.label_common_loading_t),
          ],
        ),
      ),
    );
  }

  Widget _map(BuildContext context) {
    final position = _viewModel.position;
    if (position == null) return _loading(context);
    return MarkerMapWidget(
      currentLocation: position,
      pins: _viewModel.articles,
      pinImage: 'assets/images/location_marker.png',
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final load = _viewModel.load;
    if (load.error) return _error(context);
    if (!load.completed && _viewModel.articles.isEmpty) return _loading(context);
    if (_viewModel.articles.isEmpty) {
      return GenericInfoPage(
        header: l10n.wikipedia_placeholder_header,
        body: l10n.wikipedia_placeholder_body,
      );
    }
    return ListView.builder(
      itemCount: _viewModel.articles.length,
      itemBuilder: (context, index) {
        final article = _viewModel.articles[index];
        return CandleListTile(
          title: article.title,
          maxLines: 2,
          trailing: '${_viewModel.distanceTo(article)} m',
          onTap: () => _open(article),
        );
      },
    );
  }

  Widget _error(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: GenericInfoPage(
            header: l10n.wikipedia_load_error,
            body: '',
            decoration: Icon(Icons.cloud_off, color: theme.primaryColor, size: 160),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Semantics(
            button: true,
            label: l10n.wikipedia_retry_t,
            excludeSemantics: true,
            onTap: _viewModel.load.execute,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              onPressed: _viewModel.load.execute,
              icon: const Icon(Icons.refresh, size: 32),
              label: Text(l10n.button_common_retry, style: theme.textTheme.headlineSmall),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(ArticleRef article) async {
    await _viewModel.summary.execute(article);
    if (!mounted) return;
    switch (_viewModel.summary.result) {
      case Ok(:final value):
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => ArticleScreen(summary: value)));
      case _:
        showSnackbar(context, AppLocalizations.of(context)!.wikipedia_load_error);
    }
  }
}
