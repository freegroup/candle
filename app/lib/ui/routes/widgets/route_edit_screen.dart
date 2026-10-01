import 'package:candle/domain/models/route.dart' as model;
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/ui/routes/view_models/routes_viewmodel.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:candle/ui/core/widgets/accessible_text_input.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:candle/ui/core/widgets/bold_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Rename screen for [route] with its own view model.
Widget buildRouteEditScreen(model.Route route) => ChangeNotifierProvider(
      create: (context) => RouteEditViewModel(routeRepository: context.read(), route: route),
      builder: (context, _) => RouteEditScreen(viewModel: context.read()),
    );

class RouteEditScreen extends StatefulWidget {
  const RouteEditScreen({super.key, required this.viewModel});

  final RouteEditViewModel viewModel;

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> with SemanticAnnouncer {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.viewModel.route.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_route_update),
        talkback: l10n.screen_header_route_update_t,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: AccessibleTextInput(
                maxLines: 1,
                mandatory: true,
                hintText: l10n.route_name,
                talkbackInput: l10n.route_name_t,
                talkbackIcon: l10n.route_add_speak_t,
                controller: _nameController,
                autofocus: !MediaQuery.of(context).accessibleNavigation,
              ),
            ),
            const SizedBox(height: 50),
            BoldIconButton(
              talkback: l10n.button_common_save_t,
              buttonWidth: MediaQuery.of(context).size.width / 7,
              icons: Icons.check,
              onTab: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnackbar(context, l10n.route_name_required_snackbar);
      return;
    }
    await widget.viewModel.rename.execute(name);
    if (!mounted) return;
    if (widget.viewModel.rename.completed) {
      showSnackbarAndNavigateBack(context, l10n.route_saved_toast(name));
    } else {
      showSnackbar(context, l10n.route_name_taken);
    }
  }
}
