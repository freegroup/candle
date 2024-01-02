// global_logger.dart
import 'package:logger/logger.dart';

var log = Logger(
  printer: PrettyPrinter(),
  level: Level.debug,
);
