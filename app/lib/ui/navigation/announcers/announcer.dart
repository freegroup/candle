import 'dart:async';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/domain/models/navigation_guidance.dart';
import 'package:candle/ui/navigation/announcers/abstract_style.dart';
import 'package:candle/ui/navigation/announcers/detailed_style.dart';
import 'package:candle/ui/navigation/announcers/short_style.dart';
import 'package:flutter/widgets.dart';

/// Announces a navigation in the style the user chose in the settings
/// ([SettingsRepository.navigationStyleId]). The screen only hands over the
/// guidance; which style announces it and how is decided here.
class NavigationAnnouncer {
  NavigationAnnouncer({
    required SettingsRepository settingsRepository,
  }) : _settings = settingsRepository;

  final SettingsRepository _settings;

  /// The styles the user can choose from in the settings; the first one is the default.
  static const List<NavigationStyle> styles = [DetailedStyle(), ShortStyle()];

  /// The style with [id], the default one for null or an unknown id.
  static NavigationStyle styleById(String? id) {
    for (final style in styles) {
      if (style.id == id) return style;
    }
    return styles.first;
  }

  /// Announces every guidance of [guidance] until it ends; the texts are built
  /// with [context].
  void follow(BuildContext context, Stream<NavigationGuidance> guidance) {
    guidance.listen((guidance) {
      // Once the screen is gone only the end of the navigation matters; it needs no texts.
      if (!context.mounted && guidance.event != NavigationEvent.stopped) return;
      // Read for every guidance, so a style chosen during the navigation counts at once.
      final style = styleById(_settings.navigationStyleId);
      unawaited(style.announce(guidance, context));
    });
  }
}
