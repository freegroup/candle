import 'dart:async';

import 'package:candle/models/route.dart' as model;
import 'package:candle/services/database.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/accessible_text_input.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RouteUpdateScreen extends StatefulWidget {
  final model.Route route;

  const RouteUpdateScreen({super.key, required this.route});

  @override
  State<RouteUpdateScreen> createState() => _ScreenState();
}

class _ScreenState extends State<RouteUpdateScreen> {
  TextEditingController editingController = TextEditingController();

  bool canSubmit = true;

  @override
  void initState() {
    super.initState();

    editingController.text = widget.route.name;

    editingController.addListener(() {
      if (mounted) {
        setState(() {
          canSubmit = editingController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    String name = editingController.text;

    model.Route renamedRoute = widget.route.copyWith(name: name);
    DatabaseService.instance.updateRoute(renamedRoute);

    if (!mounted) return;
    showSnackbarAndNavigateBack(context, l10n.route_saved_toast(name));
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;
    AppLocalizations l10n = AppLocalizations.of(context)!;

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
                controller: editingController,
                autofocus: !isScreenReaderEnabled,
              ),
            ),
            const SizedBox(height: 50),
            BoldIconButton(
                talkback: l10n.button_save_t,
                buttonWidth: MediaQuery.of(context).size.width / 7,
                icons: Icons.check,
                onTab: canSubmit
                    ? () => _save(context)
                    : () => showSnackbar(context, l10n.route_name_required_snackbar)),
          ],
        ),
      ),
    );
  }
}
