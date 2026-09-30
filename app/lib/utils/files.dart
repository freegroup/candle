import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// This function creates a temporary file with given data and returns the File object
Future<File> createCandleFileWithData(String basename, String data) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$basename.candle');
  await file.writeAsString(data);

  return file;
}

// Opens the platform share sheet for the given file
Future<void> shareFile(File file, {required String subject}) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], subject: subject),
  );
}
