import 'dart:async';

import 'package:candle/icons/compass.dart';
import 'package:candle/l10n/helper.dart';
import 'package:candle/screens/talkback.dart';
import 'package:candle/services/compass.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/background.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/twoliner.dart';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecorderScreen extends TalkbackScreen {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _ScreenState();

  @override
  String getTalkback(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return l10n.compass_dialog_t;
  }
}

class _ScreenState extends State<RecorderScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (7 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.compass_dialog),
        talkback: widget.getTalkback(context),
      ),
      body: BackgroundWidget(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPanel(),
          bottom: _buildBottomPane(),
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return Center(
      child: Text("Top part"),
    );
  }

  Widget _buildBottomPane() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Column(children: [
      Container(
        width: double.infinity, // Full width for TalkBack focus
        child: Semantics(
          button: true, // Explicitly mark as a button
          label: l10n.button_close_t,
          child: BoldIconButton(
            talkback: "",
            buttonWidth: MediaQuery.of(context).size.width / 5,
            icons: Icons.close_rounded,
            onTab: () {
              Navigator.pop(context);
            },
          ),
        ),
      )
    ]);
  }
}
