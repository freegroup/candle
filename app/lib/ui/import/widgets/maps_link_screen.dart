import 'package:candle/domain/models/location_address.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/ui/import/widgets/import_location_screen.dart';
import 'package:candle/ui/core/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Follows a short Google Maps link in a web view until the page reveals the
/// position, then continues with the import of that place.
class MapsLinkScreen extends StatefulWidget {
  const MapsLinkScreen({super.key, required this.url});

  final Uri url;

  @override
  State<MapsLinkScreen> createState() => _MapsLinkScreenState();
}

class _MapsLinkScreenState extends State<MapsLinkScreen> {
  late final WebViewController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          final address = LocationAddress.fromIntentUrl(url);
          if (address != null) _continueWith(address);
        },
        onWebResourceError: (_) => _fail(),
      ))
      ..loadRequest(widget.url);
  }

  void _continueWith(LocationAddress address) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => buildImportLocationScreen(address)));
  }

  void _fail() {
    if (_done || !mounted) return;
    _done = true;
    showSnackbarAndNavigateBack(context, AppLocalizations.of(context)!.maps_link_failed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.label_common_loading)),
      body: Stack(
        children: [
          // The page is only needed for its address, not for reading.
          ExcludeSemantics(child: WebViewWidget(controller: _controller)),
          Semantics(
            liveRegion: true,
            label: l10n.label_common_loading_t,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
