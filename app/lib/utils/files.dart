// This function creates a temporary file with given data and returns the File object
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> createCandleFileWithData(String basename, String data) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$basename.candle');
  await file.writeAsString(data);

  return file;
}
