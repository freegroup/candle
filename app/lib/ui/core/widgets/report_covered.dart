import 'package:flutter/widgets.dart';

/// Tells [ReportCovered] widgets when a screen or dialog opens above theirs;
/// registered with the app's navigator.
final candleRouteObserver = RouteObserver<ModalRoute<void>>();

/// Wants to know when its screen is covered by another one; it decides itself
/// what to do then (e.g. stop updating a list nobody sees).
abstract interface class CoveredAware {
  void onCovered();
  void onUncovered();
}

/// Tells [target] when another screen or dialog covers this one and when it is
/// on top again. It switches nothing off by itself.
class ReportCovered extends StatefulWidget {
  const ReportCovered({super.key, required this.target, required this.child});

  final CoveredAware target;
  final Widget child;

  @override
  State<ReportCovered> createState() => _ReportCoveredState();
}

class _ReportCoveredState extends State<ReportCovered> with RouteAware {
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _route) return;
    candleRouteObserver.unsubscribe(this);
    _route = route;
    if (route != null) candleRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    candleRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() => widget.target.onCovered();

  @override
  void didPopNext() => widget.target.onUncovered();

  @override
  Widget build(BuildContext context) => widget.child;
}
