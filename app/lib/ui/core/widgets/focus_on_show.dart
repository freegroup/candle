import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Moves the screen reader focus to [child] when it is first shown, so the
/// screen reader reads it out at once; used for the title of a screen or tab.
/// [child] needs semantics of its own (e.g. a [Semantics] with a label).
class FocusOnShow extends StatefulWidget {
  const FocusOnShow({super.key, required this.child});

  final Widget child;

  @override
  State<FocusOnShow> createState() => _FocusOnShowState();
}

class _FocusOnShowState extends State<FocusOnShow> {
  @override
  void initState() {
    super.initState();
    // the semantics of the child exist only after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.findRenderObject()?.sendSemanticsEvent(const FocusSemanticEvent());
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
