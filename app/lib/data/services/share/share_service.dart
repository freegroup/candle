import 'dart:convert';
import 'dart:io';

import 'package:candle/domain/models/location_address.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Shares places and voice pins as `.candle` files that another Candle app can import.
class ShareService {
  /// Shares [location]; [subject] defaults to its name and address.
  Future<void> shareLocation(LocationAddress location,
          {String? subject, String basename = 'location'}) =>
      _share(
        basename,
        {'locations': [location.copyWith(id: () => null).toMap()]},
        subject: subject ?? '${location.name}\n\n${location.formattedAddress}',
      );

  Future<void> shareLocationNote(LocationNote pin) => _share(
        'location_note',
        // "voicepins": the key of the first app versions, kept so older apps can read the file
        {'voicepins': [pin.copyWith(id: () => null).toMap()]},
        subject: '${pin.memo}\n\n',
      );

  Future<void> _share(String basename, Map<String, Object> data, {required String subject}) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$basename.candle');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: subject));
  }
}
