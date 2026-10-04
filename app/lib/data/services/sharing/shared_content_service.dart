import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:candle/data/services/sharing/candle_link.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:logger/logger.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final _log = Logger();

/// Something another app shared with Candle.
sealed class SharedContent {}

class SharedLocation extends SharedContent {
  SharedLocation(this.location);
  final LocationAddress location;
}

class SharedLocationNote extends SharedContent {
  SharedLocationNote(this.pin);
  final LocationNote pin;
}

/// A short Google Maps link; its position is only known after following it.
class SharedMapsLink extends SharedContent {
  SharedMapsLink(this.url);
  final Uri url;
}

/// Reads a `.candle` file as written by the share function; null if it is none.
SharedContent? parseCandleFile(String content) {
  final json = jsonDecode(content);
  if (json is! Map<String, dynamic>) return null;
  // Only single items can be imported for now.
  if (json['locations'] case [final Map<String, dynamic> location]) {
    return SharedLocation(LocationAddress.fromMap(location));
  }
  // "voicepins": the key of the first app versions, kept so files can be shared between versions
  if (json['voicepins'] case [final Map<String, dynamic> pin]) {
    return SharedLocationNote(LocationNote.fromMap(pin));
  }
  return null;
}

/// Reads a Candle https share link; null if it is not one or the payload is broken.
SharedContent? parseShareUri(Uri uri) {
  final json = decodeShareLink(uri);
  return json == null ? null : parseCandleFile(json);
}

/// Shared text that Candle understands; null otherwise.
SharedContent? parseSharedText(String text) =>
    text.startsWith('https://maps.app.goo.gl/') ? SharedMapsLink(Uri.parse(text)) : null;

/// Files and links shared with Candle, both at app start and while it runs:
/// `.candle` files and shared text via the share sheet, plus Candle https links
/// opened from a chat or browser.
class SharedContentService {
  Stream<SharedContent> content() {
    final sharing = ReceiveSharingIntent.instance;
    final appLinks = AppLinks();
    final controller = StreamController<SharedContent>();
    StreamSubscription<List<SharedMediaFile>>? mediaSubscription;
    StreamSubscription<Uri>? linkSubscription;

    controller.onListen = () async {
      await _forward(await sharing.getInitialMedia(), controller);
      await sharing.reset();
      mediaSubscription = sharing.getMediaStream().listen(
            (files) => _forward(files, controller),
            onError: (Object e) => _log.w('Sharing intent error: $e'),
          );
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) _forwardUri(initialLink, controller);
      linkSubscription = appLinks.uriLinkStream.listen(
            (uri) => _forwardUri(uri, controller),
            onError: (Object e) => _log.w('App link error: $e'),
          );
    };
    controller.onCancel = () {
      mediaSubscription?.cancel();
      linkSubscription?.cancel();
    };
    return controller.stream;
  }

  void _forwardUri(Uri uri, StreamController<SharedContent> sink) {
    final content = parseShareUri(uri);
    if (content != null) sink.add(content);
  }

  Future<void> _forward(List<SharedMediaFile> files, StreamController<SharedContent> sink) async {
    if (files.isEmpty) return;
    final shared = files.first;
    try {
      final content = switch (shared.type) {
        SharedMediaType.file => parseCandleFile(await File(shared.path).readAsString()),
        SharedMediaType.text || SharedMediaType.url => parseSharedText(shared.path),
        _ => null,
      };
      if (content != null) sink.add(content);
    } catch (e) {
      // a broken or foreign file must not stop the app
      _log.w('Reading the shared content failed: $e');
    }
  }
}
