import 'package:candle/domain/models/tip.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:candle/ui/core/widgets/info_page.dart';
import 'package:candle/ui/core/widgets/list_tile.dart';
import 'package:candle/ui/tips/view_models/tips_viewmodel.dart';
import 'package:candle/ui/tips/widgets/tip_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Tips screen with its own view model, disposed together with the screen.
Widget buildTipsScreen() => ChangeNotifierProvider(
      create: (context) => TipsViewModel(tipsRepository: context.read()),
      builder: (context, _) => TipsScreen(viewModel: context.read()),
    );

/// The tips about using Candle, unread ones first and marked as new.
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key, required this.viewModel});

  final TipsViewModel viewModel;

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with SemanticAnnouncer {
  TipsViewModel get _viewModel => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_tips),
        talkback: l10n.screen_header_tips_t,
        settingsEnabled: true,
      ),
      body: BackgroundWidget(
        child: ListenableBuilder(
          listenable: Listenable.merge([_viewModel, _viewModel.load]),
          builder: (context, _) => _content(context),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_viewModel.load.error) {
      return GenericInfoPage(header: l10n.tips_load_error, body: '');
    }
    return ListView.builder(
      itemCount: _viewModel.tips.length,
      itemBuilder: (context, index) {
        final tip = _viewModel.tips[index];
        return Semantics(
          label: tip.read ? tip.title : l10n.tips_unread_t(tip.title),
          excludeSemantics: true,
          button: true,
          child: CandleListTile(
            title: tip.title,
            maxLines: 3,
            trailing: tip.read ? null : l10n.tips_unread,
            onTap: () => _open(tip),
          ),
        );
      },
    );
  }

  void _open(Tip tip) {
    _viewModel.open(tip);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TipScreen(tip: tip)));
  }
}
