import 'package:candle/data/services/sharing/candle_link.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:share_plus/share_plus.dart';

/// Shares places and location notes as a message with two clickable links: a
/// Candle link that another Candle app opens and imports (a web page without the
/// app), and a Google Maps link to navigate there right away.
class ShareService {
  /// Shares [location]; [subject] defaults to its name and address.
  Future<void> shareLocation(LocationAddress location, {String? subject}) => _share(
        subject ?? '${location.name}\n${location.formattedAddress}',
        buildShareUri({'locations': [location.copyWith(id: () => null).toMap()]}),
        location.lat,
        location.lon,
      );

  Future<void> shareLocationNote(LocationNote pin) => _share(
        // "voicepins": the key of the first app versions, kept so older links still parse
        pin.memo,
        buildShareUri({'voicepins': [pin.copyWith(id: () => null).toMap()]}),
        pin.lat,
        pin.lon,
      );

  Future<void> _share(String subject, Uri candleLink, double lat, double lon) {
    final maps = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    final text = '$subject\n\nCandle: $candleLink\nGoogle Maps: $maps';
    return SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}
