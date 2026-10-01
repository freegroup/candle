import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The version of the app shown on the about screen.
class AboutViewModel extends ChangeNotifier {
  AboutViewModel({Future<PackageInfo> Function() packageInfo = PackageInfo.fromPlatform}) {
    unawaited(packageInfo().then((info) {
      _version = '${info.version}+${info.buildNumber}';
      notifyListeners();
    }));
  }

  String? _version;

  /// Version and build number, null while they are read.
  String? get version => _version;
}
