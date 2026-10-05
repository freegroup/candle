import 'package:flutter/widgets.dart';

mixin SemanticAnnouncer<T extends StatefulWidget> on State<T> {
  /// Whether this screen is the one on top. A screen covered by another one
  /// gives no announcements or vibrations: they would talk over the screen on top.
  bool get isOnTop => ModalRoute.isCurrentOf(context) ?? true;
}
