import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:candle/domain/models/location_address.dart';
import 'package:candle/domain/models/voicepin.dart';
import 'package:logger/logger.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final _log = Logger();

/// Something another app shared with Candle.
sealed class SharedContent {}

class SharedLocation extends SharedContent {
  SharedLocation(this.location);
  final LocationAddress location;
}

class SharedVoicePin extends SharedContent {
  SharedVoicePin(this.pin);
  final VoicePin pin;
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
  if (json['voicepins'] case [final Map<String, dynamic> pin]) {
    return SharedVoicePin(VoicePin.fromMap(pin));
  }
  return null;
}

/// Shared text that Candle understands; null otherwise.
SharedContent? parseSharedText(String text) =>
    text.startsWith('https://maps.app.goo.gl/') ? SharedMapsLink(Uri.parse(text)) : null;

/// Files and links shared with Candle, both at app start and while it runs.
class SharedContentService {
  Stream<SharedContent> content() {
    final sharing = ReceiveSharingIntent.instance;
    final controller = StreamController<SharedContent>();
    StreamSubscription<List<SharedMediaFile>>? subscription;
    controller.onListen = () async {
      await _forward(await sharing.getInitialMedia(), controller);
      await sharing.reset();
      subscription = sharing.getMediaStream().listen(
            (files) => _forward(files, controller),
            onError: (Object e) => _log.w('Sharing intent error: $e'),
          );
    };
    controller.onCancel = () => subscription?.cancel();
    return controller.stream;
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
